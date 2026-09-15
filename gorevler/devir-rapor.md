# Devir raporu — ftc-main-cx → ftc-main

Tarih: 15 Eylül 2026

Durum: `robot-cx-01` uygulama aşaması tamamlandı. Sonraki aşama başlatılmadı;
ftc-main review'ı bekleniyor.

## robot-cx-01

### Git ve kapsam

- Repo/dal: `robot-code`, `dev-phase-2`.
- Yerel HEAD ve `origin/dev-phase-2`: `dd4bd3fb6071d0ad874fc01bb63c7ddab67fede4`.
- Push edilmiş commitler:
  - `85be43f` — HAL Pinpoint verisini Pedro localizer'a bağla
  - `15e5721` — Pedro drivetrain çıkışını HAL eylemine bağla
  - `8a3d030` — Pedro follower ve yol motorunu ekle
  - `6e129ea` — Sim koşucusuna Pedro engine ve yol seçimi ekle
  - `67460be` — Pedro HAL ve engine davranışlarını test et
  - `dd4bd3f` — Localizer son HAL durumunu saklasın
- Altı committe de istenen `Co-Authored-By` ve `Claude-Session` dipnotları var.
- `c9907c9..dd4bd3f` farkı yalnız `core/.../pedro/` altındaki beş ana sınıf,
  üç test sınıfı ve `sim/.../SimMain.java` değişikliğini içeriyor. `protokol.md`,
  `mechanism.yaml`, Python repo ve TeamCode değiştirilmedi.

### Pedro 3.0 keşif sonucu

- `Localizer`: `setPose`, varsayılan `setX/setY/setHeading`, varsayılan
  `pose/twist/velocity`, `state`, `update`, `reset`, varsayılan `debug`.
- `Drivetrain`: `drive(DrivePowers, boolean)`, `maxScaling`, iki `stop` biçimi,
  `debug`, varsayılan `interpolateAcceleration`, `interpolateVelocity`.
- `DrivePowers` alan sırası: `forward`, `strafe`, `turn`. Revhub Mecanum bytecode
  teker sırası FL/FR/BL/BR ve karışımı `f-s-t, f+s+t, f+s-t, f-s+t`.
- Follower: `Follower(Localizer, Drivetrain, Algorithm)`; `update()` ve
  `update(double)`; `follow(Path)`; `hold(Pose)` ve `hold(Pose, boolean)`;
  `isBusy()`; `atParametricEnd()`.
- Pedro 3.0 jarında `followPath`, `holdPoint` veya `PathConstraints` imzaları
  bulunamadı; mevcut karşılıklar `follow`, `hold` ve `ForesightConfig`.
- `Pose(double,double,double)` değişmez değer tipidir; `x()`, `y()`, `heading()`
  erişimlerini sağlar.

### Testler

Doğrudan yeniden çalıştırılan komut:

```text
JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew :core:test :sim:test :sim:installDist
```

Sonuç: `BUILD SUCCESSFUL`; toplam `47/47` test, `0` failure, `0` error. SDK
guard başarılı. Çalışma ağacı temiz ve uzak dal ile eşit.

### Entegrasyon

- Python sunucu: headless, port `5556`.
- İstemci: Pedro engine, `test-line`, başlangıç `(72,72,0)`, `dt=20 ms`,
  `1000` adım, `seed=1`.
- İlk kabul aralığına giriş: adım `68` (`1.36 s`).
- Son truth: `(120.00295950334511, 71.95624330809692,
  0.00010558009382677369)`.
- Son pinpoint: `(120.00902775124669, 71.95490866957033,
  -0.0005071966842020714)`; buradaki başlık `[-pi,pi]` aralığına sarılmış
  değerdir.
- İki ayrı `seed=1` koşusunda truth ve pinpoint `x/y/h` double bitleri birebir
  aynı çıktı.

### Açık review konuları

- Standart `SimMain` son poz çıktısında ham pinpoint başlığı
  `6.282678110495384 rad` görünüyor. Bu değer sarıldığında
  `-0.0005071966842020714 rad` ve geometrik olarak kabul aralığında; fakat
  `|h| < 0.1` koşulu ham sayıya kelimesi kelimesine uygulanırsa geçmiyor.
  Python/protokol değiştirme yasağı nedeniyle uygulama kapsamı genişletilmedi.
- Pedro core `Drivetrain` arayüzünde voltaj telafisi girdisi bulunamadı;
  `RobotState.voltage` için tahmini API eklenmedi.
- Pedro 3.0 sıfır uzunluklu `Line` kabul etmiyor ve ayrı bir dönüş-path tipi
  bulunamadı. `test-turn`, aynı konumda `hold(Pose(120,72,pi/2))` olarak kayıtlı.
- `MASS_KG=13.8` `PedroConstants` içinde tek kaynakta tutuluyor; incelenen
  `ForesightConfig` içinde mass alanı bulunamadı.

## re-cock-nize doğrulaması

- `dev`, `origin/dev`, `dev-phase-2` ve `origin/dev-phase-2` aynı committe:
  `f4bea22d031d46c15bcea407560e4b61a7a46105`.
- `./run_tests.sh`: `44` test geçti, `6` test atlandı.
- Önceden var olan izlenmeyen `.claude/` dizinine dokunulmadı.

## Koordinasyon kilidi

`robot-cx-01` sonrasında hiçbir yeni aşama veya ball görevi başlatılmadı.
Tuna'nın güncel yönlendirmesiyle aktif kapsam yalnız robot ve sim; `ftc-ball-cx`
beklemede tutuluyor ve açık yeni emir olmadan görev almayacak.

Tuna daha sonra robot kodunda şu tasarım niyetinin koda uygulanması için açık
yetki verdi:

- Çalışan ve test edilmiş her bağımsız parça ayrı commit edilecek ve bir sonraki
  parçaya geçmeden hemen push edilecek; GitHub üzerinden adım adım izlenebilirlik
  korunacak.
- TeamCode altında L1 HAL, L2 logic/engine ve L3 controller ayrımı dizin/paket
  yapısında görünür olacak.
- Görünürlük uğruna ortak mantık kopyalanmayacak veya SDK'sız `:core` koruması
  bozulmayacak; robot ve sim aynı ortak bytecode'u çalıştıracak.
- `:sim` tutulursa yalnız ince simülasyon adaptörü (`SimHal`, soket/protokol
  istemcisi, `SimMain`, sim test fixture'ları) olacak; robot davranışı ve ortak
  controller/engine/path mantığı `:sim` altında bulunmayacak.
- Uygulamadan önce mevcut/önerilen ağaç, dosya taşıma listesi, Gradle bağımlılık
  yönü ve `:sim` modülünü tutma/silme gerekçesi raporlanacak.

15 Eylül 2026'da Tuna, koordinasyon yetki ve sorumluluklarının yeniden
`ftc-main`e aktarılmasını istedi. Bu dosyanın devamındaki karar ve görev dağıtımı
`ftc-main`e aittir.
