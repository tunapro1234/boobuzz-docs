# Research, decisions and evidence limits

> Superseded in parts by [review 2026-09-17](../review-ftc-main-specs-2026-09-17.md);
> known issues, revise after B09. Body retained, NOT a current work order.
> Read [v2 index](README.md) and [hardware-profile-v0](../hardware-profile-v0.md).
> Hardware/name/encoder conclusions below are corrected for v2; all other far-framework choices and section5 findings remain provisional. No further E–H work before B09.

Status: DRAFT supporting the review pack, not an implementation order.
Primary sources checked 2026-09-17. Recheck version-sensitive APIs/rules at execution.
Choices below are engineering proposals for this repository, not claims that one
framework is universally best. No packages were installed and no training was run.

## Repository evidence before framework selection

Current pure Java core already has HAL, subsystem, logic and controller separation;
`IController.decide(Feedback)` is the natural policy seam. Pedro 3.0 provides the
existing drivetrain/localizer. `RobotFactory` still constructs stub mechanisms.
`WorldSnapshot` currently carries only time/pose/yaw/voltage, not a full world model.
`RequestStream` names look like velocities but currently carry normalized demands.
RealHal currently lacks the complete archived turret/hood/feeder sensor/output set.
The Python field is primarily a square/background, not a rule-complete game.

These findings justify incremental seam extensions, not replacing the layer design.
Keep Java17 core, the repo's FTC SDK12.0.0/Pedro3.0.0 and existing test frameworks
unless an actual compatibility blocker warrants a separate change. Robot's `sim`
folder is valuable as a thin runner: shared control code should remain shared.

Archive-derived behavior is useful: power-domain shooter PIDF, timed feeder,
LEFT-channel hood conversion and bounded turret control. The NEW profile uses ONE
flywheel, ONE hood servo, ONE turret CR servo and ONE intake (plus feeder). Reuse
calculations and names, not the archive's actuator count or whole scheduler.
Shooter velocity is shooterRight/RIGHT; shooterLeft independently reads turret angle.
Verify the actual28-tick/1.6-ratio settings against their contradictory old comments;
do not treat the already-resolved encoder selection as an architectural blocker.

## Choices and alternatives

| Area | Initial choice | Why / when to reconsider |
|---|---|---|
| Chassis/ground physics | Existing Pymunk | Existing integration; reconsider only if a required contact test cannot be represented |
| Airborne balls | Small height-aware flight/contact model | Needed above a 2D floor; analytical gravity first, no RK4 project |
| Hive | One rotational coordinate with load torque and damping | Minimum explanatory mechanics; bracket unmeasured constants |
| Shots | Validated lookup + linear interpolation | Predictable bounded behavior; archived polynomial only if evidence beats it |
| Vision | Limelight raw detector adapter + simulated measurements | Tests perception integration, not an invented image renderer |
| Tracking | Gated association + alpha-beta first | Small track count; upgrade to Kalman/Hungarian only on failing fixtures |
| Range fusion | Conservative geometry/time association | Avoid falsely precise correlated updates; no incidental pose-SLAM work |
| Environment | Optional Gymnasium process wrapper | Standard contract, unchanged Java engine path |
| First learner (future) | SB3 PPO, small MLP, Box(3) drive | Simple continuous-control baseline and deployable actor |
| Demonstrations | Own teleop logs; BC-ready format | Known action/sensor semantics; xRC only after data feasibility proof |
| Inference | Evaluate ORT Android; narrow Java MLP fallback | Verify actual Hub compatibility and cost before adding native dependency |

### Pymunk and simulation scope

Pymunk is a 2D rigid-body library; it does not itself supply correct vertical ball
flight or game scoring. That makes a small explicit height-aware extension a better
initial fit than pretending floor circles can validate elevated shots. Existing
PyBullet support is preserved but feature expansion is outside the critical path.
[Pymunk overview](https://www.pymunk.org/en/latest/overview.html).

Our physics validation proposal uses analytic fixtures, dt convergence, conservation
and sensitivity brackets. A simulator fit to the same inverse solver being tested
would be a circular oracle. Missing physical measurements remain uncertainty, not
permission to call an arbitrary constant realistic.

### Limelight and tracking

Limelight's FTC API exposes result/detector information; actual SDK signatures,
pipeline contents, timestamp clock and camera calibration need local verification.
It does not establish that a suitable pollen/robot detector already exists.
[FTC integration documentation](https://docs.limelightvision.io/docs/docs-limelight/apis/ftc-programming).

SORT demonstrates a useful lightweight association/filtering approach, but does not
by itself solve our capture-time field transform, uncertainty or pollen occlusion.
Use it as an alternative-method reference, not a requirement to import a tracker
framework. Our alpha-beta/gated baseline is intentionally smaller.
[Original SORT paper](https://arxiv.org/abs/1602.00763).

### Game and match deployment

The official manual's control/network rules make a laptop-driven development socket
an unsuitable assumed match deployment path. Plan for onboard inference and keep
debug services out of the competition profile; recheck exact current compliance
before field use. This is a design constraint, not an inspection ruling.
[BIOBUZZ manual, R701–R704](https://ftc-resources.firstinspires.org/ftc/archive/2027/game/cm-html/BIOBUZZ%20Competition%20Manual%20-%20V1.htm).

The full rule-to-test matrix belongs in F. Pollen-only is our robot strategy, not a
change to the game. An opponent's nectar and field-mechanism state still matter.

### Gymnasium, PPO and model complexity

Gymnasium's distinction between terminal task states and external truncation affects
future bootstrapping. Match end, post-clock settlement and simulator failure must
not be conflated. [Time-limit guidance](https://gymnasium.farama.org/tutorials/gymnasium_basics/handling_time_limits/).

SB3 PPO supports continuous Box actions and offers a straightforward MLP baseline;
its docs discuss frame stacking as a simple alternative before recurrent policies.
The live master docs may be prerelease, so H pins a compatible release separately.
[PPO reference](https://stable-baselines3.readthedocs.io/en/master/modules/ppo.html).

Our 292-field proposal is derived from robot-available beliefs, not from a benchmark
claim. Four-frame history and [64,64] networks are initial candidates; observations
are kept fixed/versioned before recording data. No algorithm can make unobservable
exact target inventory appear for free. Safety stays outside the learned policy.

### Rewards, demonstrations and transfer

Potential shaping is principled only under its formal assumptions. Start full-game
evaluation with official score difference, then add separately named experiments
if sparse credit assignment is actually a problem.
[Ng, Harada and Russell](https://ai.stanford.edu/~ang/papers/shaping-icml99.pdf).

BC consumes expert observation/action pairs; DAgger needs expert involvement on
policy-visited states. Both would be training and remain prohibited now.
[BC](https://imitation.readthedocs.io/en/latest/algorithms/bc.html),
[DAgger](https://imitation.readthedocs.io/en/latest/algorithms/dagger.html).

xRC's official site supplies simulator downloads. A compatible BIOBUZZ dataset,
public synchronized observation/action export and reuse rights were NOT verified.
That is an open feasibility question, not a finding that no such API exists.
[Official downloads](https://xrcsimulator.org/downloads/).

ONNX Runtime provides Android deployment guidance; that alone does not prove a
particular package supports our FTC minSDK/ABI or meets Control Hub timing.
Benchmark/check compatibility first. A restricted Java evaluator may be simpler for
this one small actor, but requires strict parity tests and no generic ML runtime.
[Official Android guide](https://onnxruntime.ai/docs/tutorials/mobile/deploy-android.html).

## Open evidence, with bounded responses

| Unknown | Needed evidence | Safe progress while unresolved |
|---|---|---|
| Physical encoder scaling | Old code resolves shooterRight speed vs shooterLeft turret; verify28 ticks/rev and1.6 wheel ratio physically | Separate known input names; no invented encoder conflict or physical calibration claim |
| Pollen launch calibration | Ball-identified measurements with units/uncertainty | Synthetic software fixtures and explicit uncalibrated label |
| Final intake/hood/turret geometry | Mechanism drawing/measurement | Versioned archive-derived profile, reject unproven reachability |
| Camera detector/pipeline | Actual configuration and representative frames | Adapter fakes/sim frames; no claim of deployed perception |
| Range model/placement | Chosen hardware and mounts | Configurable labeled fixture; no invented final BOM |
| Hive damping/tip physics | Field CAD, component data or real measurements | Parameter brackets and documented surrogate fidelity |
| xRC data availability | Official export/API, aligned sample, permission | Own telemetry format and human replay |
| Onboard inference budget | Control Hub timing/thermal test | Desktop parity only; no physical performance claim |

Do not remove a proven capability to satisfy an imagined future learner. Escalate
only when an unknown blocks truthful acceptance, safety or a material scope choice;
continue independent software fixtures where useful and clearly labeled.
