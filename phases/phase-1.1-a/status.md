# Phase 1.1-a status — evidence ledger

**As-of:** 2026-09-17. This is an as-built audit, not a phase-close decision.
Protected `protokol.md` and `design-spec.md` are unchanged.

## Snapshot and scope

| checkout | branch | audited commit | role |
|---|---|---|---|
| docs | `dev-phase-1.1-a` | `21dae9a` | evidence ledger and reports |
| robot-code | `dev-phase-1.1-a` | `d5bda62` | Java `:core`, FTC `TeamCode`, Java `:sim` |
| re-cock-nize | `dev-phase-1.1-a` | `518bf9c` | Python server, physics and tests |

The four seed task/log files were pushed in `21dae9a`. Robot and simulator source
checkouts are read-only for this task. No reviewer, ball task, tag, merge, or phase
transition is authorized (`docs-cx-10-evidence-and-log.md:3-22`).

## Approved requirements and implementation evidence

| approved requirement | implementation evidence | current reading |
|---|---|---|
| Four pure-Java core layers, with contract DTOs and an SDK boundary | Design says HAL/Subsystem/Logic/Controller and SDK-free core (`phase-1.1/design-spec.md:12-31`). `DependencyTest` mechanically permits contract → none, hal → contract, subsystem → contract/Mechanism, logic → contract/subsystem/RobotConstants, and controller → contract/RobotConstants/debug (`robot-code/TeamCode/core/src/test/java/boobuzz/core/DependencyTest.java:14-94`). `sdkGuard` rejects FTC/Android references before compile (`robot-code/gradle/sdk-guard.gradle:1-37`). | **Implemented.** The effective guard is slightly wider than the original prose table because compile-time constants are intentionally allowed in logic/controller. |
| One compile-time configuration source shared with the simulator | `RobotConstants` is plain Java constants, including wheel/motor/Pinpoint and timing values (`robot-code/TeamCode/core/src/main/java/boobuzz/core/hal/RobotConstants.java:8-76`). The Python reader extracts scalar, string, servo and seven-field motor lines, validates them, and builds its `Mechanism` (`re-cock-nize/sim/mechanism.py:1-7,20-31,112-211`). | **Implemented for the parsed fields.** The parser does not consume every Java constant (for example shooter, debug-port, and mass fields); see gaps. |
| HAL isolates robot and simulator | `IHal` exposes `now`, `read`, `write`, and `get` only (`robot-code/TeamCode/core/src/main/java/boobuzz/core/hal/IHal.java:14-24`). `RealHal` maps FTC motors, servos, Pinpoint, voltage, and gamepad (`robot-code/TeamCode/src/main/java/org/firstinspires/ftc/teamcode/hal/RealHal.java:23-82`); `SimHal` speaks line JSON and keeps `truth` out of `RobotState` (`robot-code/sim/src/main/java/boobuzz/sim/SimHal.java:28-43,142-167,210-241`). | **Implemented.** The hardware path has not been run on a Control Hub in this ledger. |
| Narrow subsystem APIs and a wiring-only direct engine | `ISubsystem` is observe/update; `IDrive`, `IShooter`, `IIntake`, and `ITurret` are narrow (`robot-code/TeamCode/core/src/main/java/boobuzz/core/subsystem/ISubsystem.java:6-12`, `IDrive.java:7-30`, `IShooter.java:3-14`, `IIntake.java:3-11`, `ITurret.java:3-14`). `RobotFactory` builds one Pedro drive plus shooter/intake/turret stubs and both engines (`robot-code/TeamCode/core/src/main/java/boobuzz/core/RobotFactory.java:76-100`). | **Core shape implemented; real non-drive mechanisms remain stubs.** |
| Pedro bridge and cplx1 logic | `PedroDrive` feeds `HalLocalizer`, uses `HalDrivetrain`, and maps `PathRequest` to Pedro paths (`robot-code/TeamCode/core/src/main/java/boobuzz/core/subsystem/pedro/PedroDrive.java:20-55,130-188`). `CplxEngine1` owns `MotionLogic`, `TurretLogic`, and `ShooterLogic` (`robot-code/TeamCode/core/src/main/java/boobuzz/core/logic/cplx1/CplxEngine1.java:20-52`). | **Implemented and host-tested; actuator fidelity is limited by stubs.** |
| Fixed tick and one-tick status delay | The design order is documented as read/observe/sense/decide/act/update/write (`phase-1.1/design-spec.md:64-74`). In code, `RobotLoop.tick` performs read, engine sense, controller decide, engine act, action write, and seam publication (`robot-code/TeamCode/core/src/main/java/boobuzz/core/RobotLoop.java:76-115`); each engine calls `subsystems.observe` in `sense` and `subsystems.update` in `act`. | **Implemented with an abstraction correction:** observe/update are engine-owned, not separate `RobotLoop` calls. Statuses are drained before decide and produced by the preceding act (`IRobotEngine.java:21-39`; `RequestStatus.java:3-8`). |
| Autos, rigid-body backends, and S3 multi-robot lockstep | The acceptance run reports all 42 backend/engine/scenario rows successful, maximum `Δxy=0.139 in`, `|Δh|=0.229°` (`phase-1.1/acceptance-sim-cx-19.md:3-50,72-78`). It records two-robot lockstep and deterministic hashes for Pymunk and kinematic (`:63-70`). Server barriers require all ready clients to submit the same positive `dt_ms` before stepping (`re-cock-nize/sim/server.py:453-524,554-614`). | **Host acceptance evidence exists at its stated pins.** A startup-race anomaly was observed and documented (`acceptance-sim-cx-19.md:74-75`); current server code has epoch/barrier handling but needs a fresh worker review. |
| R4 tap, bag, replay, and socket seams | R7 review found no blocker/major at `05d79ff`, with 120 core + 10 sim tests and `TeamCode:assembleDebug` green (`phase-1.1/review-sim-cx-20-r7.md:3-20,124-147`). The current branch then added bounded writer shutdown (`robot-code@0b77bee`) and terminal bag-error propagation (`robot-code@4b8ba23`; source at `RobotLoop.java:163-169,214-227`, `DebugTap.java:120-152,168-236`, `BagWriter.java:83-110`). | **R7 evidence is superseded for these two changes.** M2 writer-deadline/shutdown and M3 late bag-error findings were addressed in source, but an independent review at `4b8ba23` is pending. |

## Test evidence, separated by execution target

### Host JVM and Python

- Robot-cx-22's full verification at the pushed R9 result reports `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew :core:test :sim:test :TeamCode:assembleDebug --rerun-tasks`: **122 core + 10 sim tests, zero failures/errors/skips**, both SDK guards passed, and `:TeamCode:assembleDebug` passed (`robot-cx-22-report.md:81-85`).
- The earlier R7 cross-review independently ran the same core/sim tests with **120 core + 10 sim tests** at `05d79ff` (`review-sim-cx-20-r7.md:8-16`). Keep the pin distinction: R9's 122-test result is worker evidence at `d5bda62`, not an independent docs run.
- Simulator acceptance ran all six autos and `test-line` for direct and cplx1 over Pymunk, PyBullet, and kinematic; all 42 rows exited successfully and remained within the stated tolerances (`acceptance-sim-cx-19.md:5-50,72-78`).
- The same acceptance records two-robot Pymunk overlap, seeded Pymunk/kinematic hashes, and record/replay of a 3,001-line bag (`acceptance-sim-cx-19.md:63-70`).
- Python backends share `MotorModel`/`MecanumKinematics`; backend implementations own rigid-body integration (`re-cock-nize/sim/physics/backend.py:11-37`, `motor.py:51-76,106-215`).

### Android build and real hardware

- The R9 worker reports `:TeamCode:assembleDebug` green at `d5bda62` (`robot-cx-22-report.md:81-85`); the R8 simulator cross-review also ran focused Java tests and a 1,000-tick smoke (`review-robot-r8-sim.md:9-19`). This is worker evidence, not a fresh docs-owned build.
- `RealHal` is structurally ready: it obtains FTC devices through `Hardware`, configures four wheel motors and Pinpoint, reads encoders/velocity/yaw/voltage, clamps writes, and maps `gamepad1` (`robot-code/TeamCode/src/main/java/org/firstinspires/ftc/teamcode/hal/Hardware.java:24-72`; `RealHal.java:23-82`).
- **No Control Hub, oldest-supported Android API, or physical mechanism run is evidenced here.** `RobotFactory` still supplies `StubShooter`, `StubIntake`, and `StubTurret` even to `AutoMain`/`TeleopMain` (`robot-code/TeamCode/core/src/main/java/boobuzz/core/RobotFactory.java:80-100`; opmode shells `TeamCode/src/main/java/org/firstinspires/ftc/teamcode/opmode/AutoMain.java:22-59`, `TeleopMain.java:23-67`).

## Remaining source/spec gaps

1. **Real mechanism integration:** there is no production shooter, intake, or turret implementation; the current stubs provide timing/events only (`StubShooter.java:9-11`, `StubIntake.java:9-10`, `StubTurret.java:10-11`). RealHal cannot make those actuators real by itself.
2. **Configuration coverage:** `RobotConstants.ROBOT_MASS_KG` is defined (`RobotConstants.java:16-19`), but both rigid-body backends still hard-code `mass = 12.0` and retain a stale comment saying the constant does not exist (`re-cock-nize/sim/physics/pymunk_backend.py:79-87`, `pybullet_backend.py:183-196`). The Python reader currently parses width/length but not mass (`sim/mechanism.py:197-205`).
3. **Design/source tick wording:** the protected design pseudo-code shows explicit subsystem calls, while the source puts those calls inside each engine's `sense`/`act`. The current architecture document records this as-built ownership; changing the protected design is out of scope.
4. **Request contract drift:** the design task lists a future `WAIT` request, but the current enum has no `WAIT` (`phase-1.1/robot-cx-10-subsystem-layer.md:30-37`; `robot-code/TeamCode/core/src/main/java/boobuzz/core/contract/RequestType.java:3-15`). Do not document `WAIT` as implemented.
5. **R4 review boundary is now explicit:** `review-robot-r8-sim.md` independently reviewed `0b77bee`/`4b8ba23` at `4b8ba23` with no findings and focused tests green (`review-robot-r8-sim.md:3-19`). The later R9 source/report commit `d5bda62` still needs its own cross-review only for the turret fix/report context.
6. **S3 startup characterization:** sim-cx-21 reproduced the acceptance race in a fresh process and added an uncommitted startup-barrier fix/tests; the report remains in progress, so no simulator fix hash is claimed yet (`sim-cx-21-report.md:9-13`).
7. **Android API/cadence proof:** host tests and one assembly do not prove Control Hub scheduling, physical Pinpoint offsets, voltage behavior, or real-opmode shutdown under interruption.

## Earlier findings now fixed in source

The following dispositions are supported by the cumulative R7 review and current
source inspection; they are not a claim that a new review has run:

- R3 request lifecycle fixes (manual takeover cancellation, attached sequence barriers,
  reset-pose routing, switch status forwarding, path validation) are recorded resolved
  in the R5 addendum (`review-sim-cx-15-r4-r5.md:278-417`).
- R4 Android network permission, per-client tap queues, bag drop metadata, semantic
  socket validation, feedback backpressure, and normal-entry cleanup are recorded
  closed in R6 (`review-sim-cx-18-r6.md:19-99`).
- R7 replay portability/header pose and TeleOp startup cleanup are recorded closed
  (`review-sim-cx-20-r7.md:24-34,38-43,63-79`).
- The post-R7 source now has per-client writer watchdogs and joins (`SocketController.java:222-343`, `DebugTap.java:283-405`) and preserves terminal bag failures after dispatcher drain (`RobotLoop.java:214-227`, `BagWriter.java:83-110`). These are **pending independent re-review**, not stale claims.

## Worker reports and review disposition

| worker item | expected artifact | snapshot state | disposition |
|---|---|---|---|
| robot-cx-22 R9 subsystem contract audit | `phases/phase-1.1-a/robot-cx-22-report.md`, `review-sim-cx-21-robot.md` | **Complete:** source `1e555cb` fix and report/audit pushed in `d5bda62`; worker reports 122 core + 10 sim + Android assembly green | Staged in this docs update after robot worker confirmed the stable hash; sim review of R9 remains separate. |
| sim-cx-21 R8 network/determinism review | `phases/phase-1.1-a/review-robot-r8-sim.md`, `review-robot-cx-22-sim.md`, `sim-cx-21-report.md` | R8 review complete at robot `4b8ba23`; fresh-process barrier fix/tests still in progress at sim `518bf9c` | `review-robot-r8-sim.md` is ready to stage; hold the in-progress report and R9 review until sim worker declares a final snapshot. |
| ftc-main-cx coordination | `orchestrator-log.md` | Seed handover committed in `21dae9a`; update after worker snapshots | No phase close/tag/merge. |

## Next small in-scope priorities

1. Receive the final sim-cx-21 snapshot (commit, report, barrier tests, and R9 cross-review); inspect every path before staging.
2. Re-run or obtain independent evidence for `:core:test`, `:sim:test`, and `:TeamCode:assembleDebug` at post-R9 `d5bda62`.
3. Cross-review the `RobotConstants.ROBOT_MASS_KG` parser/backend mismatch and any simulator startup-barrier change.
4. Add an acceptance checklist item for real Control Hub cadence, Pinpoint reset/offset verification, and non-stub mechanism ownership; do not claim these complete from host evidence.
5. Keep the request `WAIT` decision and duplicate `RobotConstants.Motor/Pinpoint` versus `Mechanism` records visible to ftc-main-cx; no protected spec edit is authorized.
