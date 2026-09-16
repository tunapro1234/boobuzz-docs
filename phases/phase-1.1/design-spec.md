# Phase 1.1 — Design spec (pre-write)

Status: **v1, approved by Tuna 2026-09-16 before any code was written.**
This file is the design as agreed *before* implementation. It is not edited in place
when reality diverges; instead every deviation is appended to the **Revisions** section
at the bottom with the date, what changed, and why, so we can see where the design was
wrong. Agents work against the task files in this folder, which are derived from this spec.

Branches: `dev-phase-1.1` in `robot-code` and `re-cock-nize` (from `dev-phase-1`).
Docs stay on `stable`. Phase closes with a synchronized date tag on all three repos.

## 1. Goals

1. Four layers inside `:core`: **HAL / Subsystem / Logic / Controller** (+ `contract` DTOs).
   Subsystems are unit-testable alone and a robot can run **without logic** (passthrough
   engine) so mechanism code can be tested on the real robot before the logic exists.
2. Autonomous: an `AutoController` plus a **fluent `AutoBuilder`** with last season's API
   verbatim; last season's six autos ported as data and proven in the sim (chassis only,
   shooter/intake as stubs).
3. Simulator physics rewritten on a rigid-body engine: **pymunk (default) and PyBullet**,
   both behind one backend interface, same socket contract. Angled wall contact must rotate
   the robot and let it slide along the wall (today it just clamps the coordinate).
4. Sim receives **subsystem events** (e.g. shooter feed start/end) alongside motor powers,
   so it never has to decode "when was the ball fired" from motor traces.
5. Phase ends with refreshed `architecture.md`, a LaTeX PDF, CHANGELOG/journal entries and
   a synchronized tag.

Rules carried over: all code and agent tasks in English; compile-time config only
(`RobotConstants.java`, Python reads it); no runtime parsers; `contract/` may change in
this phase but nothing "silly" lands there without ftc-main sign-off; controllers never
touch subsystems.

## 2. Core packages and dependency direction

`TeamCode/core/src/main/java/boobuzz/core/`:

```
contract/    DTOs only: Intent, Request, RequestType, RequestStatus, Feedback, Drive,
             WorldSnapshot, RobotState, RobotAction (+ Event)
hal/         Hal, Mechanism, RobotConstants, GamepadSource, GamepadState
subsystem/   Subsystem (generic), Subsystems (the set), Drive, Shooter, Intake interfaces,
             PedroDrive, StubShooter, StubIntake
logic/       RobotEngine; direct_engine/DirectEngine; cplx_engine_1/CplxEngine1 (+ lib later)
controller/  Controller, GamepadController, AutoController, auto/AutoBuilder, AutoSequence,
             AutoLocations, autos/*
RobotLoop, RobotFactory (root)
```

Allowed imports (anything else fails a dependency unit test):

| package    | may import                       |
|------------|----------------------------------|
| contract   | nothing from core                |
| hal        | contract                         |
| subsystem  | contract, hal (Mechanism/RobotConstants only, not Hal) |
| logic      | contract, subsystem              |
| controller | contract                         |
| root       | everything                       |

`RobotState` and `RobotAction` move from `hal` to `contract` so subsystem tests need no HAL.
`TeamCode/src` keeps only SDK code: `RealHal`, `TeleopMain`, `AutoMain` (one opmode per auto
via a tiny registry).

## 3. Tick order (RobotLoop)

```
state   = hal.read()
subsystems.observe(state)          // each subsystem updates its own private state
snap    = engine.sense(state)      // WorldSnapshot + drained RequestStatus list
intent  = controller.decide(snap, gamepad)
engine.act(intent)                 // calls subsystem interfaces
action  = subsystems.update()      // each subsystem writes its outputs (+ events) to one builder
hal.write(action)
```

## 4. Subsystem layer

- `Subsystem { void observe(RobotState s); void update(RobotAction.Builder out); }` — no
  commands here; commands are the per-subsystem interfaces below.
- `Drive`: `manual(vx, vy, omega)`, `follow(PathRequest)`, `stop()`, `pathDone()`, `pose()`.
  Implementation: today's `DriveSubsystem` renamed `PedroDrive`.
- `Shooter`: `spinUp(rpm)`, `spinDown()`, `isReady()`, `feed()`, `isFeeding()`.
  Implementation: `StubShooter` (ready after `RobotConstants.STUB_SPINUP_S`, feed completes
  after `STUB_FEED_S`; emits events `shooter.feed.start` / `shooter.feed.end`).
- `Intake`: `run(power)`, `stop()`, `hasBall()`. Implementation: `StubIntake` (events
  `intake.on` / `intake.off`).
- `Subsystems` = record `(Drive drive, Shooter shooter, Intake intake)` with `observe(state)`
  and `update()` that iterate in fixed order. Built in `RobotFactory`, passed to the engine.
- Interfaces are deliberately narrow: only what the engines and the auto builder need now.
  They grow when real mechanisms arrive (Phase 2).

## 5. Events (subsystem → sim, later controller → logic → sim)

`RobotAction` gains `List<Event> events` where `Event(String name, double t, Map<String,Double> data)`.
Subsystems append via the builder. `SimHal.write` sends them in the `step` message as
`"events": [{"name": "...", "t": ..., "data": {...}}]`; `RealHal` ignores them (optionally
logs). Python records them into the state log and the viewer; nothing else in Phase 1.1.
Protocol change is recorded in `protokol.md`.

## 6. Logic

- `RobotEngine { WorldSnapshot sense(RobotState); void act(Intent); String name(); }`.
- `direct_engine/DirectEngine`: **passthrough**. Zero intelligence. Maps Intent fields and
  Requests 1:1 onto subsystem calls and reports RequestStatus when the subsystem says done.
  This is the engine Tuna uses while testing mechanisms on the real robot.
- `cplx_engine_1/CplxEngine1`: today's engine, now taking `Subsystems` instead of owning
  `DriveSubsystem`. Future home of aiming/world model.
- Engine selection: `RobotFactory.create(engineName)`; SimMain `--engine direct|cplx_engine_1`
  (default `cplx_engine_1`).

## 7. Controller: AutoController + AutoBuilder

- `AutoController implements Controller`: holds an `AutoSequence`, emits Intents step by step,
  advances on `RequestStatus.DONE` (or elapsed time for waits). Never references subsystems.
- `AutoBuilder` fluent API, method names verbatim from last season
  (`archive/ftc/de-cock/robot-code/.../lvbelc5/auto/AutoBuilder.java`):
  `start(pose)`, `goToPose`, `goTo(x,y,h)`, `lineTo`, `curveTo`, `curveToPose`,
  `withTangentialHeading`, `withTangentialHeadingReverse`, `withConstantHeading`,
  `withLinearHeading`, `withLinearHeadingTo`, `shoot(n)`, `waitSeconds`, `intake(s)`,
  `turnTo`, `withIntake`, `withShooterWarmup`, `withHoldEnd`, `withPathConstraints`,
  `withVelocityConstraint`, `withBraking`, `build()`.
  Every method compiles to Requests (new RequestTypes: `PATH` with heading mode and
  constraints, `TURN_TO`, `SHOOT(n)`, `SPIN_UP`, `INTAKE_ON`, `INTAKE_OFF`, `WAIT`).
  `start` no longer takes a robot or aiming controller.
- `AutoLocations` and the six autos (`BlueDoggy6Piece`, `RedDoggy6Piece`,
  `BlueMissionary9Piece`, `RedMissionary9Piece`, `BlueMissionary9PieceLever`,
  `RedMissionary9PieceLever`) ported as data classes in `controller/autos/`. Poses are last
  season's field; in the sim we only verify sequencing and final pose, not game meaning.
- SimMain `--auto <name>` runs a sequence headless and prints the final pose.

## 8. Simulator physics

- Python `sim/physics/` package: `backend.py` (`PhysicsBackend`: `reset(seed, pose)`,
  `step(dt_ms, powers, events)`, `state(dt)`), `pymunk_backend.py`, `pybullet_backend.py`.
  Common motor model (`MotorSim`, battery, tau, efficiency, roller angles) stays shared;
  a backend only integrates rigid bodies, walls, friction and contacts. Wheel forces are
  applied at wheel positions from `RobotConstants`.
- `sim.server --physics pymunk|pybullet` (default pymunk). PyBullet runs `p.DIRECT`;
  `--gui` opens its native window. Socket contract unchanged except `events`.
- Required tests (both backends): existing test-line e2e ends at (120,72) within tolerance;
  **angled wall hit**: robot driven at 30° into a wall ends with changed heading and slides
  along the wall instead of stopping; determinism (same seed → identical log); step time
  budget ≥ 20x real-time headless.

## 9. Exit criteria

- Five packages, dependency test green, every subsystem has its own tests.
- `--engine direct` and `cplx_engine_1` both drive test-line in sim.
- Six autos finish headless in sim with final pose within tolerance; one confirmed in the viewer.
- pymunk and PyBullet both pass e2e + wall-slide + determinism tests.
- Cross review by Codex agents (robot ↔ sim), no Claude reviews (usage limits).
- `architecture.md` refreshed, LaTeX PDF built, CHANGELOG/journal written, synchronized tag.

## 10. Work order

```
R1 robot: packages + subsystem layer + stubs + events + DirectEngine   ‖  S1 sim: backend iface + pymunk + wall test + events
R2 robot: AutoController + AutoBuilder + autos + --auto               →  S2 sim: PyBullet backend + --gui
cross review (robot-cx reviews sim, sim-cx reviews robot)
D1 docs: architecture refresh + LaTeX + CHANGELOG + tag
```

## Revisions

_(append only; never rewrite the sections above)_

- 2026-09-16 v1 — initial, approved.
