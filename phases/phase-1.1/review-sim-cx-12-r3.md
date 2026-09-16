# sim-cx-12: R3 robot-code cross-review

Reviewed read-only on `robot-code` branch `dev-phase-1.1`, commit range
`2573880..d4226eb` (review pin: `d4226eb`).  I read
`robot-cx-13-r3-naming-logic-requests.md`, the R3 revisions in `design-spec.md`,
and `request-flow.md`, then inspected the complete R3 tree, production sources,
tests, and import rules.  No robot-code files were edited.

## Summary

The requested package tree and naming are present, and the controller dependency
direction is clean.  Motion stream arbitration and the broad turret/motion/shooter
state-machine shape match the diagrams.  The findings below are concentrated in
cancellation ownership, sequence completion, engine handoff, reset handling,
Pedro edge cases, and FTC runtime behavior.

## Findings

### [major] cplx1 drops per-request cancels for shooter work

Location: `TeamCode/core/src/main/java/boobuzz/core/logic/cplx1/CplxEngine1.java:56-75`;
`TeamCode/core/src/main/java/boobuzz/core/logic/cplx1/ShooterLogic.java:108-118`.

`RequestBatch.cancels()` is passed to `MotionLogic`, which handles drive IDs, but
`CplxEngine1` has no path for a non-`CANCEL_ALL` ID to `ShooterLogic`.  A running
`SHOOT` or `SPIN_UP` therefore continues after its caller asks for cancellation;
only the special engine-wide cancel reaches `ShooterLogic.cancelAll`.

Fix: add an owner-level `cancel(id, statuses)` to `ShooterLogic`, route every
non-sentinel cancel through motion/shooter (and any future long-running owner),
stop the mechanism, and emit a terminal `REJECTED`/cancelled status.  Add tests
for canceling both shooter request types.

### [major] manual sequence override leaves non-drive requests running

Location: `TeamCode/core/src/main/java/boobuzz/core/controller/teleop/TeleopController.java:54-66`;
`TeamCode/core/src/main/java/boobuzz/core/controller/auto/SequenceRunner.java:137-142`.

When a manual stream arrives, the controller marks the sequence failed and returns
the manual batch, but `abort` emits no cancel IDs.  Motion is stopped by stream
arbitration, while an attached shooter warmup/shot and an intake command from the
same sequence remain active in either engine.  This violates the intended
driver-wins safety boundary.

Fix: have `SequenceRunner` expose the primary and attached active IDs (or return a
cancel batch from `abort`), merge those IDs into the manual batch, and make every
engine cancel its owners before applying the stream.  Add a teleop test that starts
a sequence, injects stick input, and asserts drive, shooter, and intake are stopped.

### [major] attached sequence requests are not completion barriers

Location: `TeamCode/core/src/main/java/boobuzz/core/controller/auto/SequenceRunner.java:61-75,176-195`.

The runner advances on the primary path/request status and examines attached IDs
only for rejection/failure.  A `SPIN_UP` attached to a path can still be `ACTIVE`
when the path finishes; the next `SHOOT` is then issued and `ShooterLogic` rejects
it as busy.  The current `AutoControllerTest` (`.../AutoControllerTest.java:22-49`)
only supplies active attached statuses and does not exercise this ordering.

Fix: retain terminal status for each attached ID and require all attached work to
be `DONE` (or explicitly cancel/replace it) before advancing to the next step.
Add a test where the path completes before warmup and assert the next shoot is
held until warmup completes.

### [major] RESET_POSE is emitted but has no consumer

Location: `TeamCode/core/src/main/java/boobuzz/core/controller/teleop/TeleopMap.java:97-103`;
`TeamCode/core/src/main/java/boobuzz/core/logic/cplx1/CplxEngine1.java:63-73`;
`TeamCode/core/src/main/java/boobuzz/core/logic/direct/DirectMap.java:37-49`.

BACK creates the specified `RESET_POSE` request.  `RobotLoop` handles only
`SWITCH_ENGINE`; cplx1 falls through without a status, while DirectMap rejects it
as unsupported.  On a real robot the operator therefore receives neither a reset
nor an explanation.

Fix: define one reset owner (RobotLoop/HAL or a dedicated drive-localizer API),
apply the pose to both the software localizer and the real Pinpoint/simulator,
and return `DONE` or `REJECTED` to the controller.  Add tests for both engines and
the HAL implementation.

### [major] switching back to a previously used engine can write stale output

Location: `TeamCode/core/src/main/java/boobuzz/core/RobotLoop.java:52-63`.

The old engine is canceled and the selected engine is installed, but the loop then
immediately writes `engine.action()`.  Engine instances are retained in the list;
when switching A -> B -> A, A's action is its pre-switch motor/servo command, so a
stale command can be written on the handoff tick before A senses/acts again.

Fix: write an explicit all-zero/safe action on every switch tick (or defer the HAL
write until the selected engine has produced a fresh action), and reset any
selected-engine output cache.  Extend `RobotLoopSwitchTest.java:58-83` with an
A -> B -> A test that asserts no pre-switch action is written.

### [major] engine cancel-all does not quiesce the turret

Location: `TeamCode/core/src/main/java/boobuzz/core/RobotLoop.java:55-57`;
`TeamCode/core/src/main/java/boobuzz/core/logic/cplx1/CplxEngine1.java:56-60`;
`TeamCode/core/src/main/java/boobuzz/core/logic/cplx1/ShooterLogic.java:108-114`;
`TeamCode/core/src/main/java/boobuzz/core/subsystem/ITurret.java:6-10`.

The shared-subsystem handoff stops drive, shooter, and intake.  Shooter cancellation
calls `holdForShot(false)`, which only clears the shooter-held flag; it does not call
`ITurret.hold()`.  A cplx1 automatic aim can therefore remain the last turret
command after switching to DirectEngine, which does not update the turret.

Fix: make cancel-all explicitly call the turret's safe `hold()` (and define that
contract for the real implementation) in both handoff paths.  Add a test that starts
automatic aiming, switches engines, and verifies a turret hold/neutral command.

### [major] axis-aligned velocity interpolation can return zero

Location: `TeamCode/core/src/main/java/boobuzz/core/subsystem/pedro/HalDrivetrain.java:94-107`.

The harmonic interpolation divides by both requested components.  For a normal
forward-only request (`forwardVelocity > 0`, `strafeVelocity == 0`, `theta == 0`),
`Math.sin(0) / 0` is `NaN`; the guard then returns zero velocity.  The same issue
occurs for strafe-only requests and can make Pedro stop an otherwise valid axis move.

Fix: skip a term when its trigonometric numerator is effectively zero, handle a
zero component by its limiting value, and reject only genuinely invalid inputs.
Add forward-only, strafe-only, diagonal, and zero-speed unit tests; the existing
`HalDrivetrainTest.java:23-83` does not cover this method.

### [major] FTC LinearOpMode loops never yield

Location: `TeamCode/src/main/java/org/firstinspires/ftc/teamcode/opmode/TeleopMain.java:28-33`;
`TeamCode/src/main/java/org/firstinspires/ftc/teamcode/opmode/AutoMain.java:37-42`.

Both Android entry points run `robot.tick()` and telemetry in a tight
`while (opModeIsActive())` loop with no `idle()`, sleep, or rate limiter.  On the
real FTC controller this can starve the scheduler/watchdog and consume unnecessary
CPU; telemetry transport is not a reliable loop-yield contract.

Fix: call `idle()` (or use a measured 20 ms loop with `sleep`/deadline handling)
after each tick, and add an SDK/instrumentation smoke check for loop cadence and
clean stop behavior.

### [major] SHOOT RPM has inconsistent and unsafe semantics between engines

Location: `TeamCode/core/src/main/java/boobuzz/core/controller/auto/SequenceRunner.java:106-112`;
`TeamCode/core/src/main/java/boobuzz/core/logic/cplx1/CplxEngine1.java:63-68`;
`TeamCode/core/src/main/java/boobuzz/core/logic/direct/DirectMap.java:141-149`.

`SequenceRunner` can emit `Request.shoot(id, count, rpm)`, but cplx1 discards the
RPM and always computes its distance placeholder.  Conversely, a count-only
request from `TeleopMap` reaches DirectMap with the fallback `1.0` RPM.  Selecting
the direct engine on the robot would therefore command an unusably low shooter
speed, while the same request has different physical meaning in cplx1.

Fix: choose one request contract and honor it in both engines: carry a calibrated
RPM (or resolve a shared calibrated default) and pass it to ShooterLogic; reject
missing/invalid RPM rather than silently using `1.0`.  Add cross-engine tests for
count-only and explicit-RPM shots.

### [minor] switch cancellation statuses and invalid switch requests disappear

Location: `TeamCode/core/src/main/java/boobuzz/core/RobotLoop.java:52-60,80-103`.

The old engine's cancellation statuses are left in its private pending queue and
never reach the controller after a switch.  An out-of-range or non-integral switch
is also filtered without a `REJECTED` status.  The actuator handoff is attempted,
but the request lifecycle is not observable to the caller.

Fix: drain/forward the old-engine terminal statuses into the next feedback (or
emit explicit handoff statuses), and reject malformed/out-of-range switch requests
instead of silently dropping them.  Add tests for valid, invalid, and repeated
switch requests.

### [minor] RequestStatus declares an unreachable ACCEPTED state

Location: `TeamCode/core/src/main/java/boobuzz/core/contract/RequestStatus.java:9-23`.

The enum includes `ACCEPTED`, but all R3 producers start at `ACTIVE`, `DONE`, or
`REJECTED`; no code constructs `ACCEPTED`, and the record does not document whether
acceptance is implicit.  This makes the lifecycle promised by the contract
ambiguous for controllers and tests.

Fix: either remove the unused state or emit/document an `ACCEPTED -> ACTIVE ->
DONE/FAILED/REJECTED` lifecycle, including the one-tick feedback delay, and add a
contract test for every terminal path.

### [minor] Path constraints allow invalid values to reach Pedro

Location: `TeamCode/core/src/main/java/boobuzz/core/contract/PathRequest.java:119-124,160-166`;
`TeamCode/core/src/main/java/boobuzz/core/subsystem/pedro/PedroDrive.java:199-207`.

`Constraints` performs no finite/range validation, and `Braking` checks only
finiteness.  Negative power/deceleration or an out-of-range power can therefore be
passed to Foresight modifiers and fail at runtime or produce unsafe motion.

Fix: validate finite positive `maxVelocity`, `0 < maxPower <= 1`, and non-negative,
bounded braking values in the record constructors; add rejection tests before a
request reaches Pedro.

### [minor] R3 safety paths are under-tested

Location: `TeamCode/core/src/test/java/boobuzz/core/RobotLoopSwitchTest.java:58-83`;
`TeamCode/core/src/test/java/boobuzz/core/controller/teleop/TeleopControllerTest.java:41-125`;
`TeamCode/core/src/test/java/boobuzz/core/controller/auto/AutoControllerTest.java:22-49`;
`TeamCode/core/src/test/java/boobuzz/core/subsystem/pedro/HalDrivetrainTest.java:23-83`.

The suite covers the happy-path stream transform, one old-to-new switch, basic
sequence timing, and mecanum mixing, but has no cplx1 engine integration test and
does not exercise shooter/intake cancellation, manual sequence abort, repeated
handoff, reset, attached warmup ordering, or velocity interpolation.

Fix: add focused tests for those paths and one RobotLoop integration test that
asserts statuses and actuator outputs across manual override and engine switches;
keep a real-HAL/SDK smoke test for the opmode loop cadence.

## Areas with no finding

- **Tree and naming:** the `d4226eb` core tree matches the R3 tree (interfaces have
  the `I` prefix, and direct/cplx1, teleop/auto/opmodes, pedro/stub packages are in
  the requested locations).  The R3 README is also present and under 120 lines.
- **RequestStream vs Request:** `RequestStream` is an id-less per-tick level and
  `Request` is edge-triggered/id'd; `MotionLogic` and `DirectEngine` correctly let
  `manualDrive=true` cancel an active drive and reject a simultaneous drive target,
  while an idle stream stops an otherwise idle drive.
- **State-machine shape:** MotionLogic's Stopped/Following/Manual arbitration,
  TurretLogic's automatic aim/scan/hold behavior, and ShooterLogic's
  spin/lock/feed sequence follow `request-flow.md` apart from the findings above.
- **Dependency direction:** `DependencyTest.java:19-29,67-93` passes for the
  inspected tree; no controller source imports a subsystem or logic package.
- **SequenceRunner threading:** it is deliberately single-threaded with RobotLoop
  (the loop documents this at `RobotLoop.java:15-20`); no unsynchronized background
  thread or executor was found.  The runtime concern is loop cadence, covered above.
