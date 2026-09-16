# Faz 1 — katman yerleşimi + Gradle çözümü (tasarım notu)

Takım liderinin bağlayıcı kararı uygulanıyor. `robot-cx-02-rapor.md`'nin **§2 öneri kısmı
geçersizdir** (L2/L3'ü `:core`'da, TeamCode dışında tutuyordu); §1 envanteri ve §6 riskleri
geçerlidir ve burada kullanıldı.

Repo: `robot-code`, dal `dev-phase-2`. Gradle 9.1.0, AGP 8.13.2, `:core`/`:sim` Java 17.

---

## A. Gradle çözümü

### Problem

Bağlayıcı karar: **L1 HAL sözleşmesi, L2 logic, L3 controller kaynakları `TeamCode/`
klasörünün içinde, ayrı dizinler olarak görünür olacak.** Korunacak kısıt: bu kaynaklar
`:core` tarafından (FTC SDK'sız saf Java olarak) derlenmeli, `:sim` ile robot **aynı
bytecode'u** koşmalı, ve TeamCode aynı sınıfları **ikinci kez derlememeli**.

Bu iki şey normalde çelişir: AGP `TeamCode/src/main/java`'nın tamamını derler.

### Seçenek 1 — `:core` srcDir'i `TeamCode/src/main/java`'yı gösterir, TeamCode exclude eder

```groovy
// core/build.gradle
sourceSets.main.java { srcDirs = ['../TeamCode/src/main/java']; include 'boobuzz/**' }

// TeamCode/build.gradle
android.sourceSets.main.java.exclude 'boobuzz/**'
```

Katmanlar `TeamCode/src/main/java/boobuzz/{hal,logic,controller}/` altında, OpMode'larla
yan yana durur — karar metnine en birebir uyan yerleşim.

**Doğrulandı (bu makinede koşturularak):**
- `:core`'un `srcDirs`'ü proje dizininin dışını gösterebiliyor ve `include` filtresi
  çalışıyor; `org/firstinspires/**` altındaki `com.qualcomm` referanslı dosya derlemeye
  hiç girmedi. (Gradle 9.1.0 ile scratch projede koşturuldu.)
- AGP 8.13.2'de `android.sourceSets.main.java` çalışma zamanında
  `com.android.build.gradle.api.AndroidSourceDirectorySet`'e çözülüyor; bu arayüz
  `PatternFilterable` genişletiyor ve `exclude(String...)` **var** (jar'dan `javap` ile
  doğrulandı).

**Riskler:**
1. **`exclude` artık eski (deprecated) yüzeyde.** Yeni public DSL
   `com.android.build.api.dsl.AndroidSourceDirectorySet` yalnızca `srcDir/srcDirs/
   setSrcDirs/getDirectories` sunuyor — `filter`/`exclude` **yok** (doğrulandı). Groovy
   DSL bugün eski arayüze düştüğü için çalışıyor; AGP 9'da kaldırılırsa build kırılır.
2. **Sessiz çift derleme riski.** İki filtre (core'un `include`'u, TeamCode'un
   `exclude`'u) elle senkron tutuluyor. Biri şaşarsa aynı sınıflar hem `:core` jar'ında
   hem TeamCode'un `classes`'ında olur → en iyi ihtimalle dex "duplicate class", en
   kötüsünde iki farklı derleme ayarıyla (Java 17 vs desugaring) ayrışmış bytecode. Tam
   olarak kaçınmak istediğimiz şey.
3. **`sdk-guard.gradle` sessizce ölür.** Guard `fileTree(dir: projectDir, includes:
   ['src/**/*.java'])` kullanıyor; bu yerleşimde `core/` altında `src/` kalmaz → guard
   **sıfır dosya tarar, yeşil geçer**. Anayasa kural 1'in derleyiciye devredilmiş hâli
   kaybolur. Guard mutlaka `sourceSets` tabanlı yeniden yazılmalı.
4. **IDE.** Android Studio aynı dosyaları iki modülün altında indeksler; gezinme ve
   kırmızı çizgi davranışı **doğrulanmadı** (sync denenmedi).

### Seçenek 2 — `:core` fiziksel olarak `TeamCode/core/` altında ayrı modül  ✅ **ÖNERİ**

```groovy
// settings.gradle
include ':core'
project(':core').projectDir = file('TeamCode/core')
```

Katmanlar `TeamCode/core/src/main/java/boobuzz/core/{hal,logic,controller}/` altında.
TeamCode klasörünün içinde, her katman ayrı dizin — karar şartı karşılanıyor.

**Doğrulandı:** `projectDir` yeniden yönlendirmesiyle nested modül Gradle 9.1.0'da
sorunsuz derlendi (scratch projede koşturuldu).

**Riskler:**
1. Katman dizinleri OpMode'lardan bir seviye daha derinde (`TeamCode/core/src/...`).
   Kozmetik.
2. Bir Gradle projesinin dizini başka bir Gradle projesinin dizininin içinde. AGP
   `TeamCode/src/` dışını hiç taramadığı için derlemede sorun beklenmiyor, ama
   **Android Studio sync'i doğrulanmalı** (denenmedi).
3. `:core`'un `build/` dizini `TeamCode/core/build/` olur → `.gitignore` kontrol
   edilmeli.

**Riski olmayan yanları:** AGP'ye hiç dokunulmaz, deprecated API kullanılmaz, filtre
senkronu yoktur → çift derleme **yapısal olarak imkânsız** (dosyalar `TeamCode/src`'in
dışında). `sdk-guard` olduğu gibi çalışmaya devam eder (`projectDir` = `TeamCode/core`,
altında `src/` var) — yine de Adım 2'de sağlamlaştırılması önerilir.

### Seçenek 3 — TeamCode `:core` kaynaklarını kendi sourceSet'ine ekler, `:core` bağımlılığı kaldırılır

Yani tek derleme, TeamCode'da. **Reddedildi:** `:sim` ile robot aynı bytecode'u koşmaz
(sim `:core`'dan, robot TeamCode dex'inden alır); `:sim`'in bağımlılığı kalmaz; anayasa
kural 1 derleyicilikten çıkar. Kısıtları doğrudan ihlal ediyor.

### Karar: **Seçenek 2**

Gerekçe: bağlayıcı şartın üçünü de (görünür katman dizinleri / tek derleme / aynı
bytecode) karşılayan, deprecated API'ye ve elle senkronlanan filtre çiftine dayanmayan
tek seçenek. Seçenek 1'in tek üstünlüğü bir dizin seviyesi; bedeli ise AGP 9'a bağımlı
bir deprecated çağrı, sessiz çift derleme sınıfı bir hata ve guard'ın sessizce ölmesi.

> `boobuzz.core.*` paket adları **korunur** — Seçenek 2'de yalnız modülün fiziksel yeri
> değişir, `hal` paketi hiç `package` satırı değiştirmez. `boobuzz.{hal,logic,controller}`
> şeklinde `core` segmentini düşürmek daha sığ yollar verirdi ama 21 dosyanın import'unu
> kozmetik için değiştirir; yapılmıyor.

---

## B. Hedef ağaç

```
robot-code/
├── settings.gradle            :core projectDir → TeamCode/core
├── mechanism.yaml             tek gerçek kaynak (değişmez yer)
│
├── TeamCode/
│   ├── build.gradle           implementation project(':FtcRobotController') + project(':core')
│   │
│   ├── core/                          ← Gradle modülü :core — saf Java, FTC SDK YOK
│   │   ├── build.gradle               (sdk-guard uygulanır)
│   │   └── src/main/java/boobuzz/core/
│   │       ├── hal/           ── L1 SÖZLEŞMESİ (arayüz; implementasyon YOK)
│   │       │     Hal · GamepadSource · GamepadState · RobotState · RobotAction
│   │       ├── contract/      ── L2 ↔ L3 sözleşmeleri (mimari §6)
│   │       │     Intent · Drive · Request · RequestType
│   │       │     Feedback · RequestStatus · WorldSnapshot
│   │       ├── logic/         ── L2
│   │       │   ├── Subsystem.java            subsystem kalıbı (update, sabit sıra)
│   │       │   ├── engine/    RobotEngine · C1DriveEngine · PedroDriveEngine
│   │       │   └── drive/     DriveSubsystem · HalDrivetrain · HalLocalizer
│   │       │                  PedroConstants · PathRegistry
│   │       │   └── (shooter/ · intake/ · feeder/ · turret/ · world/  → Faz 2+,
│   │       │        boş açılmaz — mimari kural 9)
│   │       ├── controller/    ── L3
│   │       │     Controller · GamepadController
│   │       ├── RobotLoop.java            katmanlar arası tick (mimari §1)
│   │       ├── RobotFactory.java         engine+controller kurulumu — TEK yer (kural 6)
│   │       ├── mechanism/Mechanism.java  mechanism.yaml okuyucu
│   │       └── probe/  Probe · NullProbe
│   │   └── src/test/java/boobuzz/core/**   ana ağacı aynalar
│   │
│   └── src/main/java/org/firstinspires/ftc/teamcode/
│       ├── hal/       ── L1 İMPLEMENTASYONU — SDK'ya dokunan TEK yer
│       │     RealHal (yeni) · Hardware (revhub, HardwareMap, Pinpoint)
│       └── opmode/    ── kabuk: HAL + Engine + Controller birleştirir
│             SmokeTeleop · TeleopMain (yeni)
│
└── sim/                       ── L1'in sim tarafı — İNCE adapter, başka hiçbir şey
    └── src/main/java/boobuzz/sim/
          SimHal (soket→Python) · SimMain (kabuk) · Json
          ServerClosedException · SimProtocolException
    └── src/test/java/boobuzz/sim/  FakeSimServer · SimHalTest · SimMainTest
```

### Hangi dosya nereye gider

Kaynak: `robot-cx-02-rapor.md` §1 envanteri.

| Bugün | Yarın | Not |
|---|---|---|
| `core/` (modül kökü) | `TeamCode/core/` | `git mv` + `settings.gradle` bir satır |
| `…core/hal/{Hal,GamepadSource,GamepadState,RobotState,RobotAction}` | aynı paket | **paket değişmez**, sadece modül taşınır |
| `…core/control/{Intent,Drive,Request,RequestType,Feedback,RequestStatus,WorldSnapshot}` | `…core/contract/` | sözleşme ne L2 ne L3 |
| `…core/control/{Controller,GamepadController}` | `…core/controller/` | L3 |
| `…core/engine/{RobotEngine,C1DriveEngine}` | `…core/logic/engine/` | L2 |
| `…core/pedro/PedroDriveEngine` | `…core/logic/engine/` | engine'dir |
| `…core/pedro/{HalDrivetrain,HalLocalizer,PedroConstants,PathRegistry}` | `…core/logic/drive/` | drive subsystem'inin parçası |
| `…core/{RobotLoop,mechanism/Mechanism,probe/*}` | yerinde | katman dışı |
| `core/src/test/java/boobuzz/core/**` (7 test) | ana ağacı aynalayan paketler | bugün düz `boobuzz.core` |
| `TeamCode/…/teamcode/Hardware.java` | `teamcode/hal/Hardware.java` | alt paket; `namespace` değişmez |
| `TeamCode/…/teamcode/SmokeTeleop.java` | `teamcode/opmode/SmokeTeleop.java` | — |
| `sim/**` | **hiç taşınmaz** | hepsi L1/fixture; `mainClass` sabit |
| — | `…core/logic/Subsystem.java` (yeni) | subsystem kalıbı |
| — | `…core/logic/drive/DriveSubsystem.java` (yeni) | tek gerçek subsystem |
| — | `…core/RobotFactory.java` (yeni) | `SimMain` ↔ OpMode kopyasını öldürür |
| — | `teamcode/hal/RealHal.java` (yeni) | `Hal`'in robot tarafı bugün **yok** |
| — | `teamcode/opmode/TeleopMain.java` (yeni) | `RealHal` + `RobotLoop` üstünde |

`Hardware.java` `:core`'a **inemez** (revhub + `HardwareMap` + `com.qualcomm` →
`sdk-guard` build'i kırar). Doğru yer `teamcode/hal/`.

---

## C. Codex'e uygulama listesi — her adım bağımsız commit

Ortak doğrulama komutu (her adımın sonunda yeşil olmalı):

```bash
cd /home/shared/projects/boobuzz/robot-code
./gradlew :core:test :sim:test          # Java 17+ gerekir
./gradlew :TeamCode:assembleDebug       # AGP tarafı
```

Adım 1-9 `robot-code` reposunda; adım 10-12 `re-cock-nize` (Python fizik sunucusu).

---

**Adım 1 — `:core` modülünü `TeamCode/core/`'a taşı**
- `git mv core TeamCode/core`
- `settings.gradle`: `include ':core'` satırının altına
  `project(':core').projectDir = file('TeamCode/core')`
- `sim/build.gradle` ve `TeamCode/build.gradle`'daki `project(':core')` **değişmez**.
- `.gitignore`'da `build/` deseninin `TeamCode/core/build`'i de kapsadığını doğrula.
- Doğrulama: `:core:test :sim:test` + `:TeamCode:assembleDebug` yeşil; `./gradlew :sim:run`
  hâlâ çalışıyor.

**Adım 2 — `sdk-guard`'ı sourceSet tabanlı yap (guard'ın sessizce ölmesini önle)**
- `gradle/sdk-guard.gradle`: `fileTree(dir: projectDir, includes: ['src/**/*.java'])`
  yerine `sourceSets.main.java.asFileTree + sourceSets.test.java.asFileTree` kullan.
- Doğrulama: **kanarya** — `:core`'a geçici bir `import com.qualcomm.Foo;` satırı ekle,
  `./gradlew :core:compileJava` **kırılmalı**; satırı geri al, yeşile dön.

**Adım 3 — `control` → `contract` + `controller`**
- `Intent, Drive, Request, RequestType, Feedback, RequestStatus, WorldSnapshot`
  → `boobuzz.core.contract`
- `Controller, GamepadController` → `boobuzz.core.controller`
- Doğrulama: `:core:test :sim:test` yeşil.

**Adım 4 — L2 dizini: `engine`/`pedro` → `logic/`**
- `engine/*` + `pedro/PedroDriveEngine` → `boobuzz.core.logic.engine`
- `pedro/{HalDrivetrain,HalLocalizer,PedroConstants,PathRegistry}` → `boobuzz.core.logic.drive`
- Doğrulama: `:core:test :sim:test` yeşil.

**Adım 5 — testleri ana ağaca aynala**
- 7 test dosyası `boobuzz.core` / `boobuzz.core.pedro`'dan karşılık gelen yeni paketlere.
- Doğrulama: test sayısı düşmedi (31 test), hepsi yeşil.

**Adım 6 — subsystem mekanizması**
- `boobuzz.core.logic.Subsystem`: `String name(); void update(long now, RobotState s, RobotAction out);`
  (tam imza `Intent`/`Feedback` akışına göre netleştirilecek — L2 içi, sözleşme değil.)
- `logic/drive/DriveSubsystem`: bugün `C1DriveEngine`/`PedroDriveEngine` içindeki
  `Drive.Manual → motor gücü` ve Pedro follow yolu buraya taşınır.
- Engine'ler subsystem listesini **sabit sırayla** çağırır (mimari §4: scheduler yok).
- Doğrulama: yeni `DriveSubsystemTest`; mevcut engine testleri davranış değişmeden yeşil.

**Adım 7 — TeamCode katman dizinleri**
- `Hardware.java` → `teamcode/hal/`, `SmokeTeleop.java` → `teamcode/opmode/`
- Doğrulama: `:TeamCode:assembleDebug` yeşil **ve** Driver Station'da OpMode listesinde
  `SmokeTeleop` görünüyor (anotasyon taraması alt pakette bozulmamalı — cx-02 §6.1'de
  *doğrulanamamış* risk, burada gözle kapatılır).

**Adım 8 — `RealHal` + tek Pedro yığını**
- `teamcode/hal/RealHal.java`: `Hal` implementasyonu — motorlar, Pinpoint, voltaj.
- `Hardware` yalnız donanım kalır; içindeki `new Foresight(new ForesightConfig(cfg -> {}))`
  **kaldırılır** — Follower tek yerde, `logic/drive`'daki `PedroConstants.createFollower`'da.
- Pinpoint ofsetleri (`xPodOffset=161.0 mm`, `yPodOffset=0.0`, pod yönleri) `mechanism.yaml`'a
  taşınır; `mechanism.yaml`'daki `pinpoint: xyz: [0,0,0]` ile bugünkü **çelişki kapanır**
  (cx-02 §6.3 — taşımadan bağımsız en büyük risk).
- Doğrulama: `:TeamCode:assembleDebug`; robot eldeyse `TeleopMain` ile sürüş.

**Adım 9 — `RobotFactory`**
- `boobuzz.core.RobotFactory`: engine + controller seçimi/kurulumu tek yerde.
- `SimMain` (bugün 164 satırın ~40'ı bu seçim) ve yeni `TeleopMain` ondan çağırır.
- `SmokeTeleop` ya `RealHal`+`RobotLoop` üstüne taşınır ya da başlığında açıkça
  "SDK duman testi, `:core`'u bilerek atlar" diye işaretlenir (cx-02 §6.4).
- Doğrulama: `:sim:test` yeşil; `./gradlew :sim:run` ile Python sunucusuna karşı
  500 adım, aynı seed iki koşuda bit-bit aynı poz.

**Adım 10 — (`re-cock-nize`) motor elektrik modeli**
- Bugün: birinci derece motor, τ=0.1. Hedef: 4 tekerin **her birine** giden güç →
  voltaj → `kS`/`kV` ile tork → teker hızı; pil voltajı modeli (mimari §6: voltaj tek
  başına %20+ kaydırır).
- Parametreler `mechanism.yaml`'daki `motors.*.{kV,kS,free_rpm,ticks_per_rev}`'den okunur;
  protokol **değişmez** (`docs/protokol.md` bağlayıcı).
- Doğrulama: birim testler + entegrasyon koşusu; **determinizm korunmalı** (aynı seed
  iki koşuda bit-bit aynı).

**Adım 11 — (`re-cock-nize`) gerçek mecanum kinematiği**
- Teker hızları → gövde twist'i, `mechanism.yaml`'daki `pos` + `roller` açılarından
  türetilerek (ters kinematik matrisi, bugünkü katsayı kısayolu değil).
- Doğrulama: ileri / yan / dönüş / diyagonal için beklenen hız testleri; `Drive.GoTo`
  ve `Drive.FollowPath` simde Pedro ile koşuyor, iz kaydediliyor.

**Adım 12 — (`re-cock-nize`) geçen sezon kalibrasyonu**
- Kayma (slip), sağ/sol verimlilik farkı vb. **ayrı bir ajan arıyor.**
- Bulunursa `mechanism.yaml`/sim konfigürasyonuna girer, kaynağı (repo + commit) yorumda
  yazılır. **Bulunmazsa makul varsayılan kullanılır ve "varsayılan, ölçülmedi" diye
  açıkça işaretlenir.** Sessiz sihirli sayı yasak.
- Doğrulama: ileri 0.5 güç duvara mesafe testi (bugünkü referans: 131.30 vs truth 131.27)
  yeniden koşar ve sapma kayıt altına alınır.

**Adım 13 — Faz 1 kapanış koşusu**
- `RobotFactory` ile kurulmuş `PedroDriveEngine` + `GamepadController`, `SimHal` üstünde,
  viewer açık: klavyeyle sürülüyor; `FollowPath` ile bir yol koşuluyor; iz çiziliyor.
- Doğrulama: headless ~200×+ gerçek zaman, aynı seed bit-bit aynı, viewer'lı canlı sürüş.

**Adım 14 — dokümanlar**
- `docs/mimari.md` §10 ve §11'e kalibrasyon/elektrik modeli satırları; `plan.md` Faz 1
  kutucukları işaretlenir. (`docs/protokol.md`'ye **dokunulmaz** — protokol değişmiyor.)

---

## Bilinmezler (tahmin değil, doğrulanacak)

| # | Konu | Nasıl kapanır |
|---|---|---|
| 1 | Android Studio, `TeamCode/core` nested modülünü sorunsuz sync ediyor mu | Adım 1'den sonra IDE'de sync |
| 2 | OpMode anotasyon taraması `teamcode/opmode/` alt paketinde çalışıyor mu | Adım 7'de Driver Station listesi |
| 3 | `Subsystem.update` imzası (`RobotAction out` mu, dönüş değeri mi) | Adım 6'da `DriveSubsystem` yazılırken netleşir |
| 4 | Geçen sezon kalibrasyon verisi var mı | Ayrı ajan; yoksa varsayılan + işaret |
