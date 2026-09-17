# Phase 1.1-a roadmap v1 — discussion draft

> Historical broad draft, superseded by [v2 index](specs/README.md),
> [hardware-profile-v0](hardware-profile-v0.md) and Tuna's
> [review decisions](review-ftc-main-specs-2026-09-17.md). A/B now have worker detail;
> C is medium; later bodies remain notes, not work orders. Tags/manifests only at
> baseline/engine gates, evidence per chapter, cross-review only on R/S seams.
> Vision-A precedes Vision-B; range follows them. Old action/reward/far-stage
> prescriptions are retained history and must be reconciled after B09.
>
> Current release status (2026-09-17): Tuna approved v2.2. Chapter A is released now;
> A02 is unblocked at protected pin `26f915b`. B is approved but gated, with B01
> blocked pending the ADR signature pin, until A05/evidence/tag. C and the far roadmap
> remain unreleased. Training, ftc-reviewer, and ftc-ball remain forbidden.

Expanded by the [detailed review spec pack](specs/README.md). That newer proposal
includes pollen-only intake, executable substeps and model/reward preparation.
This v1 remains the historical broad draft; neither document authorizes execution.

Date: 2026-09-17. Author: ftc-main-cx. Status: **not dispatched for implementation**.
Authority: [Tuna's latest direction](tuna-intent-2026-09-17.md).
All work below stays on `dev-phase-1.1-a`; these are work packages, not new phases.
The protected protocol gate is already approved: ftc-main amendment `26f915b`,
reconciled in docs at `0973e86`.

## 1. Starting point and what needs to change

The driving/control infrastructure exists. Robot `d5bda62` contains R9's turret-stub
hold fix (`1e555cb`). The independent review reports 122 core tests, 10 sim tests,
Android assembly and 14 Pymunk auto/path runs passing. Simulator `78bad12` fixes
the staggered multi-robot startup barrier; `5dd6daa` strengthens the wire-level
determinism proof. The worker reports 83 Python tests. These are
pinned worker results, not proof of physical hardware operation. Later checkpoint
commits must be recorded in the eventual baseline manifest.

Important limits of that starting point:

- `RobotFactory` still constructs `StubShooter`, `StubIntake` and `StubTurret`.
  Their timers/events do not demonstrate actual actuator control.
- `RobotConstants` declares four wheel motors, no servos, and a placeholder
  shooter calibration of `300 + distanceInches` RPM.
- `RealHal` supports motor power, position servos, wheel feedback, Pinpoint and
  gamepad. It has no explicit CR-servo, turret analog, camera or range input model.
- The Python world currently simulates chassis motion. `sim/field.py` deliberately
  omits game mechanisms; the background image supplies no collision/scoring geometry.
- A reviewed simulator socket-timeout gap, fractional event timestamp validation,
  mass-configuration mismatch and turret scan-cancellation test gap remain.
- Previous acceptance tables often compare sensor pose to truth. We also need
  truth-to-commanded-target and old-to-new behavior comparisons; these are different.

The target is a continuously runnable robot/simulator pair, built from demonstrated
mechanism behavior. A compiling abstraction or a simulated successful shot is not
enough by itself to establish that a physical mechanism will work.

## 2. Architecture and framework decisions

| Area | Proposed choice | Reason and boundary |
|---|---|---|
| Robot control | Existing Java `:core`, FTC SDK only in TeamCode adapters; keep Pedro 3.0 | Preserve the working driving stack and identical mechanism/engine bytecode in robot and sim. Do not upgrade Pedro/SDK as incidental work. |
| Mechanism control | Small deterministic Java classes with explicit `dt`; existing interfaces extended only when required | Port useful PIDF/pulse/angle behavior without importing the archived FTCLib scheduler or Android timing into core. |
| Simulation | Existing Python + Pymunk + pygame-ce | Pymunk handles planar chassis/ground contacts. Retain existing PyBullet support without adding feature-parity work to the critical path. |
| Projectile motion | Small fixed-step flight model over Pymunk: x/y/z, velocity, gravity, restitution and rolling transitions | Pymunk is 2D. Airborne trajectories and elevated goals need height-aware code; pretending everything is a floor circle would give false shooting results. No RK4 project. |
| Vision adapter | FTC SDK Limelight API behind HAL; simulated raw detection frames with equivalent fields | No rendered-image pipeline, neural detector training or Python perception logic duplicated in Java. |
| Estimation | Java timestamped observations, bounded track list, explicit uncertainty; simple association/filter first | A learned estimator comes only after a measurable classical baseline. Avoid ROS, SLAM and a generic factor-graph framework at this scale. |
| Tests | Existing JUnit + Python unittest, seeded process/socket tests, actuator-trace fixtures | Reuse current tooling; no test-framework migration. pygame supplies a human-readable acceptance demo. |
| Calibration analysis | Existing data tools; NumPy/SciPy only if an actual fitting task needs them | Offline analysis may emit checked-in Java constants. Robot startup does not read a new runtime configuration format. |
| RL interface, late | Gymnasium adapter around the existing Java controller seam | Gym supplies reset/step/space conventions. No policy learner, training run or Stable-Baselines dependency in this roadmap. |

Pymunk's documented scope is planar rigid-body physics: [Pymunk documentation](https://www.pymunk.org/en/latest/).
Limelight exposes detector results through its FTC integration: [FTC programming guide](https://docs.limelightvision.io/docs/docs-limelight/apis/ftc-programming).
Gymnasium specifies seeded reset and separate termination/truncation results:
[environment API](https://gymnasium.farama.org/api/env/).

Keep the visible layering:

```text
TeamCode/core/
  contract/     raw inputs, actuator outputs, requests, feedback, observations
  hal/          interfaces + compile-time device/geometry/calibration description
  subsystem/    drive, intake, feeder, flywheel, hood, turret implementations
  logic/        direct, cplx1, cplx2, cplx3, cplx4; shared small calculators
  controller/   teleop, auto, replay, socket, eventual external-policy adapter
TeamCode/src/   FTC device adapters and thin OpMode shells
robot-code/sim/ thin transport/client runner using the same core
re-cock-nize/   actuator plants, physical world, sensor generation, game rules
```

The new protocol/config decisions go into `phase-1.1-a/` documents, leaving the
historical protected specs intact. Wire evolution must be explicit: new version
or negotiated capabilities, missing-device behavior, timestamp/units, and paired
Java/Python fixtures. A legacy client may continue only when its semantics remain
valid; unsupported actuator/sensor capabilities must fail clearly.

## 3. Engine ladder and fallback rules

| Engine | Added responsibility | Explicitly excluded |
|---|---|---|
| `direct` | Mechanism exercise/recovery through narrow commands and observable statuses | Autonomous world decisions |
| `cplx1` | Reliable mechanism coordination; manual chassis, fixed shot presets, known goal aiming, deterministic cancellation | Vision/world-model dependence, advanced shot prediction |
| `cplx2` | Calibrated distance-to-shot solution and stationary automatic aiming/shooting | Learned models, speculative shoot-on-the-move |
| `cplx3` | Sector scan, vision-only object tracks and target/inventory beliefs; retain cplx2's predictable shot execution | Range fusion, autonomous pursuit based on uncertain tracks |
| `cplx4` | Chassis range observations, conservative obstacle response and gated multimodal fusion | Unvalidated localization corrections or learned control |
| Later optional engine | World-guided collection/target choice, after full-system and field tests | RL training; no implementation until that gate |

Use small composition-based engine variants and shared mechanism/shot primitives.
Do not copy entire engines or create a subclass tree. A new engine marks a meaningful
change in decisions, not each bug fix or each motor implementation. Preserve tagged
older implementations and run their acceptance cases when shared code changes.

Switching engines cancels active owners, preserves valid sensor/localization state,
clears stale requests, emits terminal statuses and applies actuator-specific safe
handoff commands. A position servo's safe action is not automatically position zero.
Vision loss must leave cplx2/cplx1 usable. Switching out of a scan cannot leave a
turret command or feed pulse owned by the abandoned engine.

## 4. Work package A — trustworthy baseline and archived behavior map

### A0. Close the small baseline defects

Implement/review one at a time: bounded multi-robot socket I/O; integer event
timestamps; Java/Python mass consistency; pending-scan cancellation coverage.
Do not rework unrelated physics. Freeze a manifest of all three repository hashes,
runtime/dependency versions, constants hash, commands, seeds and artifact locations.

Run both engines over the six autos and test-line. Record request completion,
truth-to-target errors, sensor-to-truth errors and regression against the pinned
baseline separately. Preserve inherited target tolerance (3 in / 5 degrees for
autos) and the previous 0.15 in / 0.3 degree regression envelope where applicable;
do not reinterpret noise agreement as target accuracy. Record/replay must match
every truth sample within the same pinned environment. Add a short visible demo.

### A1. Map actual last-season behavior before porting

Build `legacy-behavior-matrix.md` and a parameter provenance table. For each driver
gesture trace button edge/hold/release -> request/state -> actuator commands ->
feedback -> stop behavior. Inspect the match-used call path and configuration,
not every abandoned experimental subsystem. Classify every behavior as preserve,
documented correction, optional later behavior or unknown.

Primary sources already located in the archived DE-Cock tree:

- `contingency/lvbelc5/teleop/{BlueTeleop,RedTeleop}.java` and
  `controllers/{ShootingController,AimingController,RecoveryController}.java`.
- `hardware/subsystems/intake/IntakePowerSubsystem.java`.
- `hardware/subsystems/feeder/FeederPowerSubsystem.java`.
- `hardware/subsystems/shooter/ShooterPidfPowerSubsystem.java` and
  `settings/storage/shooter/ShooterPidfPowerStorage.java`.
- `hardware/subsystems/turret/TurretPidPazarSubsystem.java`.
- `hardware/subsystems/hood/HoodSubsystem.java`, `config/HardwareConstants.java`.
- `contingency/lvbelc5/engines/RonaldoShEngine.java` and its coefficient sources.
- `hardware/subsystems/vision/limelight/Limelight.java` for later vision work.

Concrete observations that the port must account for:

- Shooter uses power-domain PID + feedforward, integral zone/clamp, optional slew,
  and a readiness dwell for ONE shooter with TWO motors. Archive defaults include 100 RPM error
  tolerance and 150 ms stable duration; these are inherited settings, not new measurements.
- Feeder owns pulse/delay sequencing. `clearRequest()` lets a running pulse finish;
  `stop()` cancels it immediately. The archived pulse default is 350 ms, not the
  current stub's 200 ms. Driver release and emergency cancel need distinct semantics.
- Turret preserves TWO CR servos (`turret_servo`,`turret_servo2`) on ONE mechanism,
  same logical power/both FORWARD; incremental encoder `shooterLeft`
  and analog startup input `turret_analog`, with inherited -90 to +90 degree limits.
  Shooter speed uses `shooterRight`; BOTH motor outputs drive shooter, while
  shooterLeft's encoder input measures turret. Do not delete the follower output.
- Hood preserves TWO position servos `hood_left`/`hood_right` on ONE mechanism,
  complementary commands (LEFT inverted), with the archive mechanical clamps.
- Current teleop RB/LB behavior differs from the archived hold-based shooting and
  reverse controls. Proposed default: restore the match-used driver's map, keep the
  present diagnostic map as an explicitly selected alternative. Discuss this choice.

Fixtures use recorded sensor/time inputs and expected actuator traces. Compare a
small extracted legacy calculation/reference harness with the new implementation;
do not build a second full legacy robot. Discrete timing tolerance is at most one
control tick; exact direction/order and cancel semantics must match. Unit mistakes
or known unsafe legacy behavior get a documented correction, not silent imitation.

Gate A: deterministic chassis baseline, outstanding baseline failures resolved,
archived behavior/provenance matrix and explicit control map. Then tag `p11a-a-baseline`.

## 5. Work package B — real subsystem behavior in the shared core

### B0. Minimum device contract and simulator plant foundations

Add only the channels required for the next mechanism: DC motor power and
encoder/velocity, CR-servo power, position-servo position, analog voltage, and
available digital inputs. Keep actuator type distinct from mechanism role. A
shooter motor is not another mecanum wheel; Python must apply chassis forces only
to wheel-role motors. Define gear ratio, polarity and ticks/RPM once, and test the
round trip. Keep missing input different from a valid zero measurement.

Use the archived hardware profile as an explicit provisional configuration. Document
every inherited/default/unmeasured value. Extend `Hardware`/`RealHal` and `SimHal`
together, including capability/name checks. Motor/CR stop means zero power; hood
hold/stow follows a named policy. Validate all commands before any device write.

The Python plant consumes actuator commands and produces sensor readings. Java
owns PID, readiness, pulse and request decisions. Do not put a second controller
inside the simulator or make an emitted `feed` event spawn a ball by itself.

### B1. Intake

Port signed power, direction, brake/stop and reverse behavior. Simulate shaft speed
and a simple capture mouth/contact test with finite ball inventory; start with a
floor-ball fixture, not the whole game. Test press/hold/release, forward/reverse,
manual cancellation, no capture while off, and no duplicate capture.

### B2. Feeder and inventory boundary

Give pulse timing a dedicated owner, likely `IFeeder`/`PulseFeeder`, composed by
the shot coordinator. Port single pulse, request coalescing, inter-pulse gap,
normal completion, release behavior and immediate stop. Use HAL time exclusively.
Simulate passage/jam/empty-feed from actuator motion and inventory; expose only
the sensors actually declared for the provisional hardware.

Tests cover stop during pulse/delay, restart, held/repeated requests, reverse,
exactly one release per valid ball passage and an empty request without a phantom ball.
Robot inventory is a sensor-supported estimate; simulator inventory is separate truth.

### B3. Flywheel shooter

Port the archived controller math into SDK-free `FlywheelShooter`: RPM conversion,
PIDF, clamping/anti-windup, slew, readiness dwell, target changes and spin-down.
Use right=power, left=power*followerScale1.0 with right reversed/left forward in HAL;
velocity source is shooterRight only, while shooterLeft encoder measures turret.
Inspect archived feedforward units before
adding any voltage compensation; do not apply compensation twice.

The plant models independent flywheel inertia/lag, battery limitation, sensing noise
and speed loss when a ball passes. Tune from archived evidence where available.
Test spin-up, sustained readiness, target step, recovery after one/three shots,
stalled/bad sensor, low voltage, cancel and restart. Readiness is measured speed
within tolerance for a duration, never an elapsed-time substitute.

### B4. Hood and turret

Port BOTH hood channels' complementary conversion and limits on ONE hood angle;
test paired endpoints/intermediate positions and hold. Turret also keeps BOTH CR
outputs on one angle controller, with equal logical power rather than hood inversion.
Give hood motion a finite simulated rate. Port turret calibration, encoder scaling,
analog initialization/filter, angle wrap, bounded target motion and hold/manual stop.
Start with fixed angle commands; no scanning yet. Distinguish `hold current angle`
from `disable/zero power` and from `cancel old aim`; document what each API does.

Simulate motorized turret inertia/friction, hard travel limits, sensor noise and
calibration failure. No presumed slip ring or unlimited rotation. Test limits,
startup without valid absolute feedback, stop while moving, sign/gear conversion
and the shared encoder-port case. The same core drives fake HAL and FTC adapters.

### B5. Integrate the simplest usable engine

Wire these mechanisms into `direct` and `cplx1`; retain stubs as unit fixtures only.
Port the accepted legacy control map through the controller/request seam. Mechanical
sequencing remains below the controller. Keep normal driver release, manual takeover,
cancel-all and engine switch independently tested. Add fixed-preset shot coordination
with wheel-ready, turret-settled and feeder-state gates; target selection stays simple.

Gate B: scripted button sequences produce expected powers/positions and sensor
responses through real Java core + Pymunk. Replay cases include warmup, pulse,
release, reverse/jam clear, turret target and engine fallback. Complete a visible
drive/intake/feed/aim demo plus Android assembly. Claim software/sim validation,
not physical tuning. Tag only the engine checkpoint `p11a-engine-cplx1-v1`.

## 6. Work package C — shooting and practical ballistics

### C0. Audit the calibration, including its limitations

Extract the archived distance-to-RPM and hood functions/tables with their units,
distance reference point, target height and validity range. `RonaldoShEngine` uses
weighted min/max functions and clamps; do not preserve its always-valid result for
unreachable shots. Last season's field target coordinates are not this year's goals.

Existing `ball-auto-istic/calibration/step3_analysis/fits.json` contains trajectories
derived from named videos; a separate synthetic fit file also exists. Inspect these
read-only if useful, without activating that agent or reviving its solvers. Establish
provenance before treating numbers as measurements. Hood command angle is not
automatically the projectile's launch angle: the sample fit file visibly differs.

### C1. Fixed-shot proof, then a calibrated solver

First demonstrate a fixed RPM/hood shot at a known fixture target. Then implement
a pure `ShotSolver` returning RPM, hood command, turret bearing, validity/reason
and calibration provenance. Prefer bounded piecewise interpolation if real sample
points support it; otherwise port the proven archived fit as an inherited model.
Do not synthesize fake measured data by sampling a polynomial.

Calculate distance from the muzzle/exit geometry, not blindly from chassis center.
Handle range/angle/hood/RPM limits, unreachable targets and invalid pose explicitly.
Initially require a stationary or sufficiently slow chassis and settled turret.
Moving-shot compensation is deferred until a stationary solution is trustworthy.

### C2. Independent projectile and target model

Model launch from measured simulated wheel speed, hood geometry, muzzle pose and
chassis/turret velocity. A simple gravity trajectory plus calibrated launch-speed
mapping is sufficient initially. Add drag only when evidence shows it improves fit.
Use SI inside new flight math with explicit conversion at the existing inch/radian
boundary. Avoid a migration of all working drive units.

Use Pymunk for rolling/ground contacts and height-aware swept contacts for flight,
floor, walls, frame and elevated target volumes. Define flight-to-bounce-to-roll
transitions, restitution/friction, inventory and conservation. Do not make the
simulator use the inverse of the same shot solver as its only accuracy oracle.
Check physical trajectories/held-out archived samples separately; broaden uncertain
plant parameters to expose brittle solutions.

Add only the target geometry and simple mechanism fixture needed for shooting now.
Full Hive/Flower scoring and match lifecycle remain in package F.

### C3. cplx2 shot coordination

Use `PREPARE -> AIM/SPIN -> READY -> FEED -> RECOVER -> DONE/FAULT`, with bounded
timeouts and clear ownership. Manual/cancel/switch can interrupt safely. A feed
completion is not proof a goal scored. Report attempted, released and observed
outcomes separately; re-evaluate readiness after shot-induced RPM drop.

Gate C: fixed and varied-range stationary shots, three-ball sequences, empty/jammed
cases, target outside range, cancellation, bad pose and voltage variation. Publish
landing error, miss/reject rate, time-to-ready and assumptions across a fixed seed
set. Fit-error thresholds come from the recovered data; do not invent a physical
success rate without it. Tag fixed-shot/solver checkpoints and `p11a-engine-cplx2`.

## 7. Work package D — one Limelight, bounded scan and vision-only world model

### D0. Observation contract and moving-camera time alignment

Define observations with sensor/frame identity, capture time, receive time, class,
bearing/elevation or supported relative measurement, confidence/uncertainty and
validity. Simulator object IDs are forbidden. A bounding box alone does not provide
perfect 3D range: use ground-plane/known-geometry estimates only when justified,
otherwise preserve bearing-only uncertainty.

Maintain timestamped histories of robot pose AND turret angle. Transform at capture
time through camera -> turret -> robot -> field, using mount translation, height,
yaw/pitch and calibrated optical geometry. Interpolate history and reject frames
outside the retained window; do not transform an old exposure using today's turret
angle. Handle repeated frames, dropped/out-of-order data and pipeline-switch latency.

Port a small real Limelight adapter and build a matching simulated detector. Simulate
FOV/range/occlusion, object class/confidence, noise, capture cadence, latency,
false positives and motion-related misses. Poll frequency is not camera frame rate.
Keep seeded random streams separate so enabling camera noise does not change motor
or Pinpoint noise. No image rendering/training is required.

### D1. Settle-and-look turret scan

Start with a fixed bounded sector schedule. One turret arbiter owns priority:
fault/stop, manual override, active shot, then scan. `MOVE -> SETTLE -> OBSERVE`
requires an exposure captured after settling; receiving an old frame is insufficient.
Shooting preempts scan, reacquires aim/readiness, and finishes/aborts before scanning
resumes. Respect cable/travel limits and the single camera's pipeline availability.

### D2. Vision-only tracks and beliefs

Track balls and robots with position/velocity, uncertainty, last-seen time and class
confidence. Begin with distance/uncertainty-gated association and a small filter;
introduce covariance/Kalman machinery only with tests demonstrating benefit. Use
one-to-one association, track birth/death and lost/occluded handling; bound work and
memory per tick. Do not silently relabel every unobserved object as absent.

Maintain a sector observation history and conservative ball-count/target-state
belief. Negative evidence is valid only inside a recently observed, unoccluded
region. A commanded shot may update a prediction, but confirmed contents require
evidence. Track each target/cell separately, with uncertainty and a change/tip state.
Scanning can prioritize stale/uncertain useful regions once fixed-sector tests pass.

The `cplx3` engine exposes this model in Feedback/debug views while using the already
tested cplx2 shot mechanism. It is the requested vision/world-model engine without
an entangled autonomous collection planner. Goal occupancy can guide a conservative
scan-versus-aim policy; it must never be copied from privileged simulator truth.

Gate D: stationary/moving-camera transforms, missed frames, occlusion, fast sweeps,
duplicate observations, two similar balls crossing, shot preemption and vision loss.
Report track error/age, ID switches, false tracks and scan coverage on seeded cases.
Compare internal truth only in evaluator code. Tag scan, world-model and cplx3 steps.

## 8. Work package E — chassis distance sensors and conservative fusion

### E0. Range interface and plant

Represent each sensor by mount pose, cone/FOV, range limits, cadence, timestamp,
validity and uncertainty; hardware type/count remain configurable until known.
The real adapter uses a bounded round-robin read schedule. Simulate nearest visible
surface with cone samples/shape queries, noise, dropout, floor returns and occlusion.
No assumption that every return is a robot or ball.

### E1. Safety before fusion

Implement a tested near-obstacle speed limit from fresh range observations, independent
of the object tracker. Choose thresholds using body geometry, reaction latency and
simulated braking distance. Stale/invalid range has an explicit degraded policy;
it must neither command acceleration nor fabricate a clear corridor.

### E2. Association, then fusion

Project the measurement at capture time and compare with visible map surfaces/tracks.
Only fuse a range with a visual object when geometry, time, uncertainty and occlusion
support that association. Otherwise retain an anonymous obstacle observation.
Treat known-wall localization updates as a later substep; do not feed arbitrary
range returns directly into Pedro or count correlated camera/odometry data twice.

Add `cplx4` with this fusion and independent reflex behavior. Test disagreement,
unseen obstacles, glass/no-return assumptions, late samples, moving robots and
sensor failure. Provide vision-only and range-only ablations to show when fusion
helps and when it must refuse an update. Tag each accepted substep and cplx4.

## 9. Work package F — complete the BIOBUZZ game world

Obtain and pin authoritative rules, field drawings and Team Updates; preserve their
version/hash and cite each modeled rule. The existing DECODE PDF is not a BIOBUZZ
authority, and the viewer image is not a dimensional source. FIRST currently lists
BIOBUZZ manual V1 and TU00 on its [season resources page](https://ftc-resources.firstinspires.org/ftc/game).

The manual describes bistable tipping Hives, distinct scoring elements, timed match
periods and target-dependent scoring. Model those explicitly, not as a static bucket
with a guessed count. Source: [BIOBUZZ manual](https://ftc-resources.firstinspires.org/ftc/archive/2027/game/cm-html/BIOBUZZ%20Competition%20Manual%20-%20V1.htm).

### F0. Rule and geometry manifest

Create a requirement matrix for starting objects, dimensions, permissible interactions,
field mechanisms, clock transitions, scoring/ownership, penalties and match reset.
Each row has a source, implementation owner, test and status. Read early enough to
use correct shooting-target geometry in C, but defer complete match mechanics here.

### F1. Objects and tipping mechanisms

Model each scoring element's class/color and physical state; keep simulator identity
private. Reproduce capture, release, rolling, airborne hits, containment and ejection.
Conserve objects across field, robot inventory and goals.

For Hives, start with one rotational degree of freedom, geometry/load-derived torque,
two stable states, hysteresis, finite tip duration and ejection behavior. Where
physical constants are unavailable, label a parameterized surrogate and bracket its
behavior; do not assert an exact ball-count threshold. Account for where balls land,
not just their count. Test one mechanism before connecting all structures.

Keep mechanical events distinct from scoring events: one contact must not earn
multiple tips. Target pose/occlusion may change during tipping. Add Flower/other
field interactions from the rules matrix without turning motor commands into scores.

### F2. Match clock, scoring and realistic scenarios

Use a deterministic match state machine and event ledger. Implement sourced period
boundaries, timed element entry, target ownership, scoring and supported penalties.
Unit-test just-before/exactly-at/just-after boundaries and recompute score from the
ledger. Judgment-dependent officiating rules need an explicit simplified policy
and limitation; do not claim perfect referee emulation.

Run scripted multi-robot matches with pushing, blocked intake, missed shots, target
tips, changing ownership, sensor occlusion and complete reset. Publish game coverage
and unresolved approximations. Gate F requires credible full-match results before
the environment can be called game-ready. Tag geometry, mechanism and scoring steps.

## 10. Work package G — RL-ready controller environment; no training

Implement a Gymnasium wrapper only after the sensor/game contracts settle. Python
supplies controller-level commands; Java continues to own engines and subsystems.
Use a deliberately small bounded action vocabulary plus manual-drive stream, with
request ID/ack/cancel semantics and a chosen action duration/control frequency.
Do not expose raw motor control unless it is a separate explicitly requested task.

`reset(seed, options)` resets physics, Java engine/controller state, sensors, frame
histories, tracks, inventory, clocks, buffers and request IDs. `step` advances a fixed
number of Java/Python lockstep ticks, returns observation/reward/termination/truncation
and diagnostic info. Watchdog expiry is an infrastructure fault, not a policy score.
Benchmark before choosing process counts; no unbounded simulator pool.

Policy observations contain available measurements/beliefs, confidence/age, own
mechanism state and permitted match information. Ground truth/global IDs/reward-only
privileged state must not leak into the policy adapter, including its `info` use.
Keep training reward distinct from the official scorer; initially expose score
delta and documented events without speculative reward shaping.

Gate G: Gym environment checks, seeded reset equality, action bounds, scripted
policy smoke, isolated instances, timeout/close/reconnect and full-match reset tests.
No learner/policy training job is installed or started. A learned world-model updater
remains a separate future proposal requiring recorded datasets, held-out evaluation,
on-device latency measurements and a classical fallback.

## 11. Execution, review and tagging after this discussion

Use the three existing Luna/max workers. Robot owns Java/FTC, sim owns Python plants
and physics, docs owns task/evidence documentation. Robot and sim cross-review at
immutable hashes. ftc-reviewer and ftc-ball remain forbidden. Do not create extra
supervisor agents by default; goals and written evidence should reduce orchestration.

One worker goal covers one bounded work package/increment, not this whole roadmap.
The `/goal` objective points to a detailed task file and names its stopping gate.
Coordination content remains in English; no fixed message prefix is required. Codex
documents persistent goals and recommends
file references for lengthy instructions: [goal command](https://learn.chatgpt.com/docs/developer-commands?surface=cli).
No goals from this draft have been started.

Every task file must specify:

1. Pinned input commits, relevant source paths and the exact observable behavior.
2. Files the worker owns, dependencies, units, input/output contracts and defaults.
3. State transitions, cancellation/failure semantics and compatibility requirements.
4. Small numbered implementation commits; a test and Pymunk proof per working step.
5. Deterministic fixtures, scenario matrix, acceptance thresholds and artifact paths.
6. Cross-review target, finding closure rule, final hash and handoff requirements.
7. Explicit non-goals and stop conditions; no speculative expansion to the next stage.

Parallel work follows the same feature: robot implements one mechanism while sim
implements its plant from the agreed seam; docs prepares fixtures/provenance. Review
and analysis of the next increment may overlap, but implementation starts only after
the current dependency gate passes. During this planning hold, workers may be idle.

Commit + push each tested increment. After acceptance and cross-review, publish an
annotated immutable tag in all three repos, pointing to the exact compatible hashes,
and a release manifest with tests, assumptions and review disposition. Suggested
scheme: `p11a-b1-intake-v1`, `p11a-c2-shots-v1`, `p11a-engine-cplx2-v1`.
Tags are proposed names, not existing releases. Never move a published tag; fixes
receive a new checkpoint. No merge into stable and no phase-name change is implied.

Evidence labels: **unit-tested**, **sim-integrated**, **Android-built**,
**archive-derived**, **hardware-validated**. The last label stays absent until real
hardware exists. Simulator success cannot erase that limitation.

## 12. Decisions for our discussion

1. Recommended control baseline: port last season's match-used button semantics,
   retaining today's diagnostic map under another profile. Confirm whether instead
   the current buttons should remain while only actuator behavior is ported.
2. Binding hardware after Tuna's direct v2.1 correction: archive mechanism AND
   actuator counts are preserved. ONE shooter/TWO motors, ONE hood/TWO position
   servos, ONE turret/TWO CR servos; intake1, feeder1, drive4 motors.
   See hardware-profile-v0 for pair mapping and shared encoder port; physical tuning
   remains to be verified. The original review's single-actuator interpretation is wrong.
3. Recommended shooting baseline: stationary calibrated shots first; no RK4 or
   moving-shot work before that gate.
4. Recommended vision milestone: cplx3 builds observable tracks/beliefs and scans
   safely, but does not yet chase balls. This isolates world-model quality from planning.
5. Recommended physics scope: Pymunk plus a compact height-aware projectile and
   one-axis Hive model. Revisit a 3D backend only if acceptance exposes a concrete gap.

These are design decisions for discussion, not requests to approve unfinished work.
This complete roadmap and its documented tradeoffs are the current deliverable.
