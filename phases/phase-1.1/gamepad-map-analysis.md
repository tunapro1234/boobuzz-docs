# Last-season gamepad map → this-season Request set

This is a read-only inventory of the archived DE-Cock/LC5 code.  The source snapshot is
`/home/shared/projects/archive/ftc/de-cock/robot-code/TeamCode/src/main/java/org/firstinspires/ftc/teamcode/contingency/lvbelc5/`.
Line references below are to that snapshot.  A search for `@TeleOp`, `gamepad1`,
`gamepad2`, and `Gamepad` under `TeamCode/src/main/java` found input handlers only in
`contingency/lvbelc5` (including its disabled RPM test); the autonomous classes do not
read a gamepad.  The source comments contain some Turkish text; this document records
the behavior and the English intent rather than copying those comments.

## 1. Button map

### BlueTeleop and RedTeleop

`BlueTeleop` and `RedTeleop` are the same input map.  The differences are alliance
signs and the hard-reset pose.  Calls shown in this table are the calls made by the
opmode; the resulting mechanism state is described in the referenced controller.

| Gamepad | Control | Edge type | Observed action | Robot/controller calls (file:line) |
|---|---|---|---|---|
| GP1 | Left stick Y/X + right-stick X | Hold / continuous | Tele-operated mecanum drive. Blue passes the three values as read (with `-right_stick_x`); Red negates left-stick Y/X as well as right-stick X. The final boolean is `false` in both normal branches. | `BlueTeleop.java:150-158`; `RedTeleop.java:150-158` → `Follower.setTeleOpDrive(...)` |
| GP1 | Right trigger (`rt > 0.5`) | Hold / continuous | With a valid aim solution, `AUTO_SHOOT` while in the zone and `WARMUP` outside it. In `AUTO_SHOOT`, intake runs and the feeder requests a pulse only after shooter velocity is ready. | `BlueTeleop.java:160-161`, `RedTeleop.java:160-161`; `ShootingController.java:111-114,321-334` |
| GP1 | Right bumper | Hold / continuous | The header calls this “burst”, but the `BURST` branch is hard-disabled (`false &&`). It therefore falls through to `AUTO_SHOOT` and uses pulse-and-delay, not a continuous feeder. | `ShootingController.java:103-110,307-319` |
| GP1 | Left bumper | Hold / continuous | Intake and feeder reverse at full power to clear a jam; shooter is deliberately left running for quick recovery. | `ShootingController.java:99-101,286-290` |
| GP1 | Y (without START) | Hold / continuous | Shooter-jam-clear state: shooter and feeder alternate `+1/-1` every 500 ms while intake runs forward. This control is not listed in the teleop header. | `ShootingController.java:40,101-103,292-305` |
| GP1 | Left trigger (`lt > 0.1`) | Hold / continuous | In `IDLE`, runs the intake at its default power; release stops it. While a shooting state owns the controller, the state machine owns intake output instead. | `ShootingController.java:457-463`; `IntakePowerSubsystem.java:28-40` |
| GP1 | A | Hold / level (no live action) | The advertised manual feeder override is commented out. `executeIdle` clears feeder requests every tick, regardless of A. | `ShootingController.java:165-168,465-472` |
| GP1 | D-pad left/right | Press edge | Normal mode adjusts the accumulated manual turret offset: left adds the configured step, right subtracts it, clamped to ±30°. Recovery mode instead changes the fixed turret angle by ±2°. | Call sites `BlueTeleop.java:123-126` / `RedTeleop.java:123-126`; normal `TelemetryManager.java:450-480`; recovery `RecoveryController.java:107-116,132-138` |
| GP1 | D-pad up/down | Press edge | Normal mode adjusts manual hood offset by ±1°, clamped to ±10°. Recovery mode changes the fixed hood angle by ±1°, then clamps to hardware limits. | Call sites `BlueTeleop.java:123-126` / `RedTeleop.java:123-126`; normal `TelemetryManager.java:487-501`; recovery `RecoveryController.java:118-138` |
| GP1 | B | Press edge to start; release edge to cancel | Starts a Bezier line from the current pose to the alliance `PARK` pose, linearly interpolating heading and holding the endpoint. Releasing B starts teleop drive and cancels the park path. `autoDriveActive` prevents normal stick drive during the hold. | Blue `BlueTeleop.java:135-158`; Red `RedTeleop.java:135-158` |
| GP1 | BACK | 2-second hold toggle (release re-arms) | Enters/leaves Recovery mode. Recovery uses robot-oriented drive, fixed 4,000 RPM / 45° hood / 0° turret defaults, manual D-pad offsets, and shooting allowed outside the normal zone gate. | `RecoveryController.java:27-37,68-88,164-177`; branch `BlueTeleop.java:81-115` / `RedTeleop.java:81-115` |
| GP1 | START + Y | Level hold for 2 s; one trigger per hold | Hard-resets Kalman and odometry. Blue target is `(144 - halfWidth, halfLength, 90°)`; Red is `(halfWidth, halfLength, 90°)`. Holding after the trigger does not repeat it. | Blue `BlueTeleop.java:178-217`; Red `RedTeleop.java:178-217`; `LocalizerController.hardReset` at `LocalizerController.java:270-277` |
| GP2 | D-pad up/down | Press edge | Navigates the telemetry menu (main menu, sections, or tuning list). | `BlueTeleop.java:128-133` / `RedTeleop.java:128-133`; `TelemetryManager.java:106-122` |
| GP2 | D-pad left/right | Press edge | In `TUNING`, changes the selected value within its min/max. In `SECTIONS`, toggles a section; for calibration model it cycles MT2 → TAG3D → PIXEL (or backwards). | `TelemetryManager.java:137-174`; parameter ranges/defaults `TelemetryManager.java:64-79` |
| GP2 | A | Press edge | Enters the selected main-menu child; toggles the selected section; or advances calibration model. | `TelemetryManager.java:124-156` |
| GP2 | B | Press edge | Returns from `SECTIONS`/`TUNING` to the main menu. | `TelemetryManager.java:152-156,169-174` |
| GP2 | Y | Press edge | Resets all tuning values to defaults. Applying the manager updates aiming, zone mode, calibration model, and RPM compensation each normal tick. | `TelemetryManager.java:177-182,205-240` |

The `false`/`true` argument to `setTeleOpDrive` is part of the observed Pedro call
convention: normal Blue/Red calls use `false`, while the recovery branch explicitly
describes `true` as robot-oriented (`BlueTeleop.java:89-91`).  The debug opmode's
comment calls its normal drive “field-oriented” while also passing `false`; the Pedro
dependency is not in this archive, so the boolean's library-level name should be
verified before carrying the convention into the new contract.

### RonaldoPowerDebug

This is a separate `@TeleOp`, not an in-match engine selector.  It uses only GP1.

| Gamepad | Control | Edge type | Observed action | Calls (file:line) |
|---|---|---|---|---|
| GP1 | Left stick Y/X + right-stick X | Hold / continuous | Debug teleop drive (commented as field-oriented; call passes `false`). | `RonaldoPowerDebug.java:149-155` |
| GP1 | RT / RB / LB / LT / A / Y | Hold / level | Delegated to the same `ShootingController`; `inZone` is always `true`, so RT is never warmup. RB is still `AUTO_SHOOT` because BURST is disabled; LB is jam clear; LT is manual intake in idle; A manual feeder remains disabled; Y is shooter-jam-clear. | `RonaldoPowerDebug.java:163-167`; `ShootingController.java:86-169,286-372,457-472` |
| GP1 | D-pad up/down/left/right | Press edge | Selects one of five live Ronaldo parameters and increments/decrements it, with per-parameter limits and steps. | `RonaldoPowerDebug.java:42-79,182-205` |
| GP1 | Y (menu) | Press edge | Resets the five debug parameters. The same held Y is then seen by `ShootingController`, so it also selects shooter-jam-clear until release. | `RonaldoPowerDebug.java:207-213`; `ShootingController.java:89-103` |
| GP1 | START | Press edge | Reads a valid Limelight pose (if tags are present), converts FTC coordinates to Pedro coordinates, and sets the follower pose; otherwise logs “reset skipped”. | `RonaldoPowerDebug.java:235-257,271-285` |
| GP1 | BACK | Press edge | Sets a fixed Pedro pose `(24, 96, 90°)`. | `RonaldoPowerDebug.java:260-266` |

The live debug parameters are shooter RPM weight (0.0–1.0, step 0.05), hood weight
(0.0–1.0, step 0.05), shooter RPM offset (±500 RPM, step 50), hood offset (±10°,
step 0.5°), and turret offset (±15°, step 1°) (`RonaldoPowerDebug.java:42-69`).

### PoseResetBlue and PoseResetRed

These utility `@TeleOp`s have no post-start gamepad map.  During initialization they
write the corresponding `AutoLocations.*.START_MISSIONARY` pose to `PoseStorage`,
display it, and wait for START/STOP; no control loop runs after `waitForStart`.

| OpMode | Control | Edge type | Action | Calls (file:line) |
|---|---|---|---|---|
| `PoseResetBlue` | none after init | none | Persist Blue Missionary start pose. | `PoseResetBlue.java:16-35` |
| `PoseResetRed` | none after init | none | Persist Red Missionary start pose. | `PoseResetRed.java:16-35` |

### ShooterRpmCompensationTest (disabled)

`ShooterRpmCompensationTest` is annotated `@Disabled`, but is the only additional
teleop/gamepad handler found by the source search.

| Gamepad | Control | Edge/debounce | Observed action | Calls (file:line) |
|---|---|---|---|---|
| GP1 | D-pad up/down | Level check; `sleep(150)` in target setter | Changes target RPM by ±100, clamped to 1,500–6,000 RPM. | `ShooterRpmCompensationTest.java:93-127` |
| GP1 | A | Level check plus `sleep(200)` | Toggles compensation. This is time-sleep debounce, not a stored rising edge. | `ShooterRpmCompensationTest.java:101-107` |
| GP1 | B | Level check plus `sleep(200)` | Resets the compensator. | `ShooterRpmCompensationTest.java:109-113` |
| GP1 | X | Level check plus `sleep(200)` | Toggles shooter enable; the loop sends the compensated (or base) target and calls `shooter.periodic()`. | `ShooterRpmCompensationTest.java:63-90,116-121` |

## 2. Shared input mechanics

There is no shared input helper in the archive.  Each opmode/controller keeps its own
previous-value fields:

- `BlueTeleop`/`RedTeleop` use `prevB` for the park start/release edges
  (`BlueTeleop.java:48-50,135-148`) and a level timer plus `hardResetTriggered` for
  START+Y (`BlueTeleop.java:43-46,184-217`).
- `RecoveryController.checkToggle` starts an `ElapsedTime` on the first BACK sample,
  toggles at two seconds, and requires release before re-arming
  (`RecoveryController.java:42-54,68-88`).  Its four D-pad directions have separate
  previous booleans and fire once per press (`RecoveryController.java:107-130`).
- `ShootingController` stores `prevY`, although the single-shot branch is disabled;
  the active Y behavior is level-triggered shooter-jam-clear (`ShootingController.java:55-57,86-103`).
- `TelemetryManager` has seven previous booleans and uses `current && !previous` for
  navigation, toggles, tuning, and global reset (`TelemetryManager.java:95-103,106-192`).
  GP1 manual offsets have a separate four-boolean edge state (`TelemetryManager.java:434-501`).
- `RonaldoPowerDebug` repeats the same per-button previous booleans for menu, START,
  and BACK (`RonaldoPowerDebug.java:37-38,82-89,182-213,235-267`).
- The disabled RPM test uses blocking sleeps as debounce (`ShooterRpmCompensationTest.java:101-127`);
  it does not use edge state.  No other debounce interval is present.

The common replacement should be a controller-only input package, for example:

1. An immutable frame (`GamepadState`) plus a small `ButtonEdge` state that exposes
   `down`, `pressed`, and `released` from one previous sample.
2. A `HoldTrigger` that accepts a HAL-clock timestamp, a duration, and a one-shot
   `rearmOnRelease` flag; this preserves both START+Y and Recovery BACK semantics
   without `System.currentTimeMillis()` in a controller.
3. A direction-repeat policy only if tuning wants auto-repeat; the archive currently
   uses one event per press.

The helper must emit input events/value changes only.  It must not reference a drive,
turret, shooter, or HAL implementation; the controller turns those events into an
`Intent`.  Zone rumble/LED transitions (`ZoneController.java:57-75`) are output
feedback, not gamepad edge detection and should remain outside this helper.

## 3. Engine and mode switching

### What existed

- **Recovery/contingency:** this is a branch inside the same `BlueTeleop` or
  `RedTeleop` loop, not a second `RobotEngine`.  BACK held for two seconds toggles
  `RecoveryController.recoveryActive` (`RecoveryController.java:68-88`).  On entry,
  the branch switches drive orientation, fixes turret/hood/RPM defaults, and still
  calls the normal `ShootingController`; on exit, the normal branch resumes on the
  next tick (`BlueTeleop.java:81-161`).
- State that survives the toggle is the recovery active flag, BACK timer/re-arm
  state, current manual turret/hood angles, and D-pad previous values
  (`RecoveryController.java:42-54`).  Shooter state, feeder pulse state, follower
  pose/path, and normal tuning objects are not copied or reset by the toggle.  The
  normal branch simply starts issuing its own outputs again.
- **Manual mode:** normal teleop sticks are direct follower commands.  Recovery's
  “manual” means robot-oriented sticks plus direct fixed-angle turret/hood controls;
  it is not a replaceable engine (`RecoveryController.java:147-177`).
- **Park micro-mode:** B starts a follower path and release cancels it through the
  `autoDriveActive` flag (`BlueTeleop.java:135-158`).  This carries the current path
  in Pedro and the flag/previous B in the opmode; it does not swap a logic engine.
- **Debug mode:** `RonaldoPowerDebug` is selected as a separate FTC OpMode.  START
  and BACK are pose resets, not engine selection (`RonaldoPowerDebug.java:235-267`).
- **Autonomous:** `AutoBuilder` constructs a command sequence; each command owns
  its own execution cursor and calls `Robot` directly in the archived code
  (`AutoBuilder.java:57-69,734-810`).  It is not switchable from the teleop loop.

The current-season core makes the same distinction explicit: `RobotFactory` selects
`"direct"` or `"cplx_engine_1"` only while constructing a `RobotLoop`
(`robot-code/TeamCode/core/src/main/java/boobuzz/core/RobotFactory.java:36-60`), and
`DirectEngine` keeps active motion/shoot/spin jobs internally
(`robot-code/TeamCode/core/src/main/java/boobuzz/core/logic/direct_engine/DirectEngine.java:26-32`).
There is no mid-match engine-switch operation yet.  To satisfy Tuna's mid-match
requirement, the new design needs an explicit mode/engine request, a safe handoff
point, and a defined state transfer (pose, active drive job, shooter/intake outputs,
and request statuses); otherwise a switch can strand a path or leave a mechanism
running with no owner.

## 4. Subsystem-side tricks worth keeping

These are intentionally motor/mechanism-level observations.  The new controller and
logic layers should request intent; they should not duplicate these loops.

| Mechanism trick | One-line behavior and source |
|---|---|
| Shooter PIDF | `ShooterPidfPowerSubsystem.periodic()` computes PID + feedforward in power units, clamps to ±1, optionally slew-limits power, and declares stable only after the configured tolerance duration (`ShooterPidfPowerSubsystem.java:169-207,209-239,242-309`). |
| Shooter warmup/shot gate | RT outside the zone spins the shooter only; once `isAtTargetVelocity()` is true, AUTO_SHOOT requests a feeder pulse with a 100 ms delay (`ShootingController.java:321-357`). |
| Finishing pulse | Releasing RT does not cut a feeder pulse: the shooter target is maintained while the current pulse naturally finishes, then intake/shooter are stopped (`ShootingController.java:359-372`). |
| RPM timeout compensation | After a configurable timeout, a significant RPM error produces a signed target offset; it will not request an upward correction while already at full power, and it rumbles once when applied (`ShootingController.java:382-433,519-545`). |
| Intake baseline | Intake is a fixed-power motor with BRAKE zero-power behavior; `runDefault()` uses the configured default power and there is deliberately no velocity loop (`IntakePowerSubsystem.java:15-40`). |
| Intake/feeder jam clear | LB sends `-1.0` to intake and feeder but leaves the shooter spinning for quick resume (`ShootingController.java:286-290`). |
| Shooter jam clear | Y toggles shooter direction every 500 ms, mirrors that sign to the feeder, and runs intake forward (`ShootingController.java:40,292-305`). |
| Feeder pulse queue | Feeder owns pulse duration, optional inter-pulse delay, request clearing, and stop/reset state; callers do not need a command scheduler (`FeederPowerSubsystem.java:42-136,144-152`). |
| Turret sensor fusion | The turret predicts from encoder ticks, fuses a filtered analog angle during calibration, fades analog trust, applies PID plus static-friction `kS`, and locks output while calibrating (`TurretPidPazarSubsystem.java:86-116,146-212,313-330`). |
| Turret aim ownership | Aiming continuously computes target geometry and calls `turret.setTargetAngleDegrees`; a shooter-jam-clear state only overrides hood to 25° (`AimingController.java:73-140`). |
| Recovery fallback | Recovery uses fixed `4000` RPM, `45°` hood, and `0°` turret, with hardware-limit clamps after D-pad adjustments (`RecoveryController.java:27-37,107-177`). |
| Ronaldo solution | The distance solver interpolates min/max RPM and hood functions, applies runtime weights/offsets, and clamps RPM (1,500–6,000) and hood to physical limits (`RonaldoShEngine.java:158-249`). |
| Hood actuation | Hood angles are clamped and mapped to two inverse servo positions; `moveToStow()` is a safe stop action (`HoodSubsystem.java:27-68`). |
| Auto-side warmup | A path modifier starts intake and/or shooter warmup at path initialization, keeps them alive while moving, then stops intake at path completion while intentionally leaving the shooter warm (`AutoBuilder.java:541-575`). |

## 5. Proposed Request set for this season

The current core record is `Request(int id, RequestType type, double[] params,
PathRequest path)` (`robot-code/TeamCode/core/src/main/java/boobuzz/core/contract/Request.java:5-29`),
and the checked-in enum currently contains `SHOOT`, `INTAKE`, `GOTO`, `PATH`,
`SPIN_UP`, `INTAKE_ON`, `INTAKE_OFF`, and `TURN_TO`
(`robot-code/TeamCode/core/src/main/java/boobuzz/core/contract/RequestType.java:3-12`).
Rows marked **new** are the smallest additions suggested by the archive; they are not
claims that those enum members already exist.  `WAIT` is deliberately controller-local
because it is a timer, not a mechanism request.

| Group | RequestType | Parameters (units/meaning) | Issuer | Expected completion | Last-season action replaced |
|---|---|---|---|---|---|
| Drive | `PATH` (current) | `PathRequest` payload: ordered field-inch line/Bezier segments, heading mode/radians, constraints, hold-end, optional velocity/braking. | Auto, RL, or gamepad controller (GP1 B park) | When follower reports done; `RequestStatus` is terminal then. | AutoBuilder `goToPose`, `lineTo`, `curveTo`, and GP1 B park (`AutoBuilder.java:79-230`; teleop `:135-148`). |
| Drive | `GOTO` (current compatibility) | `params = [xIn, yIn, headingRad]`; prefer compiling new calls to `PATH`. | Auto/RL; gamepad only for a simple park target. | When follower path is done. | Simple `goTo`/park target; direct engine retains this legacy branch (`DirectEngine.java:165-177`). |
| Drive | `TURN_TO` (current) | `params = [headingRad]`. | Auto, RL, or gamepad. | When in-place path is done. | AutoBuilder `turnTo` (`AutoBuilder.java:258-267`). |
| Drive | *(no RequestType)* | `Intent.drive = Drive.Manual(vx,vy,omega)` continuously; RL may use `Drive.Velocity`; idle uses `Drive.Hold`. | Gamepad or RL controller. | Continuous until the next intent. | Normal and recovery stick driving; keep it as a downward drive intent, not an edge request. |
| Shooting | `SHOOT` (current) | `params = [count]` or `[count, rpm]`; count is balls, RPM is wheel target. | Gamepad, auto, or RL. | When all feeder pulses complete; one logical job per request. | RT auto-shot, RB (which currently falls into auto-shot), Y single-shot when that feature is enabled, and AutoBuilder `.shoot(n)` (`ShootingController.java:321-347`; `AutoBuilder.java:233-239`). |
| Shooting | `SPIN_UP` (current) | `params = [rpm]` (wheel RPM). | Gamepad, auto, or RL. | When shooter reports ready; no feeder side effect. | RT warmup outside the zone and `withShooterWarmup`/`warmupAuto` (`ShootingController.java:350-357`; `AutoBuilder.java:284-295,546-550`). |
| Shooting | **new `CLEAR_JAM`** | `params = [scope, direction]` or a named scope in the future contract (`intake_feeder` vs `shooter`); duration/re-arm must be explicit. | Gamepad or RL safety policy. | Continuous while active, or when the bounded reversal finishes. | LB intake/feeder reversal and Y shooter oscillation (`ShootingController.java:286-305`). This is a candidate, not a current enum member. |
| Intake | `INTAKE_ON` (current) | `params = [power]`, signed motor power. | Gamepad, auto, or RL. | Continuous until `INTAKE_OFF`; current `DirectEngine` reports it DONE immediately, so lifecycle semantics need confirmation (`DirectEngine.java:179-188`). | LT manual intake and AutoBuilder intake/with-intake. |
| Intake | `INTAKE_OFF` (current) | No parameters. | Gamepad, auto, or RL. | Instant stop. | LT release and the end of timed auto intake (`AutoController.java:50-72`; `DirectEngine.java:105-109`). |
| Intake | `INTAKE` (current compatibility) | Optional signed power; zero means stop in the direct engine. Prefer the explicit ON/OFF pair. | Auto/RL compatibility callers. | Immediate command acceptance. | Older single-call intake code (`DirectEngine.java:102-106,179-188`). |
| Aim override | **new `SET_AIM_OFFSET`** | `[turretDeg, hoodDeg]` absolute offsets (or define a separate delta request); clamp in the controller/mechanism contract. | Gamepad or RL; auto only if a routine intentionally compensates. | Instant after accepted. | GP1 D-pad manual turret/hood offsets and Ronaldo turret/hood offsets (`TelemetryManager.java:450-515`; `RonaldoPowerDebug.java:140-147`). |
| Settings | **new `SET_SHOT_TUNING`** | `[rpmWeight, hoodWeight, rpmOffset, hoodOffset, timeoutSec]`; units are unitless, degrees/RPM/seconds as named. | Gamepad tuning or RL calibration tool. | Instant after validation. | GP2 tuning menu and Ronaldo live parameter menu (`TelemetryManager.java:64-79,159-182`; `RonaldoPowerDebug.java:42-79`). |
| Settings | **new `SET_ZONE_MODE`** | `[mode]`, enum value `0=RECTANGLE`, `1=CIRCLE` (document the numeric mapping before freezing). | Gamepad or calibration tool. | Instant. | GP2 `Zone Mode` section; zone geometry itself remains logic-owned (`TelemetryManager.java:218-223`; `ZoneController.java:41-75`). |
| Settings | **new `SET_CALIBRATION_MODEL`** | `[model]`, enum value `0=MT2`, `1=TAG3D`, `2=PIXEL`. | Gamepad or calibration tool. | Instant after model validation. | GP2 calibration-model cycle (`TelemetryManager.java:137-145,225-234`). |
| Settings | **new `SET_RPM_COMPENSATION`** | `[enabled]` (`0/1`) plus optional timeout in seconds, or use the tuning request. | Gamepad or RL. | Instant. | GP2 RPM-compensation toggle/timeout (`TelemetryManager.java:236-240`; controller behavior `ShootingController.java:382-455`). |
| Reset | **new `RESET_POSE`** | `[xIn, yIn, headingRad]` plus an optional source code (`hard`, `vision`, `fixed`) once source precedence is agreed. | Gamepad, auto, or RL. | Instant when accepted; status should say rejected if pose is unavailable/unsafe. | START+Y hard reset, debug START vision reset, debug BACK fixed reset, and the two pose-reset utility OpModes (`BlueTeleop.java:184-217`; `RonaldoPowerDebug.java:235-266`; `PoseResetBlue.java:19-35`). |
| Mode | **new `MODE_SWITCH`** | `[mode]`, e.g. `NORMAL`/`RECOVERY`; include whether the request is a two-second hold already validated by the controller. | Gamepad or RL safety policy. | Instant only at a safe tick boundary; otherwise `ACTIVE` until handoff. | Recovery BACK hold (`RecoveryController.java:68-88`). |
| Engine | **new `ENGINE_SWITCH`** | `[engineId]` or a typed engine name; a numeric-only `double[]` is not self-describing, so a string/enum payload may be preferable. | Gamepad, auto supervisor, or RL. | When old jobs are quiesced and new engine has accepted transferred state. | No true last-season equivalent; Ronaldo debug and recovery were separate branches/OpModes, not swaps. |
| Sequence | `WAIT` (controller-local, not a RequestType) | `seconds >= 0`. | Auto controller only. | When HAL clock reaches the deadline. | AutoBuilder `.waitSeconds` (`AutoBuilder.java:241-247`; current `AutoController.java:42-48,129-135`). |

The following remain automatic logic/mechanism behavior and should **not** become
per-tick requests: turret target tracking from robot pose and goal geometry,
hood/RPM solution calculation and physical clamps, zone classification plus LED/rumble,
shooter readiness gating, feeder pulse timing, RPM timeout compensation, and the
normal cleanup when a shot/path completes.  In particular, “turret always tracks the
goal” is an invariant of the aiming/logic layer; a driver request should only change
an explicit offset or mode.  Jam clear is listed as a candidate because last season
made it a deliberate driver action; if the new subsystem detects jams itself, remove
`CLEAR_JAM` and keep the reversal entirely below the request seam.

## 6. Open questions for Tuna

1. Should `CLEAR_JAM` be a public request, or should the shooter/intake subsystem
   detect and reverse automatically with no upper-layer command?
2. For `MODE_SWITCH` and `ENGINE_SWITCH`, which state is transferred (pose, active
   path/request IDs, shooter target, feeder pulse, intake power), and what is the safe
   handoff boundary?
3. Should `SET_AIM_OFFSET` carry absolute offsets or deltas, and are manual offsets
   allowed during autonomous/RL control?
4. Which pose-reset source wins when vision, Pinpoint, and a fixed pose are all
   available, and should a reset also invalidate pending request statuses?
5. Should compatibility `GOTO`/`INTAKE` remain in the public enum after all callers
   migrate to `PATH` and `INTAKE_ON/OFF`?
