# Teleop gamepad map (robot-code `dev-phase-1.1`)

This is the implementation in `TeleopMap`, `Buttons`, and `TeleopController`,
not a proposed control scheme.  `GamepadState` reports sticks in `[-1,1]`,
triggers in `[0,1]`, and `ly` is negative when pushed up
(`contract/GamepadState.java:9-17`).  Button edges come from the previous and
current frames (`controller/Buttons.java:55-108`).  Teleop request IDs start at
10,000 and increment (`teleop/TeleopMap.java:24-39,143-145`).

| Control | RequestStream field or Request type | Engine consumer | Robot effect |
|---|---|---|---|
| Left stick Y (`ly`) | `RequestStream.vx = deadband(-ly)` | DirectEngine; cplx1 `MotionLogic` | Forward/back drive command; field-oriented transform may rotate it (`teleop/TeleopMap.java:60-76`, `logic/direct/DirectEngine.java:56-60`, `logic/cplx1/MotionLogic.java:25-33`). |
| Left stick X (`lx`) | `RequestStream.vy = deadband(-lx)` | DirectEngine; cplx1 `MotionLogic` | Left/right drive command, with the same transform and deadband as above (`teleop/TeleopMap.java:60-76`). |
| Right stick X (`rx`) | `RequestStream.omega = deadband(-rx)` | DirectEngine; cplx1 `MotionLogic` | Rotation command (`teleop/TeleopMap.java:60-76`). |
| Any non-zero `lx`, `ly`, or `rx` | `RequestStream.manualDrive = true` (raw value, before deadband) | DirectEngine; cplx1 `MotionLogic` | Manual drive takes ownership; any active drive request is cancelled and a simultaneous drive request is rejected (`teleop/TeleopMap.java:73-76`, `logic/direct/DirectEngine.java:56-73`, `logic/cplx1/MotionLogic.java:30-55`). |
| **B rising edge** | No request; toggles `fieldOriented` | No direct engine consumer | Switches field-oriented/robot-oriented stream transform; starts `true` (`teleop/TeleopMap.java:34,49-52,66-72`). |
| **Y rising edge** | No edge request; starts an `AutoSequence` (and stores current heading as offset) | `TeleopController` → `SequenceRunner` → selected engine: `PATH`, then `SHOOT` | Drives 12 in in the current pose's +X direction, then shoots 3; a real stick sample aborts the sequence (`teleop/TeleopMap.java:54-58,91-95,128-140`, `teleop/TeleopController.java:48-66`). |
| **RB rising edge** | `Request.SHOOT`, params `[count=3]` | DirectMap `SHOOT`; cplx1 `ShooterLogic.requestShot` | Spin up and feed three shots (`teleop/TeleopMap.java:78-81`, `logic/direct/DirectMap.java:141-150`, `logic/cplx1/CplxEngine1.java:63-75`). |
| **LB rising edge** | `INTAKE_ON [power=1.0]` or `INTAKE_OFF []` (toggle) | DirectMap; cplx1 `CplxEngine1.handleIntake` | Run intake at full power or stop it; each emits immediate `DONE` (`teleop/TeleopMap.java:83-89`, `logic/direct/DirectMap.java:162-171`, `logic/cplx1/CplxEngine1.java:109-118`). |
| **BACK rising edge** | `RESET_POSE [TELEOP_RESET_POSE_X, Y, H]` | RobotLoop passes it through; DirectMap rejects it as unsupported, cplx1 ignores it | No pose reset is performed: this request is emitted but currently has no engine consumer (`teleop/TeleopMap.java:97-103`, `logic/direct/DirectMap.java:37-48`, `logic/cplx1/CplxEngine1.java:63-73`). |
| **START held ≥ 1.0 s** | `SWITCH_ENGINE [index 0 or 1]` (one request per hold) | `RobotLoop`, before either engine | Cancels the old engine with `CANCEL_ALL`, then selects the target for the next tick. `RobotFactory` orders index 0 = DirectEngine and index 1 = CplxEngine1 (`teleop/TeleopMap.java:105-112`, `controller/Buttons.java:102-108`, `RobotLoop.java:74-90`, `RobotFactory.java:88-97`). |
| A, X, right stick Y (`ry`), LT, RT, or any D-pad direction | No `RequestStream` field or request | None | The fields exist in `GamepadState`, but this map reads none of them; no robot effect (`contract/GamepadState.java:12-17`, `controller/Buttons.java:21-24,114-125`). |

## Gesture details

* **Engine switch:** START must remain held for one HAL-clocked second.  The
  edge helper suppresses repeats while held; releasing START arms the next
  switch.  `TeleopMap` alternates its target index between 0 and 1.  During a
  switch `RobotLoop` sends `RequestBatch.cancelAll()` to the old owner, strips
  `SWITCH_ENGINE`, and only the next tick calls the selected engine
  (`teleop/TeleopMap.java:105-112`, `RobotLoop.java:79-87`).
* **Reset pose:** BACK is a rising-edge gesture only.  It emits the compile-time
  `RobotConstants.TELEOP_RESET_POSE_*` triple, but neither current engine
  changes odometry; treat the behavior as unimplemented until a consumer is
  added (`teleop/TeleopMap.java:97-103`, `logic/direct/DirectMap.java:37-48`,
  `logic/cplx1/CplxEngine1.java:63-73`).

## Source snapshot

The cited files are in robot-code commit `aca0f19` on `dev-phase-1.1`.
