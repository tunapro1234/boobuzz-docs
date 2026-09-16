# robot-cx-10 — Subsystem layer, events, passthrough engine (Phase 1.1 / R1)

Repo: `robot-code`. Create branch `dev-phase-1.1` from `dev-phase-1` (HEAD 656f166), push it.
Design source: `docs/phases/phase-1.1/design-spec.md` §2–§6 (binding). Protocol:
`docs/protokol.md` (`events` field). Each step = separate commit + immediate push; report
hashes. All code, comments and identifiers in English. No behaviour change to driving in
this task: the existing sim test-line e2e must still end at (120,72).
`JAVA_HOME=/usr/lib/jvm/java-21-openjdk`. Read a file before editing it. No bloat.

## Steps

**R1.1 — Move DTOs to `contract`.** `RobotState`, `RobotAction` move from `hal` to `contract`.
Add `contract/Event(String name, long tMs, Map<String,Double> data)`; `RobotAction` gains
`List<Event> events` (immutable, builder `event(name, tMs, data)`). Update all imports/tests.

**R1.2 — `subsystem` package.**
- `Subsystem { void observe(RobotState s); void update(RobotAction.Builder out); }`
  (move from `logic`, drop the Intent parameter).
- Interfaces `Drive`, `Shooter`, `Intake` exactly as in spec §4 (each `extends Subsystem`).
  `PathRequest` is whatever `DriveSubsystem` consumes today for GoTo; keep it in `contract`.
- `PedroDrive implements Drive` = today's `logic/cplx_engine_1/DriveSubsystem` moved and
  renamed; `HalDrivetrain`, `HalLocalizer`, `PathRegistry`, `PedroConstants` move with it
  into `subsystem/pedro/`. Manual mixing and follower logic unchanged.
- `StubShooter`, `StubIntake` per spec §4, timings from new `RobotConstants.STUB_SPINUP_S`,
  `STUB_FEED_S`. They emit the listed events with the state timestamp.
- `Subsystems(Drive drive, Shooter shooter, Intake intake)` record with `observe(state)` and
  `RobotAction update(long tMs)` iterating in that order onto one builder.

**R1.3 — Engines take `Subsystems`.** `RobotEngine { WorldSnapshot sense(RobotState); void act(Intent); String name(); }`.
`CplxEngine1(Subsystems)` calls `subsystems.drive` instead of owning a subsystem list.
New `logic/direct_engine/DirectEngine(Subsystems)`: passthrough, maps `Intent.drive`
(Manual → `drive.manual`, Hold → `drive.stop`) and Requests 1:1 (`GOTO` → `drive.follow`,
`SHOOT` → `shooter.spinUp` then `feed` n times, `SPIN_UP`, `INTAKE_ON/OFF`) and reports
`RequestStatus` DONE/REJECTED when the subsystem says so. Add the missing `RequestType`s to
`contract` (`SHOOT(count)`, `SPIN_UP(rpm)`, `INTAKE_ON(power)`, `INTAKE_OFF`, `TURN_TO(headingRad)`,
`WAIT(seconds)`); `TURN_TO`/`WAIT` may be REJECTED by DirectEngine for now but must exist.
`RobotFactory.create(engineName)` with `"direct"` and `"cplx_engine_1"`; `SimMain --engine`
(default `cplx_engine_1`).

**R1.4 — RobotLoop tick order** per spec §3. `SimHal.write` serialises `events` into the
`step` message (`"events": []` when empty); `RealHal` ignores them. `FakeSimServer` in `:sim`
tests accepts the field.

**R1.5 — Dependency test.** A `:core` unit test that scans `core/src/main/java` imports and
fails on any edge not in spec §2 table. Keep it simple (string scan, no library).

**R1.6 — Tests.** Each subsystem tested alone with a fake `RobotState` (PedroDrive keeps its
existing tests, renamed). DirectEngine: manual passthrough, SHOOT request lifecycle
(spinUp → ready → feed × n → DONE) using StubShooter, INTAKE on/off events present in the
built RobotAction. `:core:test` and `:sim:test` green.

**R1.7 — E2E.** Start Python server (`re-cock-nize` `dev-phase-1`, current physics is fine):
`.venv/bin/python -m sim.server --mechanism <RobotConstants.java> --headless --port 5556`,
then `./gradlew :sim:run --args="--port 5556 --path test-line --steps 1000"` with both
`--engine cplx_engine_1` and `--engine direct` (direct uses the path too via GOTO passthrough).
Both end at (120,72) within the existing tolerance. If the Python server rejects the new
`events` key, report it (sim-cx-07 adds it in parallel; do not edit re-cock-nize).

## Report
Commit hashes per step; final package tree; dependency-test output; both e2e final poses;
anything in the spec that did not fit reality (say what and why, do not silently deviate).
