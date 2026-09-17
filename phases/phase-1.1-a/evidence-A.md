# Chapter A evidence ledger

Status: **open, documentation-only.** This is the sole Chapter A evidence file.
It records approved pins, task slots, commands and limitations; an empty result is
not a passing result. No implementation or acceptance outcome is claimed here.

## Pinned inputs

| Repository / source | Branch | Pin | Role |
|---|---|---|---|
| docs | `dev-phase-1.1-a` | `e5796b7c1b005d4c1559d5339621c99080de0903` | v2.2 docs entry |
| robot-code (R) | `dev-phase-1.1-a` | `d5bda622d5bba6dfef6c4bfefed69e0cc20d7e67` | Java core, FTC adapter, Java sim |
| re-cock-nize (S) | `dev-phase-1.1-a` | `5dd6daacedbd629deb0827b36240f3064a808f3b` | Python server, physics and tests |
| archive (OLD) | archived source | `d7711d043280034ab5c75ae26a253629fd2d4a7b` | behavior/calibration provenance |

The protected `protokol.md` and `phases/phase-1.1/design-spec.md` are read-only.
R and S source are read-only for this documentation checkpoint. A source pin is
not a test result; later entries must name the exact command and artifact.

## Approved Chapter A slots

| Slot | Owner / seam | Planned evidence | State |
|---|---|---|---|
| A00 | D release cleanup | fixed-prefix retirement, English-content rule, ADR/evidence paths | **Recorded in this docs increment; no implementation outcome** |
| A01 | S transport/events | bounded fragmented I/O, integral millisecond events, no mixed-world advance | **Not started; no outcome recorded** |
| A02.0 | D + ftc-main protocol owner | `adr-device-seam-v2.md`; protected protocol amendment gate | **ADR draft recorded; protected amendment published at ftc-main `26f915b`; implementation/fixture evidence pending** |
| A02 | R/S mass seam + R regression | Java-source mass parsing, 18 kg isolated fixture, cancellation/deadband tests | **Not started; no outcome recorded** |
| A03 | R/S e2e seam | two fixed Pymunk scenarios and JSONL traces | **Not started; no outcome recorded** |
| A04 | R analysis + D evidence | extension of predecessor gamepad/request evidence with archive file:line handoff | **Handoff received; archive facts appended below; no test outcome** |
| A05 | R + D checkpoint | registry/order fixtures, A-drive/A-cancel gate, chapter manifest/tag only after approval | **Not started; no tag** |

## A00/A02 documentation record

- `00-common.md` now retains the English-content rule but no fixed message prefix.
- `adr-device-seam-v2.md` distinguishes current proto1 zero-fill from proposed
  proto2 positional-servo hold, keeps DC/CR omission at zero, lists paired devices,
  units, ownership and validation, and blocks code until ftc-main approves the
  protected protocol amendment.
- A02's planned Java-source reader rule requires a finite positive
  `ROBOT_MASS_KG` in kg, clear missing/invalid failure, and an isolated 18 kg body/
  inertia fixture. These are requirements for a future task, not completed tests.

## Commands and outcomes

| Check | Command / artifact | Outcome |
|---|---|---|
| Documentation diff | `git diff --check` | Pending for the next docs increment; prior evidence commit was clean |
| Mass parser | named A02 isolated fixture | Not run; no implementation dispatched |
| Protocol fixture | proto1/proto2 paired golden frames | Not run; protected amendment published at `26f915b`; paired fixture evidence pending |
| Chapter A e2e | A03 runner and two Pymunk scenarios | Not run; A03 not started |

Prior robot/simulator reports remain provenance references, not new Chapter A
outcomes. Their test counts and smoke results must not be copied into this ledger as
fresh evidence.

## A04 source-grounded handoff — preserve, correct, defer

ftc-watchdog supplied the archive handoff against OLD `d7711d0` (approved docs pin
`e5796b7` and R entry `d5bda62`). The entries below are archive-derived facts and
planned trace vectors, not newly run tests or implementation outcomes.

### Preserve

- GP1 mecanum: Blue uses `ly/lx/-rx`; Red negates `ly/lx`. Normal teleop is
  field-oriented false; Recovery is robot-oriented true. RT `> .5` requests
  `AUTO_SHOOT` in the zone and WARMUP outside. LB runs intake and feeder at `-1`
  while the shooter keeps running. LT `> .1` drives the default intake only while
  IDLE. GP1 D-pad applies configured turret steps and hood ±1°; Recovery applies
  turret ±2° and hood ±1°. B press parks/releases teleop; BACK held 2 s enters
  Recovery; START+Y held 2 s hard-resets (`contingency/lvbelc5/teleop/{BlueTeleop,RedTeleop}.java:74-171,184-217`; `controllers/RecoveryController.java:27-37,68-177`).
- Hardware remains one shooter mechanism with two DC motors, one hood with two
  complementary position servos, one turret with two equal CR-servo outputs, plus
  intake1, feeder1 and drive4. `shooterRight` is the speed source; `shooterLeft`
  actively drives the shooter and its encoder is the turret input (`HardwareConstants.java:147-160,282-307`).

### Correct / record

- RB's burst branch is disabled by `false &&`; RB therefore falls through the
  AUTO_SHOOT pulse-plus-delay path (`ShootingController.java:103-110`). GP1 A's
  manual-feeder branch is commented/cleared (`:165-169,465-471`).
- Y without START toggles shooter and feeder sign every 500 ms and commands intake
  `+1` (`ShootingController.java:89-103,292-305`). Shooting intake is `.8`, idle
  default is `1`; HC `holdPower=.2` is declared but unused (`HardwareConstants.java:90-114`; `ShootingController.java:321-357,457-463`).
- Active feeder timing is a 350 ms pulse plus a 100 ms post-pulse delay
  (`ShootingController.java:38-40,321-334`); HC `postPulseDelayMs=500` has no caller
  (`HardwareConstants.java:611-612`). Recovery hood 45° is from
  `RecoveryController.DEFAULT_HOOD_ANGLE` (`RecoveryController.java:27-30,163-165`),
  not HC's default 44°.
- Reset precedence remains a decision before porting: Teleop BACK calls
  `RecoveryController.checkToggle` (`BlueTeleop.java:81-82`), while
  `LocalizerController.handleBackButtonReset` is a distinct rising-edge vision
  reset (`LocalizerController.java:125-145`); START+Y uses
  `System.currentTimeMillis`. Central encoder reset is a new fix, not archive behavior.

### Defer

- GP2 tuning UI and the disabled RPM test remain out of A04. The archive Limelight
  is active but tolerates absence (`Limelight.java:43-50,80-109`; `LocalizerController.java:75-109,150-188`); its adapter belongs to Vision-A, while B remains odometry-only.
- `intake_dist` is an unused declaration; capacity3 is archive configuration.
  Turret analog calibration still needs physical work. Runtime shooter tuning is
  applied from `ShooterPidfPowerStorage.java:13-43` by
  `ShooterPidfPowerSubsystem.java:42-53`; HC values are boot defaults.
- Pinpoint uses active forwardPodY=161 / strafePodX=0, FORWARD/REVERSED and 4_BAR
  (`drivetrain/pedroPathing/Constants.java:41-48`); HC `-84/-168` is unused.
  Archive shooter constants use 28 ticks and ratio 1.6, while turret uses 8192/.715
  (`HardwareConstants.java:154-160,287-296`).

## A04 planned golden actuator traces (not run)

| ID | Planned vector and expected archive-derived shape | Source anchor |
|---|---|---|
| T1 IDLE | shooter R/L=0; hood holds explicit pair; turret CR pair=0; intake/feeder=0 | `HardwareConstants.java:90-114,147-160,282-307` |
| T2 RT/RB | shooter R=`p`, L=`p*followerScale`; speed reads RIGHT; hood aims; turret=`(q,q)`; feeder waits ready then 350+100 ms; intake=.8; RB uses AUTO_SHOOT because burst is disabled | `ShootingController.java:103-110,321-357`; `HardwareConstants.java:147-160` |
| T3 LB | shooter unchanged; hood/turret track; intake=-1 and feeder=-1 | `BlueTeleop.java:89-103`; `ShootingController.java:321-357` |
| T4 Y | shooter R/L signs toggle together every 500 ms; feeder follows; intake=+1; hood=25°; turret=`(q,q)` | `ShootingController.java:89-103,292-305` |
| T5 Recovery | shooter target 4000 RPM; hood 45° = `(0.4266667,0.5733333)`; turret target 0 with equal CR power | `RecoveryController.java:27-30,163-165`; `HardwareConstants.java:668-688` |
| T6 pairs | `s=215*(clamp(a,25,50)-25)/25`; left=`1-s/300`, right=`s/300`; 25°→(1,0), 44°→(.4553333,.5446667), 50°→(.2833333,.7166667); turret outputs equal | `HardwareConstants.java:668-688`; `TurretPidPazarSubsystem.java:309-310` |
| T7 shared port | shooter writes R=`p`, L=`p*follower`; speed reads RIGHT; turret reads `shooterLeft` position/sign/gear and writes only both CR outputs | `ShooterPidfPowerSubsystem.java:268-275`; `TurretPidPazarSubsystem.java:146-212,298-310` |

These vectors define what a later A04/B01 fixture should compare; they do not claim
that the current Java core, adapter, plant or physical robot already produces them.
No `legacy-behavior-matrix.md` is created.

## Safety and publication boundary

No code, protocol, tag, reviewer, ball, training or phase change is authorized by
this ledger. The proto2 decision, paired fixtures, and A02 mass proof remain review
gates. Future evidence must separate `unit-tested`, `sim-integrated`,
`Android-built`, `archive-derived`, and `hardware-validated`; the last label remains
absent until a physical robot is available.
