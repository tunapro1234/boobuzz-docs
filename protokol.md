# Sim köprüsü protokolü (L1 seam) — BAĞLAYICI

`mimari.md` §3'ün somut hâli. İki ajan (ftc-robot ↔ ftc-sim) bu dosyaya karşı yazar.
Değişiklik önce burada, sonra kodda. Bu dosyayı ftc-main günceller.

## Roller
- **Python (re-cock-nize) = sunucu, fizik.** Önce açılır. `--mechanism <yol>` alır.
- **Java (`:sim` modülü) = istemci, saat sahibi.** `dt`'yi Java gönderir → headless koşu
  gerçek zamandan hızlı olabilir; pygame açıkken viewer gerçek zamana kilitler.
- **Lockstep:** her tick tam bir `step` ↔ `state` çifti. Python `step` gelmeden ilerlemez.
- Taşıma: TCP `127.0.0.1:5555`, satır sonlu JSON (bir mesaj = bir satır).

## Tek gerçek kaynak: `robot-code/TeamCode/core/src/main/java/boobuzz/core/hal/RobotConstants.java`
(16 Eyl: `mechanism.yaml` KALDIRILDI — runtime parser istenmiyor, hatalar derlemede görülsün.)
İki taraf da **aynı Java dosyasını** okur: Java derleme zamanı sabit olarak, Python
(`sim/mechanism.py`) regex ile satır satır. Makine-okunur sözleşme:
- skaler: `public static final double NAME = value;` tek satır (ROBOT_WIDTH, ROBOT_LENGTH,
  ROBOT_MASS_KG, WHEEL_DIAMETER, BATTERY_V, MOTOR_TAU_S, EFFICIENCY_FL/FR/BL/BR, STRAFE_EFF,
  ZERO_POWER_DECEL_FORWARD_IN_S2, ZERO_POWER_DECEL_LATERAL_IN_S2); string: ANGLE_UNIT="deg",
  DRIVETRAIN_TYPE="mecanum".
- **ROBOT_MASS_KG (17 Eyl, A02):** kilogram, sonlu ve pozitif. Eksik/bozuk/sonsuz/≤0 ⇒ Python
  `MechanismError` ile gövde kurulmadan durur; sessiz varsayılan (12 veya arşiv 13.8) YASAK.
  Kütle telden geçmez, kaynağı yalnız bu dosyadır. Kanıt: izole 18 kg fixture (kopya dosya,
  yalnız literal değişir) + eksik/bozuk varyant.
- motor: `public static final Motor FL = new Motor("fl", "wheel", xForward, yLeft, rollerDeg, ticksPerRev, freeRpm);`
  tek satır; `MOTORS` dizisi; `SERVOS = {}`; `PINPOINT = new Pinpoint(xOffset, yOffset, xDir, yDir, pod)`.
- Motor/servo/sensör **adları** buradan gelir; protokol şeması sabit kalır. Java başlangıçta
  `ready` içindeki ad listesini doğrular, uyuşmazlık = anında çökme (sessiz kayma yasak).
Faz 0/1'de sadece 4 tekerlek. Shooter/turret/tof **eklendiğinde** buraya girer, protokol değişmez.

## Çerçeve kuralı (Pedro/FTC ile aynı — Faz 2.5'te çevrim yok)
- **Saha:** 144×144 in, orijin köşe, `x`,`y` ∈ [0,144]. `h` = robotun ileri yönünün saha
  `+x` ekseninden **CCW** açısı, radyan. `h=0` ⇒ robot `+x`'e bakar.
- **Robot:** `+x` ileri, `+y` SOL, dönüş CCW pozitif. `Drive.Manual(vx,vy,ω)` de bu çerçevede
  (`vy>0` = sola kayma). `RobotConstants`'taki tüm `xForward/yLeft` bu çerçevede.
- `imu.yaw` ile `pinpoint.h` aynı tanım; ikisi de seed'li gürültülü (σ 0.002 rad).
  Gürültüsüz sensör `truth`'u `:core`'a sızdırır — yasak.
- `free_rpm`: `kV=0` "ideal" modunda hız = `power × free_rpm`. Zorunlu alan.
- **Pedro 3.0 doğrulaması (15 Eyl, ftc-robot bytecode+belge):** saha, robot çerçevesi ve mecanum
  karışımı (FL=f−s−t, FR=f+s+t, BL=f+s−t, BR=f−s+t) Pedro ile birebir; çevrim gerekmez.
  0..144 Pedro kütüphanesinde değil belgede; biz protokolde zorluyoruz (bizimki daha sıkı).
  Pinpoint → Pedro `Localizer` hiçbir eksen/işaret/orijin dönüşümü yapmaz; çerçeve = `setPose` çerçevesi.
- **FTC-standart (orijin merkez, +x seyirciden uzağa) ↔ bizim/Pedro:**
  `x_p = y_f + 72`, `y_p = 72 − x_f`, `h_p = h_f − π/2`; tersi `x_f = 72 − y_p`, `y_f = x_p − 72`, `h_f = h_p + π/2`.
- **MeepMeep saha görseli** (FieldUtil: 141×141 in, px=(x_f+70.5)s, py=(70.5−y_f)s): görselde Pedro
  `+x` YUKARI, `+y` SOLA. Viewer'da `+x` sağ/`+y` yukarı için görsel **90° saat yönünde** döndürülür,
  aynalama yok. Görsel 141 in'e ölçeklenir, sahada her kenarda 1.5 in boşluk kalır (144'e esnetme yasak).
  Görselden geometri okunmaz.
- **İttifak kenarları (15 Eyl, görsel 38051f4'e göre):** KIRMIZI `x=0`, MAVİ `x=144`. Kaynak yalnızca
  Team Juice görseli; BIOBUZZ kılavuzuyla henüz doğrulanmadı. Viewer ızgarası 24 in'de kalır (çerçeve
  ölçüsü); görselin 23.5 in karosuyla kenarlara doğru ≤1 in ayrışma normaldir, hata değildir.
- **Uyarı:** `PoseFactory.mirrorX(a)` x→2a−x, h→−h; `mirrorY(a)` y→2a−y, h değişmez. Katı yansıma
  değil; ittifak aynalaması için kullanmadan önce test yaz.

## Mesajlar

### Java → Python
```json
{"type":"reset","seed":0,"pose":{"x":0,"y":0,"h":0}}
{"type":"step","dt_ms":20,"motors":{"fl":0.5,"fr":-0.3,"bl":0.5,"br":-0.3},"servos":{},
 "events":[{"name":"shooter.feed.start","t_ms":1240,"data":{}}]}
{"type":"bye"}
```
`motors` değerleri −1..1 güç. Eksik anahtar = 0.
- `events` (Faz 1.1, opsiyonel, boş liste = yok): subsystem olayları (`shooter.feed.start/end`,
  `intake.on/off`, ileride controller→logic Intent olayları). Python **fiziği bundan türetmez**;
  sadece kaydeder ve viewer'da gösterir. Topun ne zaman atıldığı motor izinden çözülmez, buradan bilinir.
  `t_ms` Java'nın o tick'teki `hal.now()` değeri.

### Python → Java
```json
{"type":"ready","motors":["fl","fr","bl","br"],"servos":[],"proto":1,
 "state":{ ...aşağıdaki state ile aynı şema, t_ms=0, reset pozu... }}
{"type":"state","t_ms":1240,
 "enc":{"fl":1203,"fr":-870,"bl":1199,"br":-865},
 "vel":{"fl":2400.0,"fr":-1700.0,"bl":2400.0,"br":-1700.0},
 "imu":{"yaw":0.12},
 "pinpoint":{"x":3.1,"y":0.4,"h":0.12},
 "voltage":12.6,
 "gamepad":{"lx":0,"ly":-0.8,"rx":0,"ry":0,"a":false,"b":false,"x":false,"y":false,
            "lb":false,"rb":false,"back":false,"start":false,"lt":0,"rt":0,"dpad":"none"},
 "truth":{"x":3.0,"y":0.5,"h":0.12}}
```
- `enc` tam sayı tick, `vel` tick/s, açılar **radyan**, uzunluk **inç**.
- `ready` **başlangıç `state`'ini taşır** (t_ms=0): `RobotLoop` ilk tick'te `read()` çağırır, saat
  ilerlemeden geçerli bir durum olmalı. `dt_ms=0` geçersizdir.
- `t_ms` sim saati; Java tarafında `hal.now()` **budur** (anayasa kural 2).
- `gamepad`: pygame klavyesi/joystick'i. `SimHal` bunu `GamepadSource` olarak sunar;
  robotta aynı arayüzü `RealHal` OpMode'un `gamepad1`'inden doldurur.
- `truth`: **yalnızca viewer ve `:sim` testleri** okur. `:core` bu alanı hiç görmez —
  `RobotState`'e girmez.
- `voltage`: Faz 1'de sabit 12.6 olabilir; alan şimdiden var.

## Proto 2 — seyrek konum-servosu komutu (17 Eyl, ADR `phases/phase-1.1-a/adr-device-seam-v2.md`)
Proto 1 yukarıdaki gibi kalır; proto 2 yalnız aşağıdaki farkları getirir. B01 koduyla birlikte
devreye girer; A02 kütle kuralından bağımsızdır.
- **Sürüm pazarlığı:** Java `reset`'e `"proto":2` ekler (alan yoksa 1 sayılır). Python `ready.proto`
  ile kendi sürümünü söyler. İki taraf eşit değilse **her iki taraf da çıkış üretmeden çöker**;
  proto 2 mekanizma profili için sessiz proto 1 geri düşüşü yok. Proto 1 eşine tam map + sıfır
  doldurma davranışı aynen sürer (mevcut golden JSON satırları korunur).
- **İki map, semantiğe göre:** `motors` = güç cihazları (DC motor **ve CR servo**; −1..1, eksik = 0,
  STOP = 0). `servos` = yalnız **konum servoları** (0..1). Cihazın FTC tipi (DcMotorEx/CRServo/Servo)
  `RobotConstants` bildiriminden gelir, telde ayrı map açılmaz; `RobotAction` iki map olarak kalır.
- **Eksik konum servosu = tut:** Python her konum servosu için son *açık* komutu saklar; `step.servos`'ta
  eksik ad ⇒ o servo son açık konumunda kalır. Daha hiç komut almamışsa mekanizma profilindeki başlangıç
  konumunda durur, tahmini bir konuma GİTMEZ. Stow/nötr açık komuttur, STOP değildir. `reset` saklanan
  konumları siler. Java tarafı (`SimHal.fill`) proto 2'de konum servolarını sıfırla DOLDURMAZ; yalnız
  aksiyonda olanı gönderir. `RealHal` aynı kuralı uygular: bu tick'te komut yoksa `setPosition` çağırmaz.
- **Ad listeleri:** `ready.motors` güç cihazlarının (DC+CR), `ready.servos` konum servolarının adlarını
  taşır; Java iki listeyi de `RobotConstants` bildirimleriyle karşılaştırır, uyuşmazlık = çıkış öncesi çökme.
- **Çift cihaz sahipliği (kablo dışı ama bağlayıcı):** bir çiftin iki üyesi tek aksiyonda birlikte
  gelir (shooterRight/shooterLeft, hood_left/hood_right, turret_servo/turret_servo2); yarım çift komutu
  HAL `write` içinde `ActionValidator` tarafından yazımdan önce reddedilir. `shooterLeft` motor çıkışı
  shooter'ın, enkoder girişi turret'indir; enkoder sıfırlama merkezî init'te bir kez yapılır (arşivdeki
  ikinci reset bilerek düzeltilir). `ready`/`state` şeması bundan etkilenmez.
- **B01 bildirim biçimleri:** cihaz bildirimleri `RobotConstants`'ta satır başına bir tane, ad+tip+yön.
  Tam record imzaları B01 koddan önce ADR'ye eklenir ve ftc-main bu bölüme sabitler; bu kural
  eklenmeden B01 kodu başlamaz. A02 bu kuralı beklemez.
- **Eşli fixture'lar:** ADR §"Paired seam fixtures" 1–6 bağlayıcıdır; bölüm kanıtı (evidence-A/B)
  R ve S hash'leriyle sonuçlarını kaydeder.

## Java tarafı tipler (`:core`, SDK'sız)
```java
record RobotAction(Map<String,Double> motors, Map<String,Double> servos, List<Event> events) {}
record Event(String name, long tMs, Map<String,Double> data) {}
record RobotState (long t, Map<String,Integer> enc, Map<String,Double> vel,
                   double yaw, Pose pinpoint, double voltage) {}
interface Hal           { long now(); RobotState read(); void write(RobotAction a); }
interface GamepadSource { GamepadState get(); }
```
Ad-anahtarlı map = `RobotConstants`'a motor eklemek protokolü değiştirmez. `RealHal` `events`'i yok sayar.
(Kayıt/sealed Android'de derlenmezse düz final sınıf; buna zaman gömme.)

## Determinizm
Aynı `seed` + aynı `step` dizisi ⇒ bit-bit aynı `state` dizisi. Python tarafında
gürültü yalnızca `seed`'li RNG'den. Test: 500 adım iki kez koş, `truth` eşit olmalı.

## Faz 1.1 fizik (Python) — rijit cisim
- `sim.server --physics pymunk|pybullet` (varsayılan pymunk). Tek `PhysicsBackend` arayüzü:
  `reset(seed, pose)`, `step(dt_ms, powers, events)`, `state(dt)`. Motor modeli (τ, batarya,
  verim, roller açısı) backend'den bağımsız ortak Python kodu; backend yalnızca rijit cisim,
  duvar, sürtünme ve temas. Açılı duvar teması robotu döndürür ve duvar boyunca kaydırır.
- Determinizm ve mesaj şeması backend'den bağımsız; iki backend aynı e2e'yi toleransla geçer.

## Faz 1 fizik (Python) — asgari (tarihsel, 1.1'de yerini yukarıdaki alır)
- Motor: `power → hedef hız = (power·V − kS)/kV`, birinci derece gecikme (τ ≈ 0.1 s).
  Faz 1'de kV/kS 0 ise "ideal": hız = power × serbest hız.
- Mecanum ters/düz kinematik → şasi twist → pozu Euler'le ilerlet. Sürtünme yok, çarpışma
  yok, duvar = kırpma. **PyBullet kapalı.**
- Enkoder: `carryover/encoder.py` (tick kuantizasyonu). Pinpoint = truth + seed'li gürültü
  (σ 0.05 in / 0.002 rad). Duvar kırpma çevrel yarıçapla (heading'den bağımsız).

## Karar günlüğü
- 15 Eyl: çerçeve kuralı, `robot` bloğu, `free_rpm`, imu gürültüsü eklendi (ftc-sim'in 4 sorusu).
  Robot çerçevesi ilk taslakta x-sağ/y-ileri idi; Pedro ile çakışmasın diye x-ileri/y-sol yapıldı.
- 15 Eyl: `ready` başlangıç state'i taşır (ftc-robot'un boşluğu; alternatif dt_ms=0 reddedildi — sıfır adım fizik için anlamsız).
- 15 Eyl: Pedro çerçeve araştırması → protokolde değişiklik YOK; FTC-standart çevrim, MeepMeep yönelimi (90° CW, 141 in) ve mirror uyarısı eklendi.
- 15 Eyl: ittifak kenarı görsele göre kırmızı x=0 / mavi x=144 (viewer yer tutucusu tersti, takas edildi); ızgara 24 in kaldı.
- 16 Eyl: `mechanism.yaml` → `RobotConstants.java` (tek kaynak, derleme zamanı). Faz 1.1: `step.events` alanı, `--physics` backend seçimi.
- 16 Eyl (R3.6): `gamepad` şemasına `back`, `start` alanları eklendi (teleop reset-pose ve engine switch). Eksik anahtar = false.
- 17 Eyl (ADR device-seam-v2, docs 3201d65): `ROBOT_MASS_KG` skaler sözleşmeye girdi (kg, sessiz varsayılan yasak).
  Proto 2 tanımlandı: `reset.proto`/`ready.proto` pazarlığı, CR servo `motors` map'inde, eksik konum servosu = tut.
  A02 seam kodu bu hash ile serbest; B01 record imzaları sabitlenince serbest.
