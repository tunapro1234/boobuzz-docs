# robot-cx-02 raporu — L1/L2/L3 katman ağacı (öneri, kod yok)

Repo `robot-code`, dal `dev-phase-2`, HEAD `dd4bd3f`. Her iddia dosyadan okunarak doğrulandı; doğrulanamayan
**doğrulanamadı** diye işaretli. Hiçbir kaynak dosya değiştirilmedi.

## 1. Mevcut ağaç + katman etiketi

`FtcRobotController/` (99 dosya) **dokunulmaz, katman dışı** — SDK'nın kendi modülü.

| Dosya | Katman | Neden |
|---|---|---|
| `TeamCode/…/teamcode/Hardware.java` | **L1** | `HardwareMap`, revhub `Mecanum`, `PinpointLocalizer`, Pinpoint ofsetleri. Ama içinde **kendi `Follower`'ını** kuruyor (`new Foresight(new ForesightConfig(cfg -> {}))`) → L2 sızıntısı |
| `TeamCode/…/teamcode/SmokeTeleop.java` | kabuk (+ kaçak L3/L2) | `@TeleOp`; `follower.manual(...)` çağırıyor, `:core`'u hiç kullanmıyor |
| `core/…/core/hal/{Hal,GamepadSource,GamepadState,RobotState,RobotAction}.java` | **L1 sözleşmesi** | Arayüz + motor seviyesi seam DTO'ları (mimari §3); implementasyon yok |
| `core/…/core/control/Controller.java`, `GamepadController.java` | **L3** | `decide(Feedback)->Intent` |
| `core/…/core/control/Intent/Drive/Request/RequestType/Feedback/RequestStatus/WorldSnapshot.java` | **L2↔L3 sözleşmesi** | mimari §6 "Sözleşmeler"; ne L2 ne L3 — ikisinin arasında |
| `core/…/core/engine/RobotEngine.java`, `C1DriveEngine.java` | **L2** | `sense`/`act` |
| `core/…/core/pedro/*` (5 dosya) | **L2** | `PedroDriveEngine` engine; `HalDrivetrain`/`HalLocalizer` Pedro↔HAL adaptörü (donanıma yazmıyor); `PedroConstants`/`PathRegistry` konfig |
| `core/…/core/{RobotLoop,mechanism/Mechanism,probe/*}.java` | katman dışı | tick (mimari §1), `mechanism.yaml` okuyucu, musluk (§9) |
| `core/src/test/java/boobuzz/core/**` (7 test) | test | **Hepsi `boobuzz.core` veya `boobuzz.core.pedro` paketinde** — ana ağacı aynalamıyor |
| `sim/…/sim/SimHal.java` + `{Json,SimProtocolException,ServerClosedException}.java` | **L1** | Soket istemcisi (`Hal` impl.) + protokol taşıma |
| `sim/…/sim/SimMain.java` | kabuk (sim'in "OpMode"u) | Engine/controller seçimi + döngü |
| `sim/src/test/java/…/FakeSimServer.java`, `SimHalTest.java` | test fixture | — |

Not: `TeamCode`'da **`RealHal` yok** — `Hal`'in robot tarafı hiç yazılmamış (`TeamCode/src` altında yalnız bu iki Java dosyası var).

## 2. Önerilen ağaç

TeamCode (bağlayıcı şart: L1/L2/L3 dizin düzeyinde görünür; TeamCode'da yalnız L1 + kabuk olur):

```
org.firstinspires.ftc.teamcode
├── l1.hal/      RealHal, Hardware        ← SDK'lı tek yer (revhub, HardwareMap, Pinpoint)
├── opmode/      SmokeTeleop, TeleopMain, AutoMain   ← kabuk: HAL+Engine+Controller birleştirir
└── (l2/, l3/ dizini AÇILMAZ — boş kalması kuralın kendisidir; L2/L3 :core'dadır)
```

`:core` — öneri A (**tavsiye**, katman öneki alsın):

```
boobuzz.core            RobotLoop                       (tick, katmanlar arası)
boobuzz.core.l1         Hal, GamepadSource, GamepadState, RobotState, RobotAction
boobuzz.core.contract   Intent, Drive, Request, RequestType, Feedback, RequestStatus, WorldSnapshot
boobuzz.core.l2.engine  RobotEngine, C1DriveEngine, PedroDriveEngine
boobuzz.core.l2.pedro   HalDrivetrain, HalLocalizer, PedroConstants, PathRegistry
boobuzz.core.l2.world   (C4'te: WorldModel, Predictor, …; adapters/ altında)
boobuzz.core.l3         Controller, GamepadController
boobuzz.core.mechanism / .probe            (katman dışı)
```

Gerekçe: `control` bugün L3 sınıflarıyla L2↔L3 sözleşmelerini aynı yere koyuyor; sözleşmeler ne L2 ne
L3'tür, ayrı `contract` bunu görünür kılar. `l1`'in `:core`'da olması çelişki değil: orada arayüz var,
implementasyon yok. **Maliyet:** mimari.md §7 `core/world/` yazıyor, öneri A ile `core/l2/world/` olur → §7'de tek satır güncelleme.
Öneri B (öneksiz): bugünkü adlar korunur, sadece `control` → `contract` + `l3` ayrılır; mimari.md'ye
dokunulmaz, katman isimden okunmaz — modül sınırı zaten L1/L2 ayrımını derleyiciye devretmiş durumda.

## 3. Taşıma listesi (commit adayları)

Her satır `git mv` + paket satırı + import düzeltmesi; her commit'ten sonra
`./gradlew :core:test :sim:test` ve TeamCode derlemesi yeşil olmalı.

1. **TeamCode L1 dizini:** `teamcode/Hardware.java` → `teamcode/l1/hal/Hardware.java`;
   `teamcode/SmokeTeleop.java` → `teamcode/opmode/SmokeTeleop.java`
2. **`:core` L1 sözleşmesi:** `core/hal/{Hal,GamepadSource,GamepadState,RobotState,RobotAction}.java` → `core/l1/`
3. **Sözleşme/L3 ayrımı:** `core/control/{Intent,Drive,Request,RequestType,Feedback,RequestStatus,WorldSnapshot}.java`
   → `core/contract/`; `core/control/{Controller,GamepadController}.java` → `core/l3/`
4. **L2:** `core/engine/*` → `core/l2/engine/`; `core/pedro/*` → `core/l2/pedro/`
5. **Testleri ana ağaca aynala:** `core/src/test/java/boobuzz/core/*Test.java` → `l2/engine`, `l3`, `mechanism`,
   kök paketleri; `…/core/pedro/*Test.java` → `…/core/l2/pedro/`
6. (öneri A seçilirse) `docs/mimari.md` §7 yol güncellemesi.

`:sim` dosyalarından **hiçbiri taşınmaz** (tek paket, hepsi L1). `Hardware.java` `:core`'a **inemez**
(revhub + `HardwareMap` + `com.qualcomm` → `sdk-guard.gradle` build'i kırar).

## 4. Gradle yönü (dosyalar okundu)

- `TeamCode/build.gradle`: `implementation project(':FtcRobotController')` + `implementation project(':core')` → **TeamCode → :core** ✔
- `sim/build.gradle`: `implementation project(':core')` → **:sim → :core** ✔; TeamCode'a bağımlılık yok ✔
- `core/build.gradle`: hiçbir proje bağımlılığı yok → ters ok yok ✔
- Pedro core: `core/build.gradle`'da **`api 'com.pedropathing:core:3.0.0'`** ✔ (`api` olduğu için `Pose` TeamCode ve `:sim` derleme yoluna sızıyor; `RobotState.pinpoint()` `Pose` döndürdüğü için bu bilinçli)
- Pedro revhub: `build.dependencies.gradle`'da `implementation 'com.pedropathing:revhub:3.0.0'`; bu dosya **hem TeamCode hem FtcRobotController tarafından apply ediliyor** → revhub ikisine de giriyor ve core'u transitive çekiyor; TeamCode Pedro core'u iki yoldan alıyor, ikisi de 3.0.0 olduğu sürece sorunsuz.
- `gradle/sdk-guard.gradle` `:core`+`:sim`'e apply; regex `com\.qualcomm|org\.firstinspires|android\.` — Pedro'yu kapsamıyor, doğru.
- **Değişmesi gereken satır yok**: taşımalar paket adını değiştiriyor, modül sınırını değil. Tek aday `:sim`'in `mainClass = 'boobuzz.sim.SimMain'` satırı, `SimMain` taşınmadığı için o da sabit.

## 5. `:sim` tut/sil — iki seçeneğin maliyeti (karar ftc-main'in)

"İnce L1 adapter" testi: `SimHal` ✔, `Json`/iki exception ✔ (protokol taşıma), `FakeSimServer`+`SimHalTest` ✔
(fixture), `SimMain` ✔ tanımda sayılmış ama **içinde karar mantığı var**: engine (`pedro` vs C1) ve controller
(gamepad / sabit `Manual` / `FollowPath`) seçimi `main` içinde, 164 satırın ~40'ı. Gelecekteki TeleOp OpMode'u
aynı seçimi ikinci kez yazacak → kural 6'ya yakın kopya. İki seçenekte de çözüm aynı: `:core`'da tek bir
`RobotFactory` (engine+controller kurulumu), `SimMain` ve OpMode ondan çağırsın.

| | Tutmak (bugünkü hâl) | Silip `:core`'a katmak |
|---|---|---|
| Maliyet | 0 taşıma; `:sim` zaten sdk-guard'lı, `application` eklentisiyle `./gradlew :sim:run` çalışıyor | `SimHal` + soket + `Json` `:core`'a girer; `:core` artık "saf mantık" değil, ağ istemcisi taşır |
| Kural 1 | Korunur (ayrı modül, guard) | Korunur ama `:core`'un rolü bulanır |
| Kural 3 (`if (isSim)` yok) | Modül sınırı bunu fiziksel kılar | `:core` içinde iki HAL yan yana; sızıntı riski disipline kalır |
| Robot APK | `:sim` APK'ya hiç girmez | Soket/JSON kodu robot APK'sına girer (ölü ağırlık) |
| Test | `FakeSimServer` `:sim` testinde izole | `:core` testi soket açar; `:core` testleri yavaşlar |
| Kazanç | — | Bir Gradle modülü eksilir; `settings.gradle`, `sim/build.gradle` gider |

## 6. Riskler

1. **OpMode kaydı:** `FtcOpModeRegister.register()` gövdesi boş; kayıt `@TeleOp`/`@Autonomous` anotasyon taramasıyla
   (`TeamCode/lib/OpModeAnnotationProcessor.jar`). Tarama anotasyona baktığı için `opmode/` alt paketi kaydı bozmamalı —
   **fiilen doğrulanamadı** (DS'te denenmedi); taşıma sonrası Driver Station listesi gözle kontrol edilmeli.
2. **Android paket adı:** `TeamCode/build.gradle` `namespace = 'org.firstinspires.ftc.teamcode'`,
   `applicationId 'com.qualcomm.ftcrobotcontroller'` (`build.common.gradle`). **Alt paket** açmak
   (`…teamcode.l1.hal`) namespace'i değiştirmez, güvenli. Kök paketi (`org.firstinspires.ftc.teamcode`)
   değiştirmek `namespace` + `R`/`BuildConfig` üretimini etkiler → yapılmamalı.
   `:core` paketleri `boobuzz.*`; Android için sorun yok, ama `l1`/`l2` gibi segmentlerin **rakamla
   başlamaması** şart (başlamıyorlar).
3. **`Hardware.java` ve Pinpoint ofsetleri (en büyük risk, taşımadan bağımsız):** `Hardware`
   `xPodOffset=161.0 mm`, `yPodOffset=0.0`, xPod FORWARD, yPod REVERSED, `goBILDA_4_BAR_POD`, birim MM
   taşıyor ("yeni robotta yeniden ölçülecek" notuyla); `mechanism.yaml` ise `pinpoint: xyz: [0,0,0]` diyor →
   **sim ile robotun odometri ofseti bugün farklı.** Ayrıca `Hardware` kendi Follower'ını **ayarsız**
   `ForesightConfig(cfg -> {})` ile kuruyor, `:core`'daki `PedroConstants.createFollower` ise ayarlı → robotta
   ve simde **iki farklı Pedro yığını** (kural 6 ihlaline aday). Hedef: `Hardware` yalnız donanım kalsın,
   Follower tek yerde (`PedroDriveEngine`) kalsın, ofsetler `mechanism.yaml`'a taşınsın. Kapsam dışı ama planlanmalı.
4. **`SmokeTeleop` `:core`'u atlıyor** (`follower.manual(...)` doğrudan): taşıma sonrası da kuralın istisnası kalır;
   ya `RealHal`+`RobotLoop` üstüne yazılmalı ya da açıkça "SDK duman testi" diye işaretlenmeli.
5. **Testler:** `:core` testleri paket-private erişime dayanmıyor → taşınmaları güvenli. `MechanismTest`/`SimHalTest`
   `Path.of("..","mechanism.yaml")` ile çalışma dizinine bağımlı; paket taşıması etkilemez, modül taşıması eder.
