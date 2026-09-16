# robot-cx-13 — R3: naming/tree, Request+RequestStream, DirectMap, logic modules, teleop (Phase 1.1 / R3)

Repo: `robot-code`, branch `dev-phase-1.1` (HEAD 2573880). Design source: `design-spec.md`
§2–§7 plus Revision **2026-09-16 R3** at its bottom (binding; read it first). English only.
Each step = separate commit + immediate push; report hashes. `JAVA_HOME=/usr/lib/jvm/java-21-openjdk`.
Read a file before editing it. No bloat, no new abstractions beyond the ones listed.
Behaviour must not change for autos: after every step the six `--auto` runs and `--path test-line`
(both engines) still end within 0.15 in / 0.3° of today's results (pymunk server from
`re-cock-nize` `dev-phase-1.1` 8af8281: `.venv/bin/python -m sim.server --mechanism <RobotConstants.java> --physics pymunk --headless --port 5556`).

## R3.1 — Tree and names (pure rename/move, git mv, no logic change)

Final tree of `TeamCode/core/src/main/java/boobuzz/core/`:

```
contract/   Request, RequestType, RequestStatus, PathRequest,
            RequestStream, RequestBatch, Feedback,
            RobotState, RobotAction, Event, WorldSnapshot, GamepadState, IGamepadSource
hal/        IHal, Mechanism, RobotConstants
subsystem/  ISubsystem, IDrive, IShooter, IIntake, ITurret, Subsystems
            pedro/  PedroDrive, HalDrivetrain, HalLocalizer, PathRegistry, PedroConstants
            stub/   StubShooter, StubIntake, StubTurret
logic/      IRobotEngine
            direct/ DirectEngine, DirectMap
            cplx1/  CplxEngine1, ShooterLogic, TurretLogic, MotionLogic
controller/ IController, Buttons
            teleop/  TeleopController, TeleopMap
            auto/    AutoController, AutoBuilder, AutoSequence, AutoStep
            opmodes/ AutoRegistry, AutoLocations, BlueDoggy6Piece, RedDoggy6Piece,
                     BlueMissionary9Piece, RedMissionary9Piece,
                     BlueMissionary9PieceLever, RedMissionary9PieceLever
RobotLoop, RobotFactory
```

Rules: every interface is prefixed `I` (file and class name). Shared things live at the
package root, variants in subfolders. `controller/autos` → `controller/opmodes`,
`logic/direct_engine` → `logic/direct`, `logic/cplx_engine_1` → `logic/cplx1`,
`GamepadController` → `teleop/TeleopController`. `contract/Drive` and `contract/Intent`
disappear in R3.2. Update `DependencyTest`, `TeamCode/src` opmodes, `:sim` module, docs
strings (`--engine direct|cplx1`; keep `cplx_engine_1` accepted as alias for one phase).

## R3.2 — Request / RequestStream / RequestBatch

- `Request` stays the edge-triggered, id'd, answered ("TCP") message. Drive targets are
  requests too: `GOTO`, `PATH`, `TURN_TO`. Add `DRIVE_HOLD` is NOT a request.
- `RequestStream` (new record, "UDP"): per-tick level information, no id, no status.
  Fields now: `double vx, vy, omega` (manual drive, robot frame, protokol.md frame rule),
  `boolean manualDrive` (false = no manual input this tick). Reserve nothing else; offsets
  and tuning knobs are added when they exist. Missing stream on a tick = zeros.
- `RequestBatch(RequestStream stream, List<Request> requests, int[] cancels)` replaces
  `Intent`. `IController.decide(Feedback) → RequestBatch`, `IRobotEngine.act(RequestBatch)`.
- Semantics in engines: a manual stream with `manualDrive=true` **cancels** an active drive
  request (GOTO/PATH/TURN_TO get `RequestStatus.rejected(id, "overridden by manual drive")`)
  — driver always wins. Stream with `manualDrive=false` and no drive request → `drive.stop()`.
- Remove `contract/Drive` (Manual/Hold/GoTo/FollowPath): Manual → stream, GoTo/FollowPath →
  requests, Hold → absence. Update AutoController, tests, `RobotFactory.create(..., fixedDrive)`
  (replace with a fixed-stream variant used by `--path test-line`).

## R3.3 — DirectEngine split

- `direct/DirectEngine`: wiring only (request job tracking, status draining, stream → drive,
  cancel handling). Tuna does not edit this file.
- `direct/DirectMap`: one small class Tuna edits: a `switch (request.type())` that maps each
  `RequestType` to subsystem calls, plus `boolean isDone(job)` per type. Everything type-specific
  from today's `startShoot/startSpin/startIntake/...` moves here. Top-of-file comment: "add a
  request type: (1) RequestType enum, (2) one case here, (3) done".

## R3.4 — Turret interface + stub

- `ITurret extends ISubsystem { void aimAt(double fieldX, double fieldY); void scan(); void hold(); boolean onTarget(); double angleRad(); }`.
- `StubTurret`: `onTarget()` true after `RobotConstants.STUB_TURRET_SETTLE_S` (new, 0.3) from
  the last `aimAt`; events `turret.locked` / `turret.scan`. `Subsystems` gains `turret`.
- No controller request drives the turret (fully automatic in logic). `DirectMap` gets a
  test-only `TURRET_AIM(x,y)` request so the mechanism can be exercised on the real robot.

## R3.5 — cplx1 logic modules (skeletons with the real call graph, simple math)

- `MotionLogic`: owns drive decisions: stream vs drive request arbitration (rule in R3.2),
  forwards to `IDrive`. Later home of a planner; not now.
- `TurretLogic`: every tick computes the target (goal position constant in
  `RobotConstants.GOAL_X/GOAL_Y` per alliance, alliance from `RobotConstants.ALLIANCE_BLUE`
  boolean for now) and calls `turret.aimAt` when the robot pose is known, `turret.scan()`
  when not (pose unknown = never in sim; keep the branch). Exposes `boolean locked()`.
  `holdForShot(boolean)` freezes the target while feeding.
- `ShooterLogic`: `requestShot(id, count)` → `spinUp(rpmFor(distance))` where
  `rpmFor` is a linear placeholder `RobotConstants.SHOOTER_RPM_BASE + SHOOTER_RPM_PER_IN * d`;
  hood angle same shape (`hoodFor`), stored but unused by the stub. State machine:
  `IDLE → SPINNING → (shooter.isReady && turretLogic.locked) → FEEDING ×count → DONE`.
  Tells `turretLogic.holdForShot(true)` on entering FEEDING, `false` on DONE. Reports
  `RequestStatus.done(id)`; REJECTED if a shot is already in progress.
- `CplxEngine1.act(batch)`: `MotionLogic` gets the stream + drive requests, `ShooterLogic`
  gets SHOOT/SPIN_UP, intake requests go straight to `IIntake` (no logic needed).
  `sense` stays. All three logic classes unit-tested alone with stubs.

## R3.6 — Controller helpers + teleop

- `controller/Buttons`: pure helper over two `GamepadState`s: `pressed(name)` (rising edge),
  `released(name)`, `held(name)`, `toggle(name)` (flips on rising edge), `heldFor(name, s)`.
  Unit-tested with hand-made `GamepadState` sequences.
- `controller/teleop/TeleopMap`: THE file Tuna edits. Table-like code: for each control →
  what it emits. Phase 1.1 content: left stick → stream drive, right stick x → omega,
  `rb` pressed → `Request.shoot(3)`, `lb` toggle → INTAKE_ON/INTAKE_OFF, `y` pressed →
  fluent chain example (see below), `back` pressed → reset request (`RequestType.RESET_POSE`
  with x,y,h from `RobotConstants.TELEOP_RESET_POSE_*`), `start` held 1 s → engine switch
  (see R3.7). Map from `docs/phases/phase-1.1/gamepad-map-analysis.md` §5 if it exists
  when you get there; otherwise this list.
- `TeleopController implements IController`: reads gamepads, applies `TeleopMap`, and can
  run an `AutoSequence` in the background: a button may start a sequence built with
  `AutoBuilder` (e.g. `y` → `new AutoBuilder().start(pose).goTo(...).withConstantHeading().shoot(3).build()`);
  while it runs, its steps become requests exactly as in `AutoController` (reuse: extract the
  step→request stepping from `AutoController` into a shared `SequenceRunner` in `controller/auto`).
  Manual stick input (`manualDrive=true`) aborts the running sequence.

## R3.7 — Engine switch mid-match (contingency)

- `RobotLoop` gets `setEngine(IRobotEngine)`; `RobotFactory` builds both engines over the
  same `Subsystems`. `RequestType.SWITCH_ENGINE(index)` is handled **in RobotLoop before the
  engine sees the batch** (engines never switch themselves): old engine gets `act` with a
  cancel-all batch, new engine takes over next tick. `SimMain --engine` picks the initial one.

## R3.8 — Docs in repo

- `core/README.md`: the tree above, the four-step "add a subsystem" recipe
  (interface in `subsystem/`, stub in `stub/`, add to `Subsystems`, one case in `DirectMap`),
  and the "add a request type" recipe. Keep under 120 lines.

## Report
Hashes per step; final `find core -name '*.java'` tree; test counts; six-auto table on pymunk
for both engines; anything in the spec that did not fit reality (say what and why; do not
silently deviate).
