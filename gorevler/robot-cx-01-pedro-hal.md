# Görev robot-cx-01 — Pedro 3.0 Localizer + Drivetrain HAL üstüne (Faz 2.5 adım 1)

Repo: /home/shared/projects/boobuzz/robot-code. Bağlayıcı belge: /home/shared/projects/boobuzz/docs/protokol.md
(özellikle "Çerçeve kuralı"). Mimari: docs/mimari.md. Plan: docs/plan.md §"Faz 2.5".
Ortam: `export JAVA_HOME=/usr/lib/jvm/java-21-openjdk` HER gradle çağrısından önce (sistem java 11).
Build: `./gradlew :core:test :sim:test :sim:installDist`. Guard: gradle/sdk-guard.gradle (FTC SDK importu = build hatası).

## 0. Git (önce bu)
1. `git checkout dev && git merge --ff-only dev-phase-1 && git push origin dev`
2. `git checkout -b dev-phase-2 && git push -u origin dev-phase-2`
Tüm iş dev-phase-2'de. Her tamamlanmış parça = ayrı commit + anında push. Commit mesajı Türkçe, ilk satır ≤72 karakter.
Commit mesajı sonuna şu iki satırı ekle:
Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01SdkrbNwP3QT1rYDjT5r478

## 1. Keşif (kod yazmadan, raporda ilk bölüm)
Pedro core jar zaten :core bağımlılığı (`com.pedropathing:core:3.0.0`, saf Java). Jar ~/.gradle/caches altında.
`javap -cp <jar>` ile şunları çıkar ve rapora AYNEN yaz (imza düzeyinde):
- Localizer arayüzü (paket adı + tüm metodlar: setPose, pose, twist, velocity, state, update, reset …)
- Drivetrain arayüzü/soyut sınıfı (Follower'ın motor gücü verdiği yer; paket + metodlar; güç sırası FL/FR/BL/BR mi?)
- Follower'ın kurulumu: constructor / builder, hangi Constants/PathConstraints tipleri zorunlu, update() metodu, followPath/holdPoint imzaları, isBusy/atParametricEnd.
- Pose: com.pedropathing.math.Pose (x() y() heading(), immutable).
Bilinmeyen bir şey varsa TAHMİN ETME, "bulamadım" yaz.

## 2. Kod — core/src/main/java/boobuzz/core/pedro/
Hepsi :core içinde, SDK yok (guard kırılırsa iş reddedilir).

### 2a. `HalLocalizer implements <Pedro Localizer>`
- Alan: son `RobotState` (protokoldeki record: t ms, enc, vel, yaw, pinpoint(x,y,h), voltage). `void feed(RobotState s)` ile RobotLoop her tick besler.
- `pose()` = pinpoint pozu, çerçeve dönüşümü YOK (protokol: bizim çerçeve = Pedro çerçevesi).
- Hız: ardışık iki pinpoint farkı / (Δt s). Saha çerçevesinde vx,vy; heading farkı [-π,π]'ye sarılır. İlk örnekte hız 0.
- `twist()` (robot çerçevesi) = saha hızını −heading ile döndür.
- `setPose(p)`: sonraki pose() p döner ve bir "offset" tutulur (pinpoint'i yazamıyoruz; offset = p − pinpoint, uygulanan: pose = pinpoint + offset; heading offset da ayrı). Basit tut.
- `update()`/`reset()`: no-op ya da offset sıfırlama; ne yaptığını Javadoc'a yaz.

### 2b. `HalDrivetrain` (Pedro Drivetrain uygulaması)
- Pedro'nun verdiği gücü YAZMAZ; son gücü `double[] fl,fr,bl,br` alanında tutar, `RobotAction lastAction()` üretir (motor isimleri mechanism.yaml'daki: fl, fr, bl, br — Mechanism sınıfından oku, sabitleme).
- Güçler [-1,1]'e kırpılır; Pedro zaten normalize ediyorsa ek normalize YOK (keşifte doğrula).
- Pedro voltage compensation istiyorsa RobotState.voltage'ı ver.
- Pedro'nun kendi Mecanum sınıfı KULLANILMAZ (hardwareMap ister).

### 2c. `PedroDriveEngine implements RobotEngine`
- Mevcut C1DriveEngine'e bak; aynı sözleşme. `Drive.Manual` → C1DriveEngine'e delege (mevcut davranış aynen korunur, testler kırılmaz).
- `Drive.GoTo(target, constraints)` → Follower.holdPoint / kısa path (keşifte hangisi uygunsa) ; `Drive.FollowPath(pathId)` → `PathRegistry`'den (aşağıda) path al, followPath. `Drive.Hold` → holdPoint(mevcut poz).
- Her tick sırası: localizer.feed(state) → follower.update() → drivetrain.lastAction() → RobotAction döndür.
- Follower `Constants`: plan.md'deki geçen sezon değerleri (mass 13.8, forwardZeroPowerAccel −36.17, lateralZeroPowerAccel −85.98, xVel 73.63, yVel 54.09) + makul PID varsayılanları; hepsi `PedroConstants` sınıfında tek yerde, üstüne "yeni robotta yeniden ölçülecek" yorumu.
- `PathRegistry`: `Map<String, Path/PathChain>`; tek kayıtlı yol: `"test-line"` = (72,72,h=0) → (120,72,h=0) düz çizgi, ardından `"test-turn"` = aynı noktada h=0→π/2 (Pedro'da nasıl ifade ediliyorsa).

### 2d. :sim — SimMain'e mod
- Yeni bayrak `--engine pedro|c1` (varsayılan c1, mevcut davranış değişmez) ve `--path <id>` (pedro modunda RobotLoop'a başlangıç Intent'i olarak `Drive.FollowPath(id)` verir).
- Mevcut bayraklar/çıktılar aynen kalır.

## 3. Testler (JUnit 4, :core)
- HalLocalizerTest: pose passthrough; iki örnekle hız hesabı (dt 20 ms, 1 in fark → 50 in/s); heading sarma (3.1 → −3.1 küçük fark); setPose offset'i.
- HalDrivetrainTest: verilen güç → lastAction motor isimleri ve değerleri; kırpma.
- PedroDriveEngineTest: Manual → C1 ile bit-bit aynı RobotAction; FollowPath("yok") → açık hata (IllegalArgumentException), sessiz no-op DEĞİL.
- Entegrasyon (gradle testi değil, elle): Python sunucu headless: `cd /home/shared/projects/boobuzz/re-cock-nize && .venv/bin/python -m sim.server --help` ile headless/port bayrağını bul, 5556'da aç; sonra
  `sim/build/install/sim/bin/sim --mechanism mechanism.yaml --port 5556 --engine pedro --path test-line --x 72 --y 72 --h 0 --dt 20 --steps 1000 --seed 1`.
  Kabul: 1000 adımda (20 s) truth/pinpoint x ∈ [118,122], |y−72| < 2, |h| < 0.1 rad. Aynı seed iki koşuda bit-bit aynı son poz.
  Sonucu (son poz, ilk kaç adımda yaklaştı) rapora yaz. Sapma büyükse PID'yi kabaca ayarla ama Constants dışına çıkma; tutmuyorsa nedenini yaz, "tutturdum" deme.

## 4. Yapılmayacaklar
- protokol.md, mechanism.yaml, Python repo'ya dokunma. C1DriveEngine'in mecanum karışımını değiştirme.
- TeamCode'a dokunma (Pedro revhub tarafı sonraki görev). :core'a yeni bağımlılık ekleme.
- Yardımcı sınıf/abstraction şişirme: 2a–2d + PathRegistry + PedroConstants dışında yeni public sınıf açma.
- Tahminle "çalışıyor" deme; her iddia bir komut çıktısına dayansın.

## 5. Rapor (kısa, ftc-main'e; dosya dökümü yok)
1) Keşif imzaları 2) commit hash'leri (push'lu) 3) test sayısı ve sonucu 4) entegrasyon koşusu son poz + determinizm 5) bulamadığın / tutmayan şeyler.
