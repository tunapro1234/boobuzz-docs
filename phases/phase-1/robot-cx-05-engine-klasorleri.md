# robot-cx-05 — core sadeleştirme: tek engine (cplx_engine_1, Pedro'lu) + review düzeltmeleri

Repo: robot-code, dal `dev-phase-1` (HEAD 0694bc7). Her madde AYRI commit + anında push.
Kod yazmadan önce ilgili dosyayı oku. Bloat yok. `contract/` paketine DOKUNMA (Tuna donduracak).

## A. Hedef ağaç (Tuna onayladı) — `TeamCode/core/src/main/java/boobuzz/core/`
  hal/          Hal, RobotState, RobotAction, GamepadState, GamepadSource, Mechanism, Probe, NullProbe
  logic/        RobotEngine.java, Subsystem.java (ortak arayüzler, kökte)
  logic/cplx_engine_1/   PedroDriveEngine → adı `CplxEngine1` olur; DriveSubsystem, HalDrivetrain,
                         HalLocalizer, PathRegistry, PedroConstants
  controller/   Controller, GamepadController
  contract/     (değişmez)
  RobotLoop.java, RobotFactory.java (kökte)
Kalkanlar: `mechanism/`, `probe/` (→ hal/), `logic/engine/`, `logic/drive/`, **C1DriveEngine** (Faz 0
kalıntısı, Pedro'suz; SİL — testleri dahil). Tek engine var: `cplx_engine_1` = Pedro'lu C1.
Java paketleri dizinle aynı (`boobuzz.core.logic.cplx_engine_1`, `boobuzz.core.hal`).
`RobotFactory`: engine seçimi kalkar ya da tek ad `cplx_engine_1`; SimMain `--engine` bayrağı
kaldırılır (varsayılan tek engine), `--path` kalır. Testler dizin yapısını aynalar; boş artık
dizinleri sil. Adım sırası: A1 mechanism+probe→hal · A2 C1DriveEngine sil · A3 cplx_engine_1 taşıma
+ yeniden adlandırma · A4 RobotFactory/SimMain sadeleştirme.

## B. Review düzeltmeleri (robot-cx-04 Opus review)
B1. `PedroConstants` fizik sabitleri (73.63/54.09/36.17/85.98) Java'da gömülü → `mechanism.yaml`
    `physics` bloğundan `Mechanism.physics()` ile oku; `createFollower(Mechanism, ...)`. Tek kaynak.
B2. `opmode/SmokeTeleop.java` — davranışsız `@TeleOp` kopyası; SİL.
B3. `DriveSubsystem` testleri: GoTo→Hold→Velocity geçişleri, `sameCommand` yeniden başlatma,
    `deltaTimeSeconds` (dt=0 ve normal). En az 4 yeni test, gerçek assert.
B4. Küçük: `DriveSubsystem` yanıltıcı "C1'de subsystem yok" mesajı düzelt; her tick
    `follower.stop()` → yalnız geçişte; `Hardware` `left()>=0` eşiğine yorum.

## C. Kabul
`JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew :core:test :sim:test :TeamCode:assembleDebug` yeşil;
SimMain `--path test-line` port 5556 1000 adım hedefte (sim: re-cock-nize dev-phase-1 6432808).
Rapor ≤15 satır bp msg ftc-main: hash'ler, `find TeamCode/core/src/main -type d` çıktısı, test sayısı.
Commit dipnotu: Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com> / Claude-Session: https://claude.ai/code/session_01SdkrbNwP3QT1rYDjT5r478

## A5 (ek, Tuna) — Mechanism sadeleştirme
`Mechanism.java` (359 satır) ikiye: `hal/Mechanism` = saf veri record'u (motorlar, pinpoint, physics,
geometri); `hal/MechanismLoader` = yalnız YAML okuma. Kullanılmayan alan/metotları (grep ile
robot-code + sim çağrılarına bak) SİL. Toplam satır belirgin düşmeli; rapora önce/sonra satır sayısı.
