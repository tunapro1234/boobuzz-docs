# ftc-main review of the phase-1.1-a spec pack — 2026-09-17

Author: ftc-main (Claude), three independent Opus reviewers checked the specs against
`robot-code` @ d5bda62, `re-cock-nize` @ 5dd6daa and the archive. Tuna read the summary
and made the decisions in section 1. Section 2 is the orchestrator-level view, sections
3–5 are the full reviewer reports (verbatim, ranked by severity, with file:line evidence).

Status: the pack is NOT dispatchable as written. Revise per sections 1–2, then fix the
blockers/majors in 3–5, then bring it back to Tuna.

## 1. Tuna's binding decisions (today)

1. **Hardware topology is ONE turret, ONE shooter (single flywheel), ONE intake, ONE hood
   servo.** "We are not making the robot complex right now." Every dual-flywheel /
   paired-or-mirrored hood / dual-CR-servo sentence (README decision 2, roadmap-v1 :146
   :149 :502, 10-research :24, B05/B06/B07 titles and bodies) is wrong and must be
   rewritten. The archive is a *behaviour and calibration* reference, not a topology source.
2. **Detail near, sketch far.** From now on, executable-level detail goes into A and B
   (file paths, constants, test class names, seeds, thresholds); C medium; E–H stay as
   roadmap-level bullets. Detail already written for far chapters is NOT to be deleted,
   but do not spend more effort there until A/B are done.
3. **Process overhead must drop.** No per-task tag / manifest / review.md / acceptance.json.
   Tags and manifests only at engine checkpoints (A05 baseline, B09 cplx1, then per engine).
   Evidence per chapter, not per task. Cross-review only on tasks that touch both repos
   at a seam. Codex tends to over-engineer process; keep it lean.
4. **Engines compose, they are not copies.** cplxN = cplx(N-1) + one pluggable module.
   Write the composition rule once in 00-common and name the shared classes; a worker must
   never end up with four parallel engine implementations.
5. **Acceptance = a few end-to-end scenarios**, not test counts. Per engine: one gamepad or
   auto scenario on Pymunk ("drive here, shoot N pollen, expect M in target"). Unit tests
   stay, but the gate is the e2e demo. Tuna explicitly prefers few e2e tests.
6. **Vision splits into two engines.**
   - Vision-A (first): AprilTag + simple object detection from the Limelight; aim/approach
     with a plain PID on the on-screen offset/size. No world model, no tracking.
   - Vision-B (later): 3D map from detections, ball distance estimation, ball tracking,
     sector scanning, target-load beliefs. This is where D03/D04 content moves.
7. **RealHal keeps the archive's motor/encoder/servo names** (`shooterRight`, `shooterLeft`,
   `turret_servo`, `hood_left`, `intake_dist`, etc.). Tuna wants to run the new code and
   engines directly on last season's physical robot without a rewire/reconfig. Add a
   `RobotConstants` device-name block with provenance and let `sim/mechanism.py` parse it.

## 2. Orchestrator-level view (ftc-main)

- The engineering judgement in the pack is good: honest uncertainty, one owner per
  actuator, terminal request results, no fake sensor health. Keep that prose.
- The systemic gaps are (a) the wrong hardware topology, (b) contract-level contradictions
  that no task owns (see 3.F6–F9, 4.B1–B3, 5.B1–B2), (c) no task names a single test
  file or a concrete class path, (d) chapter ordering: geometry constants land in F but
  are needed by B02/C01; G01 and H04 are cheap and decision-relevant yet gated behind F.
- Recommended next action for ftc-main-cx: produce spec pack v2 covering README,
  00-common, 01, 02, 03 (single hardware, composition rule, lean process, e2e gates,
  archive device names, explicit protocol/ADR sub-steps), plus a one-page
  `hardware-profile-v0.md` that every spec references. Leave 04–10 as is with a header
  note "superseded in parts by review 2026-09-17, to be revised after B09". Then show v2
  to Tuna. Do not dispatch anything before that.

## 3. Reviewer report — README, 00-common, 01-baseline (A01–A05), 02-intake-feeder (B01–B04), 03-mechanisms-cplx1 (B05–B09)

### BLOCKERS — single-turret / single-shooter / single-intake violations

**F1. `03-mechanisms-cplx1.md` § B05 — "dual flywheel" is the task's premise.**
Title is "dual flywheel feedback and readiness"; the body preserves "follower scale", and the sim half says "S models each flywheel's inertia". This is the archived two-motor shooter (`HardwareConstants.java:147-148` `rightMotorName="shooterRight"`, `leftMotorName="shooterLeft"`, `followerScale=1.0`). Tuna's robot has ONE flywheel.
Fix: retitle "B05 — single flywheel feedback and readiness". Delete follower scale / second-motor polarity; one DC output, one velocity source, one plant. Keep the PIDF+FF port (kS/kV/kP/kI/kD from `HardwareConstants.java:180-186`) but mark them as re-tune candidates for a single wheel.

**F2. `03-mechanisms-cplx1.md` § B06 — "mirrored hood with honest feedback" specifies two position servos.**
"angle-to-two-servo mapping", "mirror relation", "S models bounded travel and mirrored linkage". Archive is `hood_left`/`hood_right` (`HardwareConstants.java:669-670`, `HoodSubsystem.java:16-57`).
Fix: single hood servo: angle → one normalized position with trim, inversion flag, range, mechanical clamp. Keep the settling-estimate design. Note: even the archive is not "mirrored" — `rightInverse=false` (`HardwareConstants.java:684`) means the LEFT servo is the inverted one (`HoodSubsystem.java:41-47`).

**F3. `03-mechanisms-cplx1.md` § B07 — "dual-CR-servo angular controller".**
"R replaces stub with dual-CR-servo angular controller"; "S models … two servo contributions"; "STOP immediately zeros both CR outputs". Archive: `turret_servo` + `turret_servo2`, both `CRServo`, both driven with the same power (`TurretPidPazarSubsystem.java:28-29,56-62,308-310`).
Fix: "single CR-servo turret". One CR output, one encoder input, one analog startup input. Geometry inputs verified: ±90° and 8192 ticks/rev with `turretGearTeeth=0.715` match `HardwareConstants.java:292-298`.

**F4. `README.md` "Decisions proposed for discussion" item 2 is the root cause.**
"Use the archived dual-flywheel, paired-hood, dual-CR-servo limited turret as a provisional hardware profile." Same wording in `roadmap-v1.md:146,149,502`. B05–B07 inherit it.
Fix: rewrite item 2 to state the new topology as binding (1 intake motor, 1 feeder motor, 1 flywheel, 1 hood servo, 1 turret CR servo, POLLEN only) and demote the archive to a calibration/behaviour source. Regenerate B05–B07 from that.

**F5. `02-intake-feeder.md` § B01 — the channel table's justification is the dual-hardware profile.**
"archived turret requires CR servos (plural) and independent encoder/analog channels" drives a six-channel typed seam. Re-justify per single device; see F25.

### MAJOR — factual mismatches and contradictions with binding docs

**F6. `00-common.md` §3 invents a request terminal state that the contract does not have.**
"completed, cancelled, rejected or faulted." Actual: `RequestStatus.State { ACTIVE, DONE, FAILED, REJECTED }` (`TeamCode/core/src/main/java/boobuzz/core/contract/RequestStatus.java:12`). No CANCELLED.
Fix: decide explicitly in 00-common: either "cancel reports `FAILED` with note `cancelled`" (no contract change), or schedule the enum addition as an explicit B01 sub-item with migration.

**F7. `00-common.md` §2 contradicts binding `protokol.md` on timestamp units, and contradicts A01.3.**
00-common: "integer microseconds on new wire timestamps." `protokol.md` fixes `t_ms` milliseconds; `hal.now()` is `t_ms`. A01.3 says "Preserve the established integer unit." Code agrees with ms (`RealHal.java:39-42`, `sim/server.py:844`).
Fix: drop the microsecond rule, or make it an explicit ADR that amends `protokol.md` first.

**F8. `00-common.md` §2 describes a six-step tick that `RobotLoop` does not have.**
Actual `RobotLoop.tick()` (`RobotLoop.java:96-121`) is `hal.read()` → `engine.sense()` → `controller.decide()` → `engine.act()` → `hal.write(action)`. No estimator step, no validation step; clamping is inside `RealHal.write()` (`RealHal.java:76-85`).
Fix: state the tick order as it is; name the two additions as owned work items (frame validation in B01 with a named class, e.g. `contract/ActionValidator`); say that Pedro is updated inside `PedroDrive`, not in the loop.

**F9. `02-intake-feeder.md` § B01/B04 "no implicit zero" is an unscheduled breaking change.**
Current contract: "A missing key means 0" (`RobotAction.java:19`); `RealHal.write()` writes `clamp(action.servo(name),0,1)` for every servo every tick, so an omitted key commands position 0.0. `protokol.md` restates "Eksik anahtar = 0".
Fix: explicit named B01 sub-item: change `RobotAction` servo semantics to absent-means-hold, update `RealHal`, `SimHal`, `sim/server.py` and `protokol.md` together, with a named regression test.

**F10. `02-intake-feeder.md` § B04 leaves a determinable fact as a worker guess.**
"If the archived robot lacks a beam break…". The archive declares `ballSensorName="intake_dist"` and `maxBallCapacity=3` (`HardwareConstants.java:96,98`) but nothing reads them.
Fix: state it as fact; treat inventory as unsensed; B02's "three for a test" capacity is `maxBallCapacity=3`, cite it.

**F11. A04 / B05 treat an already-resolved encoder question as a gating unknown.**
"turret encoder sharing the `shooterLeft` port name" — the archive answers it: `Turret.encoderName="shooterLeft"` (`HardwareConstants.java:287`) and `Shooter.encoderSource = MotorSelection.RIGHT` (`:151`), so no collision.
Fix: record the resolution; downgrade to "verify on the new single-flywheel wiring". The genuinely suspicious archive value is `Shooter.encoderTicksPerRev = 28` (`:157`) under a comment claiming an 8192-CPR through-bore encoder.

**F12. A02 mass item is based on a stale code comment; its real dependency is unassigned.**
`pymunk_backend.py:81` reads `mass = 12.0  # RobotConstants has no ROBOT_MASS_KG yet` — but `RobotConstants.java:29` DOES define `ROBOT_MASS_KG = 12.0`. The value is not transmitted: the sim reads `RobotConstants.java` by regex (`sim/mechanism.py:20-31`), and `ROBOT_MASS_KG` is absent from `protokol.md`'s scalar list.
Fix: rewrite A02.1 exactly so; add the required step: amend `protokol.md` scalar contract + `sim/mechanism.py` before any fixture, via the ADR route.

**F13. B01 never names the simulator-side file or the single-source-of-truth mechanism.**
`RobotConstants.java` is the only source of truth; `mechanism.yaml` was deleted 16 Sep; Python parses the Java file with regexes (`sim/mechanism.py:20-31`) matching only `public static final double NAME`, `String NAME`, `String[] SERVOS`, one-line `new Motor(...)`. Any new device type needs a one-line machine-readable Java constant AND a new regex. `RobotConstants.SERVOS = {}` today (`:108`).
Fix: add these paths and the one-line-declaration constraint to B01 verbatim.

**F14. B01 "fail at handshake" assumes a capability field the protocol does not have.**
`ready` carries `{"motors":[...],"servos":[],"proto":1,"state":{...}}` — no capability set.
Fix: drop capability negotiation for cplx1 (name-list validation already fails on mismatch), or add an explicit "B00: protokol.md amendment + ADR" step before B01.

**F15. A04/A05 ignore existing predecessor deliverables.**
`docs/phases/phase-1.1/gamepad-map-analysis.md` is a complete button-by-button archive inventory with file:line evidence (RT auto-shoot, RB disabled burst, LB jam reverse, Y jam-clear, LT intake, D-pad offsets, B park, BACK 2-s recovery hold with 4000 RPM / 45° hood / 0° turret). `teleop-map.md` and `request-catalog.md` also exist. A04 orders a new `legacy-behavior-matrix.md` without referencing them.
Fix: make A04 an extension of `gamepad-map-analysis.md`; list those three files under A04/A05 "Read:".

### MINOR — ambiguity a worker must guess

**F16. A01.3** "reject booleans masquerading as integers" — `sim/server.py:818` already rejects `bool`. The real defect is only the silent truncation at `sim/server.py:844` (`int(t_raw)`). Say that precisely.
**F17. A03** tolerances (3 in / 5°; prior 0.15 in / 0.3°) have no cited source; `robot-code/tools/` contains only `agent_example.py`, `drive.py`, `tap.py` — no acceptance-matrix runner to "preserve". Cite doc paths, state the harness is new, name its path and output schema.
**F18. No task in the pack names a single new test class or file path.** Repo convention: `TeamCode/core/src/test/java/boobuzz/core/logic/EngineCancelAllTurretTest.java`, `.../subsystem/stub/StubTurretTest.java`, `re-cock-nize/tests/test_multi_robot.py`. List exact new test names per task — the single highest-leverage edit.
**F19. Engine switching is by index, not name.** `SWITCH_ENGINE` carries a numeric index (`RobotLoop.java:switchIndex`) into `RobotFactory.java:97`'s list `[direct, cplx1]`. Adding an engine renumbers bindings and replay bags. State the mapping; require a named-constant registry before a third engine.
**F20. B03** defers numbers it could state: `FeederPower.singleBallDurationMs = 350` (`HardwareConstants.java:622`), `Feeder.postPulseDelayMs = 500` (`:612`), coalescing behaviour `FeederPowerSubsystem.java:89-114`.
**F21. B06** gives no hood numbers: `hoodMinDeg=25`, `hoodMaxDeg=50`, `servoMinDeg=0`, `servoMaxDeg=215`, `mechanicalMaxDeg=300`, `stowAngleDeg=25`, `defaultAngleDeg=44` (`HardwareConstants.java:673-688`). B07: quote `degreesPerEncoderTick = 360*encoderGearTeeth/(turretGearTeeth*ticksPerRev)` (`:295-296`).
**F22. B08** stationary gate "<=2 in/s and <=5°/s for 150 ms" — `RobotState` has no chassis speed in in/s. Name the derivation (Pinpoint pose differentiation, Pedro follower velocity, or wheel `vel` conversion) and its filter.
**F23. A04** wrong path: Shooting/Aiming/Recovery controllers are in `contingency/lvbelc5/controllers/`, not `teleop/`.

### Scope creep vs Gall's law

**F24. 00-common §4.6-4.7 ceremony is disproportionate**: per-task entry-hash inventory, ≤3 pushed increments, cross-review, annotated `p11a-<task-id>-v1` tag in every repo, `evidence/<ID>/{manifest,commands,acceptance.json,review}` — ~75 tags and ~100 evidence files for one phase. Tag at engine gates only (A05, B09, C05, ...); keep acceptance + trace refs per chapter.
**F25. B01's six-channel typed seam is sized for the archived robot.** Digital channels have no consumer in B02–B09; analog has one (B07). 00-common's own "two consumers" rule argues against it. B01 adds DC output + CR output + incremental encoder; analog inside B07; digital only when a device exists.

### Verified correct
Hashes d5bda62 / 5dd6daa are current HEADs; test counts exact (core 122, :sim 10, python 83); six autos (`AutoRegistry.java:19-24`); engine names `direct`/`cplx1` (+ alias `cplx_engine_1`) match `RobotFactory.java:91-95`; `sim/server.py:692` per-recv timeout and reset barrier at 464-485 are real; B05 archive constants kS=0.18766200 / kV=0.00013514, readiness 100 RPM / 150 ms match `HardwareConstants.java:180-181,201-202`. Sim transport is TCP 5555; 5600/5601 are debug tap / control socket; the real profile already sets `REAL_DEBUG_TAP_PORT = 0` — say so in 00-common §3.

## 4. Reviewer report — 04-shooting-cplx2 (C01–C05), 05-vision-cplx3 (D01–D05), 06-range-cplx4 (E01–E04)

Note from ftc-main: per Tuna's decision 6, chapter D must be split into Vision-A (AprilTag + simple detection, PID on screen offset) and Vision-B (3D map, ball distance, tracking, sectors). The findings below still apply to whichever half inherits the text.

### BLOCKERS

**B1. (D01, D02, E01) The wire protocol has no field for vision or range, and no task schedules the protocol change.**
`state` schema is closed: `t_ms, enc, vel, imu, pinpoint, voltage, gamepad, truth` (`re-cock-nize/sim/physics/motor.py:207-215`; `protokol.md:66-88`); `RobotState` mirrors it (`contract/RobotState.java:25-30`). 00-common §6 requires an ADR for a wire semantic change; `design-spec.md:98` says protocol change is recorded in `protokol.md`. Neither D01, D02, E01 nor B01 mentions this.
Fix: explicit substep at the head of D01 and E01: propose `protokol.md` v2 messages (`state.vision[]`, `state.range[]`), version in `ready.proto`, ADR, paired R/S golden fixture before either side implements. Extend B01's channel table with camera and range rows.

**B2. (D01, E01) `IHal` has no seam for asynchronous observations.**
`IHal` is `now()/read()/write()` (`hal/IHal.java:14-24`); `RealHal`/`Hardware` bind only `DcMotorEx` and `Servo` (`Hardware.java:49-53`, `RealHal.java:68-70`). No `HardwareMap` path for `Limelight3A`, `AnalogInput`, `CRServo` or distance sensor; `RobotConstants.SERVOS = {}`. D01/E01 never name the delivery seam.
Fix: name the decision — e.g. "`RobotState` gains `List<VisionFrame> vision` / `List<RangeObservation> ranges`, populated by `RealHal` and `SimHal`; `IHal` unchanged" — and name the RealHal binding files and the `RobotConstants` device declarations (which `sim/mechanism.py` must also parse).

**B3. (C01/C02) The spec points at the wrong calibration artifact; the archived "coefficients" are TODO placeholders.**
C01 sends the worker to `RonaldoShEngine` + `fits.json`. `fits.json` has 4 samples, all hood=38, no distance/height/voltage column. The real distance calibration is `archive/ftc/de-cock/.../config/logic/AdvancedLogicConstants.java:315-345` — `lookupTable = {distance, hood, minRpm, maxRpm}` over 43.3–90.7 in. The archive's selected method is `LINEAR` (`RonaldoShEngine.java:123,189-193`) whose coefficients are `15.0*distance + 2500.0` with `// TODO: Placeholder coefficients` (`:440-443,456-457`). The `R² = 0.9656` comment (`:136`) is attached to a method that never received fitted numbers.
Fix: name `AdvancedLogicConstants.Solvers.Ronaldo.lookupTable` as primary source; mandatory finding "LINEAR/POLY coefficients are placeholders — quarantine"; drop evidence columns the data cannot supply.

**B4. (C02) "distance-to-RPM/hood lookup with piecewise-linear interpolation" is not well defined for the actual table.**
The table is a set of feasible `(hood, minRpm, maxRpm)` rows per distance (5 rows at 43.3 in, 7 at 66.1, 4 at 75.6); the archive resolves with `shooterRpmWeight = 0.55` blend plus an independent hood polynomial (`RonaldoShEngine.java:98,108,126`). C02 never mentions min/max/weight.
Fix: state the reduction rule ("reduce each distance row-group to one `(hood, rpm)` by the documented weight, record it as a named constant, interpolate linearly in distance; reject outside [43.3, 90.7] in").

**B5. (C02/C05) The live in-repo calibration is never mentioned.**
`ShooterCalibration.calibratedRpm = 300 + 1.0*d` (`logic/ShooterCalibration.java:12-19`, `RobotConstants.java:47-50`, `SHOOTER_HOOD_PER_IN = 0.0`); `direct` and `cplx1` use it; `ShooterRpmConsistencyTest:43` pins it. Two orders of magnitude below the archive's 3700–4400 RPM.
Fix: C01 labels these constants as unprovenanced placeholders; C02 states "cplx2 uses `ShotSolver`; cplx1/direct keep `ShooterCalibration` unchanged" or explicitly authorises changing it.

**B6. (C04) The existing turret API cannot express what C04 requires.**
"reject unreachable turret headings" — `ITurret` is `aimAt(fieldX, fieldY)` returning void, no limits, no reachability; `CplxEngine1.java:87` hard-rejects every `TURRET_AIM` ("turret is automatic in cplx1"); `TurretLogic.java:31-35` hardcodes the goal from `RobotConstants.GOAL_X/GOAL_Y`. C05 says "compose cplx1 coordinator" but cplx1's turret owner cannot accept a solver bearing.
Fix: name the API change (e.g. `ITurret.aimRelative(double angleRad)` returning reachability, added in B07); cplx2 replaces `TurretLogic`'s hardcoded goal with a solver target.

### MAJOR

**M1. (C05, D05, E04) "Selectable engine" is never wired to the actual mechanism.** Engines are a `switch` on `"cplx1"`/`"direct"` (`RobotFactory.java:91-96`); mid-match switching is by integer index (`RobotLoop.java:90-104,242-267`). Fix: register in `RobotFactory.createWithController`, fixed order `direct, cplx1, cplx2, cplx3, cplx4`, regression asserting index order.
**M2. (D02) 20 Hz frames do not fit the 20 ms lockstep tick.** 20 Hz = 2.5 ticks; determinism is required (`protokol.md:102-104`). Fix: 25 Hz (every 2 ticks) or 12.5 Hz; "asynchronous" means a capture-time offset in the payload, not out-of-band delivery.
**M3. (D02) Independent RNG streams need a backend refactor nothing schedules.** Backend owns a single `self.rng` (`motor.py:203-213`, `pymunk_backend.py:188`); adding camera draws breaks `tests/test_determinism.py`. Fix: split into `rng_pose/rng_vision/rng_range` seeded by `(seed, stream_id)`; assert byte-identical determinism with vision disabled.
**M4. (D04) depends on F-package game modelling.** Target-load beliefs and "Hive tips widen belief" need F01/F02; the sim has no ball/goal/hive object. Fix: cut D04 to sector staleness + observed/unobserved flag; move target-load beliefs behind F02 (→ Vision-B).
**M5. (E02) contradicts itself on vision dependency** (:42-45 "fresh vision" vs :51 "before any vision fusion"). Fix: delete the vision clause; move any vision-gated variant to E03.
**M6. (E03 vs D03)** E03 offers covariance intersection; D03 uses an isotropic radius. Fix: single method = conservative scalar radial update; covariance intersection → future ADR.
**M7. (C03 vs B08)** B08's exit is "actuator-causal pollen release" and B09 asserts object conservation, but nothing in B02–B08 creates a projectile (B03: "a feeder event alone does not spawn a projectile"). Fix: state in B08 that release = ball leaves inventory into a planar Pymunk body with no vertical flight; C03 upgrades later. Say it in both files.
**M8. (C01)** assigns target dimensions to S, but `protokol.md:13` makes `RobotConstants.java` the only source, and `GOAL_X=48 / RED_GOAL_X=96 / GOAL_Y=96` (`:44-46`) disagree with `protokol.md:45-47` alliance walls (RED x=0, BLUE x=144). Fix: authoritative numbers land in `RobotConstants`; `sim/mechanism.py` gains matching rows; existing `GOAL_*` replaced or renamed `LEGACY_GOAL_*`.

### MODERATE

**Mo1.** C01/C02 import archive shooter calibration without noting it came from a dual-flywheel shooter (`robot-code/docs/miras/01-shooter.md`). Add: "single-flywheel launch-speed mapping must be re-derived, not assumed equal."
**Mo2. (E02)** `a_brake` left to invent although `ZERO_POWER_DECEL_FORWARD_IN_S2 = 36.17`, `_LATERAL = 85.98`, free speeds 73.63 / 54.09 in/s exist (`RobotConstants.java:30-36`). Name them.
**Mo3. (D03, C04, E03)** "declared mild noise" is a self-referential gate. Fix one numeric profile in D02 (e.g. bearing σ 1.0°, range σ 3%, P(miss) 0.10, latency 60±20 ms, seeds 1..10) and reference its ID.
**Mo4.** Missing file/package names, test names and seeds throughout C02–D05/E02 (`ShotSolver` package? `WorldUpdater`? where the range limiter sits — `RobotLoop`, `MotionLogic`, or new class?). Give concrete paths (`logic/shot/ShotSolver.java` + `ShotSolverTableTest`, `logic/world/WorldUpdater.java`, `logic/safety/RangeLimiter.java` inside `MotionLogic.act` before `drive.manual(...)`) and fixed seed lists.
**Mo5. (C03)** Launch velocity omits muzzle world velocity from chassis twist + turret rate (roadmap-v1 :272-273 requires it). Stationary gate lives in the engine, not the physics.
**Mo6. (E01)** range-sensor fixture under-specified: give provisional mount poses, min/max, FOV, period, σ, marked "fixture only".

### MINOR
- C02's ballistics check `v² = g·r²/[2·cos²θ·(r·tanθ − dz)]` is correct.
- C01 "do not infer launch angle from hood servo angle" is supported: `fits.json` hood=38 for all four videos yet θ 63.7°–69.1°. Cite it.
- README "No tags for this draft" vs tuna-intent "tag after each accepted step": scope the README line to the draft period.
- D02 occlusion / E01 field obstacles need F01 structures; multi-robot occlusion already feasible (`sim/physics/multi.py`).
- C03 "move to Pymunk rolling when vertical motion small": name a threshold (e.g. `z < 0.5·r` and `|vz| < 5 in/s` for 2 ticks).
- `sim/server.py:130-131` currently rejects any non-empty servo command — B01/B06 must lift it before C03's hood-derived launch.
- Say once in C02 which frame the solver returns (field azimuth, radians, CCW from +x); C04 only maps to turret angle.

## 5. Reviewer report — 07-game (F01–F04), 08-environment (G01–G05), 09-learning-preparation (H01–H05), 10-research, roadmap/intent consistency

Note from ftc-main: per Tuna's decision 2, these chapters stay as written for now (no deletion), but nothing below is to be worked on before B09. Record the findings in the files' headers as "known issues, revise after B09".

### BLOCKER

**B1. (G03) inverts the protocol's clock ownership; no task owns the protocol change.** `protokol.md:7-9`: Java is client and clock owner; Python does not advance without `step`. G03's Gym `reset/step` around the Java loop needs a reverse control channel, `proto` bump and handshake, assigned nowhere. Fix: add G00 specifying the env↔Java control channel (`reset/act/ack/obs`), clock ownership in env mode (recommended: Java keeps the clock and blocks on `act`), paired fixtures.
**B2. (G01/G03) demand bit-exact rollout determinism from an asynchronous, lossy controller.** `SocketController.java:29-48`: background threads, last-value-wins `AtomicReference`, drops feedback when the 64-slot queue fills. Fix: env mode uses a synchronous variant (indexed action queue); async `SocketController` stays debug-only; fixture: same seed + actions → identical `truth`.
**B3. (obs-v1 vs F03) Nothing carries match clock/game state to the robot.** obs-v1 indices 0–3 are remaining-time/auto/transition/teleop; F03 builds the clock in Python; wire `state` and `WorldSnapshot(t, pose, yaw, voltage)` have no match field. Fix: F03 sub-step defining a `match` block on `state` and its `Feedback` extension; only phase + remaining time cross, never score.

### MAJOR

**M1. Single-hardware violations**: `specs/README.md:76`, `roadmap-v1.md:149,502`, `specs/10-research.md:24`. 07/08/09 themselves are compliant (obs-v1 uses singular `flywheel-rpm`, `hood-command`, `turret-angle`).
**M2. (F04)** re-specifies multi-robot the sim already has (`sim/physics/multi.py:11-48`, `server.py:320-485,854 --robots`) and quietly requires scripted opponent mechanisms; one TCP client per robot. Fix: cite `MultiRobotWorld`; split F04 into scripted-opponent harness and 20-match completeness run; say whether opponents get mechanisms.
**M3. Ownership contradiction**: 00-common:146 says G/H are S-owned, but G01/G02 are R work; H02 has no owner. Fix: per-task owner table (G01=R, G02=R+S fixture, G03=S, G04=S, G05=D, H01=D, H02=S, H03=R+S, H04=R, H05=D).
**M4. (G02)** "current public feedback" is not current: `Feedback` = `WorldSnapshot` + `List<RequestStatus>`; 10-research:17 admits it. Fix: per-block producing-task column; obs-v1 cannot freeze before those land.
**M5. (obs-v1)** `owner belief / owner confidence` have no producer (D04 gives load beliefs only; F01 puts ownership in the scorer, forbidden to the policy). Drop or add a bounded D sub-step.
**M6. (F01 too late)** pollen/nectar dimensions (~2.8 in / ~3.6 in, 07:13) needed by B02, C01, C03. Fix: split "F00 — object and field dimension constants with provenance" and schedule before B02.
**M7. (gating)** G01 and H04 are cheap and decision-relevant, gated behind F04. Fix: G01 after E04 (or B09); H04 and H03 xRC feasibility as early independent spikes.
**M8. (training risk)** constructing `PPO(...)` instantiates `torch.optim.Adam`, falsifying H05's "no optimizer invoked". Fix: synthetic weights as raw tensors with fixed seed; no SB3 algorithm object in any executed path; CI grep for `stable_baselines3`, `.learn(`, `optim.`, `loss.backward`.

### MODERATE
D1 roadmap-v1:317-319 mechanism action vocabulary vs 08:11 Box(3) drive-only — add superseded note. D2 reward vs official scorer wording (roadmap:328 vs 09:45-47). D3 Hive model: bistable/hysteresis (roadmap) vs angle/rate/torque (F02); tuna-intent:94 count threshold vs moment calc. D4 co-operator script required by G01/G03, owned by none — Java `CoOperatorController` in `core/controller`. D5 G03 settle phase undefined in F03. D6 demonstration logging (G01) before obs-v1 schema (G02). D7 obs-v1 capacities (8/3/8/8) asserted; truncation asymmetry unexplained. D8 F01/F04 "critical"/"important" undefined — list rule IDs. D9 F03 judgment/penalty layer unenumerated; ranking points consumed by nothing. D10 F02 hides a second chapter ("remaining structures") — split F02a/F02b. D11 no seed list / wall-time budget for 20 matches / 20 episodes. D12 SB3/PyTorch wheels on Python 3.14 (sim runs 3.14) deferred by both chapters — make it an H01 deliverable with a separate 3.11/3.12 venv fallback. D13 H04 "1e-5" has no norm/fixture count. D14 H03 70/15/15 split has no size floor. D15 tag naming drift (`p11a-g05-env-v1` vs `p11a-<task-id>-v1`).

### Verified correct
G02 arithmetic 32+32+72+30+40+80+6 = 292; ×4 = 1,168. H01 hyperparameters self-consistent (2048/256, γ=0.999, 10 Hz / 50 Hz = 5-tick hold). G01 frame convention matches `RequestStream.manual` and `protokol.md:22-24`. 10-research repository claims check out (stubs `RobotFactory.java:85`, Pedro 3.0.0, linear calibration, PyBullet preserved). `SimMain --control-port` exists; but G01's wall-clock watchdog `CONTROL_SOCKET_TIMEOUT_MS=250` will misfire under non-realtime stepping — env mode must disable or scale it.
