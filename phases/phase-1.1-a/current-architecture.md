# Current architecture (as built)

**Snapshot:** docs baseline `dev-phase-1.1-a@8d80ba4`; robot-code
`dev-phase-1.1-a@d5bda62`; re-cock-nize `dev-phase-1.1-a@5dd6daa`.
This document describes source at those commits. Historical requirements remain in
`phases/phase-1.1/design-spec.md`; it is protected and is not rewritten here.

## 1. Repository and module map

```text
boobuzz/
├── robot-code/                 dev-phase-1.1-a
│   ├── TeamCode/core/          :core, pure Java 17
│   ├── TeamCode/src/           Android FTC shell: RealHal + OpModes
│   └── sim/                    :sim Java client (depends on :core only)
├── re-cock-nize/               dev-phase-1.1-a
│   ├── sim/                    Python JSON server, physics, viewer, bag/tap tools
│   └── tests/                  Python protocol/physics/determinism tests
└── docs/                       dev-phase-1.1-a (this checkout)
```

`settings.gradle` includes `:core` from `TeamCode/core` and `:sim` as a sibling
module (`robot-code/settings.gradle:9-16`). `:core` exposes only the Pedro pure-Java
artifact and JUnit (`robot-code/TeamCode/core/build.gradle:1-20`); `:sim` depends on
`:core`, never on TeamCode (`robot-code/sim/build.gradle:1-26`).

### Visible source tree

```text
TeamCode/core/src/main/java/boobuzz/core/
├── contract/  Event Feedback GamepadState IGamepadSource PathRequest
│              Request RequestBatch RequestStatus RequestStream RequestType
│              RobotAction RobotState WorldSnapshot
├── hal/       IHal Mechanism RobotConstants
├── subsystem/ ISubsystem IDrive IShooter IIntake ITurret Subsystems
│   ├── pedro/ HalDrivetrain HalLocalizer PathRegistry PedroConstants PedroDrive
│   └── stub/  StubShooter StubIntake StubTurret
├── logic/     IRobotEngine ShooterCalibration
│   ├── direct/ DirectEngine DirectMap
│   └── cplx1/  CplxEngine1 MotionLogic TurretLogic ShooterLogic
├── controller/ IController Buttons
│   ├── teleop/ TeleopController TeleopMap
│   ├── auto/   AutoBuilder AutoController AutoSequence AutoStep SequenceRunner
│   ├── opmodes/ AutoLocations AutoRegistry + six auto data classes
│   ├── replay/ ReplayController
│   └── socket/ SocketController
├── debug/     BagWriter DebugFrame DebugTap JsonCodec SeamJson SubsystemTrace
└── RobotLoop.java RobotFactory.java

TeamCode/src/main/java/org/firstinspires/ftc/teamcode/
├── hal/ RealHal Hardware
└── opmode/ AutoMain TeleopMain + six FTC OpMode wrappers

robot-code/sim/src/main/java/boobuzz/sim/
  SimHal Json SimMain SimProtocolException ServerClosedException

re-cock-nize/sim/
  server.py mechanism.py physics/{backend,motor,kinematic_backend,pymunk_backend,
  pybullet_backend,multi}.py bag.py tap.py viewer.py field.py encoder.py
```

| layer | package path | key classes |
|---|---|---|
| contract | `boobuzz.core.contract` | immutable records and enums listed above |
| HAL | `boobuzz.core.hal`; TeamCode `...hal` | `IHal`, `RobotConstants`, `Mechanism`, `RealHal`, `SimHal` |
| subsystem | `boobuzz.core.subsystem` | `ISubsystem`, four narrow interfaces, `Subsystems`, `PedroDrive`, stubs |
| logic | `boobuzz.core.logic` | `IRobotEngine`, `DirectEngine`, `CplxEngine1`, three cplx1 modules |
| controller | `boobuzz.core.controller` | `IController`, teleop/auto/replay/socket implementations |
| orchestration | `boobuzz.core` | `RobotLoop`, `RobotFactory` |
| debug seam | `boobuzz.core.debug` | immutable `DebugFrame`, `DebugTap`, JSON codec, bag writer |
| physics | `re-cock-nize.sim.physics` | `PhysicsBackend`, `MotorModel`, Pymunk/PyBullet/Kinematic |

## 2. Actual dependency direction

```text
contract  <── hal ── Mechanism/RobotConstants
    ▲          ▲
    │          └──────── subsystem ──► Pedro/stub implementations
    │                                  ▲
    └──────────── logic (Direct/Cplx1)─┘
    ▲                 ▲
    └──── controller ┘       debug ──► contract + subsystem trace

root RobotFactory/RobotLoop ──► all core packages
TeamCode Android (FTC SDK) ──► :core + RealHal/OpModes
:sim Java ──► :core ──TCP JSON──► re-cock-nize Python server
```

The import rule is mechanically checked (`robot-code/TeamCode/core/src/test/java/boobuzz/core/DependencyTest.java:14-94`).
The implementation deliberately permits `RobotConstants` in logic and controller,
and `debug` in replay/socket; those are the effective rules, not the older table's
shortened wording. `sdkGuard` rejects FTC/Android names in `:core` and `:sim` before
compilation (`robot-code/gradle/sdk-guard.gradle:1-37`).

## 3. One control tick

```text
RobotLoop (single thread)
  │  state = hal.read()                                  [RobotLoop.java:76-81]
  ▼
engine.sense(state)
  ├─ Subsystems.observe(state)                           [DirectEngine.java:40-43]
  ├─ PedroDrive feeds HalLocalizer; cplx1 updates turret/shooter pose
  └─ WorldSnapshot
  │  drain prior statuses → Feedback(world,statuses,t)
  ▼
controller.decide(feedback)                              [RobotLoop.java:82-88]
  │  RequestBatch = level RequestStream + edge Requests + cancels
  ▼
engine.act(batch)                                         [RobotLoop.java:89-108]
  ├─ cancel/switch arbitration and logic state transitions
  ├─ subsystem commands
  └─ Subsystems.update() → RobotAction (motors, servos, events)
  ▼
hal.write(action); publish immutable debug frame                  [RobotLoop.java:109-115]
```

There is no controller→engine feedback call in the same tick. Statuses emitted by
`act` are drained before the next `decide`, so completion is one tick delayed
(`robot-code/TeamCode/core/src/main/java/boobuzz/core/contract/RequestStatus.java:3-8`).
On a valid engine switch, the old engine receives cancel-all, the new engine starts
next tick, and the handoff tick writes `RobotAction.zero()` (`RobotLoop.java:89-112`).

## 4. HAL and subsystem ownership

```text
FTC HardwareMap/gamepad1 ──► RealHal ──► IHal
Python state/gamepad      ──► SimHal  ──► IHal
                                      │
                       RobotState ▲  │ RobotAction ▼
                                      │
      ISubsystem.observe(state) ─► engine ─► ISubsystem.update(builder)
```

`IHal` owns clock, raw sensors, outputs, and gamepad only (`robot-code/TeamCode/core/src/main/java/boobuzz/core/hal/IHal.java:14-24`).
`RealHal` configures motors/Pinpoint through `Hardware`, reads encoders, velocity,
yaw, voltage and FTC gamepad, and clamps writes (`robot-code/TeamCode/src/main/java/org/firstinspires/ftc/teamcode/hal/RealHal.java:23-82`).
`SimHal` blocks on reset/ready and each step/state pair; `truth` is retained only for
tests/viewer and never enters `RobotState` (`robot-code/sim/src/main/java/boobuzz/sim/SimHal.java:28-43,102-138,171-241`).

`ISubsystem` owns mechanism-local state and only `observe`/`update`; command methods
are the narrow drive/shooter/intake/turret interfaces (`robot-code/TeamCode/core/src/main/java/boobuzz/core/subsystem/ISubsystem.java:6-12`,
`IDrive.java:7-30`, `IShooter.java:3-14`, `IIntake.java:3-11`, `ITurret.java:3-14`).
`RobotFactory` currently wires one `PedroDrive` and three timing stubs, for both
engines (`robot-code/TeamCode/core/src/main/java/boobuzz/core/RobotFactory.java:76-100`).

## 5. Logic and controllers

```text
IRobotEngine
├── DirectEngine ── DirectMap ── one drive/shooter job + direct mechanism calls
└── CplxEngine1
    ├── MotionLogic  (manual vs GOTO/PATH/TURN_TO arbitration)
    ├── TurretLogic  (automatic alliance-goal aim; hold during shot)
    └── ShooterLogic (IDLE → SPINNING → FEEDING → DONE)

IController
├── TeleopController ── Buttons + TeleopMap ── optional Y AutoSequence
├── AutoController ── SequenceRunner ── six opmode data classes
├── ReplayController ── logic batches from a bag
└── SocketController ── latest validated RequestBatch over TCP
```

`IRobotEngine` is `sense(RobotState) → WorldSnapshot`, `act(RequestBatch)`,
`action()`, and `drainStatuses()` (`robot-code/TeamCode/core/src/main/java/boobuzz/core/logic/IRobotEngine.java:13-39`).
`CplxEngine1` constructs all three modules and routes reset, shot, spin-up and intake
requests (`.../logic/cplx1/CplxEngine1.java:20-95`). `MotionLogic` owns one active
drive job and cancels it for manual input or cancellation (`.../MotionLogic.java:15-80`).
`TurretLogic` scans only for a null pose, otherwise aims at the compile-time goal and
reports the stub's lock (`.../TurretLogic.java:10-49`). `ShooterLogic` sequences
spin-up, target lock, feed and cancellation (`.../ShooterLogic.java:13-91,121-176`).

Controllers never call subsystems. `TeleopMap` emits field-oriented `RequestStream`,
three-shot, intake, BACK reset, Y sequence and held-START engine switch requests
(`.../controller/teleop/TeleopMap.java:45-114`). Auto, replay and socket controllers
all implement the same `IController.decide(Feedback)` signature.

## 6. Contract records at the seams

| type | exact fields (units/meaning) | source |
|---|---|---|
| `RobotState` | `long t` ms; `Map<String,Integer> enc`; `Map<String,Double> vel` ticks/s; `double yaw` rad; `Pose pinpoint` inches/rad; `double voltage` V | `contract/RobotState.java:18-30` |
| `RobotAction` | `motors` name→power [-1,1]; `servos` name→position [0,1]; `List<Event> events` | `contract/RobotAction.java:8-25` |
| `RequestStream` | `vx, vy, omega` level values; `manualDrive` boolean; no id/status | `contract/RequestStream.java:3-11` |
| `Request` | `int id`; `RequestType type`; `double[] params`; optional `PathRequest path` (PATH only) | `contract/Request.java:5-17` |
| `RequestBatch` | `RequestStream stream`; `List<Request> requests`; `int[] cancels`; `CANCEL_ALL=Integer.MIN_VALUE` | `contract/RequestBatch.java:7-39` |
| `RequestStatus` | `id`, `State={ACTIVE,DONE,FAILED,REJECTED}`, `progress`, `note`; terminal = DONE/FAILED/REJECTED | `contract/RequestStatus.java:9-23` |
| `WorldSnapshot` | `t` ms, `Pose pose`, `yaw` rad, `voltage` V | `contract/WorldSnapshot.java:5-7` |
| `Feedback` | `WorldSnapshot world`, immutable `List<RequestStatus> statuses`, `long t` ms | `contract/Feedback.java:7-15` |
| `GamepadState` | sticks [-1,1], triggers [0,1], A/B/X/Y, LB/RB, D-pad, BACK/START | `contract/GamepadState.java:9-17` |
| `Event` | name, `tMs`, numeric `data` map; subsystem events are forwarded by SimHal | `contract/Event.java:9-11`; `sim/SimHal.java:171-190` |

`RequestType` currently contains `SHOOT, INTAKE, GOTO, PATH, SPIN_UP, INTAKE_ON,
INTAKE_OFF, TURN_TO, TURRET_AIM, RESET_POSE, SWITCH_ENGINE`; there is no `WAIT`
(`contract/RequestType.java:3-15`). `PathRequest` carries target/segments, heading,
hold-end, velocity and braking constraints (`contract/PathRequest.java:11-20,125-183`).

## 7. Simulator protocol and physics

```text
SimHal                         sim.server (TCP JSONL 127.0.0.1:5555)
  reset {seed,pose{x,y,h}} ───► validate → backend.reset →
  ◄── ready {proto,motors,servos,state(t=0,...)}
  read() returns ready/state
  write(action) ──────────────► step {dt_ms,motors,servos,events}
  ◄──────────────────────────── state {t_ms,enc,vel,imu,pinpoint,voltage,truth,gamepad}
  ... one step/state pair per tick ...
  bye ────────────────────────► close
```

The server requires positive integer `dt_ms`, declared motor powers in [-1,1],
servo positions in [0,1] (non-empty servo commands are currently rejected), and
numeric event payloads (`re-cock-nize/sim/server.py:97-132,748-820`). It never
advances physics before a valid step; `SimHal.write` blocks for the matching state
(`robot-code/sim/src/main/java/boobuzz/sim/SimHal.java:28-41,171-199`).

```text
PhysicsBackend.reset(seed, pose) / step(dt_ms,powers,events) / state(dt)
├── KinematicBackend  Euler baseline, clamp and explicit zero-power decel
├── PymunkBackend     shared PymunkWorld, rigid body, walls/contact/traction
└── PyBulletBackend   shared PyBulletWorld, planar rigid body, walls/contact
       └── MotorModel ── MotorSim (first-order lag) + MecanumKinematics
                         + quantized encoders + seeded sensor noise
```

The common model is in `re-cock-nize/sim/physics/motor.py:51-76,106-215`; backend
ownership is defined by `PhysicsBackend` (`.../physics/backend.py:11-37`). The Java
and Python sides use the same `RobotConstants.java` source, but the Python reader
only extracts its documented scalar/string/servo/motor subset (`sim/mechanism.py:20-31,112-211`).

For `--robots N`, the server listens on `port+i`, holds one backend per robot, and
first blocks an early `step` until every configured slot has connected and reset in
the current epoch. It then advances the shared world only after every ready client
has submitted one equal-`dt_ms` step; a missing client is evicted after the
configured per-tick deadline (`re-cock-nize/sim/server.py:453-524,554-614,651-658`;
`physics/multi.py:11-86`). The process-boundary proof compares canonical `ready`
and `state` JSONL across normal and staggered starts (`tests/test_process_network.py:188-280`).

## 8. Readiness and known gaps

- RealHal/Hardware are structurally wired, but no Control Hub run, physical Pinpoint
  offset check, Android scheduling test, or real mechanism acceptance is recorded.
- Shooter, intake and turret are timing/event stubs in both entry points; only Pedro
  drive reaches a production-like implementation (`RobotFactory.java:80-100`).
- `RobotConstants.ROBOT_MASS_KG` exists, while Pymunk/PyBullet still use literal
  `12.0` and stale “no constant” comments (`RobotConstants.java:16-19`;
  `pymunk_backend.py:79-87`; `pybullet_backend.py:183-196`).
- The original design's pseudo-code shows explicit subsystem observe/update calls;
  source places them inside engine `sense`/`act`. This document follows source.
- R7's independent review ended at `05d79ff`; R8 independently reviewed the
  post-review writer/bag fixes through `4b8ba23` with no findings
  (`phases/phase-1.1-a/review-robot-r8-sim.md:3-19`). R9's `1e555cb` turret-hold
  fix is included in `d5bda62`; simulator `78bad12` closes the startup barrier and
  `5dd6daa` adds exact process-boundary JSONL comparisons. The R9 cross-review has
  one coverage-only minor: the
  new hold test does not exercise the pending scan event
  (`phases/phase-1.1-a/review-robot-cx-22-sim.md:3-63`).

No protected document was edited. The next acceptance checklist is: close the
R9 scan-event coverage minor, resolve the RobotConstants mass parser/backend
mismatch, obtain post-R9 JVM/Android gates independently, and run a real Control
Hub + mechanism acceptance.
