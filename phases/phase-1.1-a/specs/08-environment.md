# G — controller-level Gymnasium environment, no training

Status: DRAFT, not dispatched. Entry: F04 game-ready gate and stable cplx engines.
Apply [common gates](00-common.md). This creates an environment, not a learner.

## G01 — small driving action and explicit authority

R adds a policy/replay controller adapter at `IController.decide(Feedback)`. Python
transport is a development adapter only; onboard inference will use the identical
Java observation/action transforms. Engines/subsystems remain authoritative.

Proposed `drive-v1` action is Box(3), finite normalized values [-1,1]: forward,
left-strafe, counterclockwise turn in ROBOT frame. These are the existing normalized
drive demands, not raw individual motor powers and not physical velocity targets.
Apply the same mecanum mixing/saturation path as human drive. Avoid a new velocity
controller until a measured need justifies a separate explicit command type.
Policy actions bypass joystick deadband only by a documented shared transform;
human replay fixtures specify which transform produced the stored intended action.

Policy rate starts at 10 Hz, control/physics 50 Hz: hold one driving action for five
20 ms ticks. Engine safety and human takeover run every control tick. Sequence/epoch
and bounded expiry prevent old actions after reset. Missing/nonfinite/stale policy
output zeros drive and latches policy fault; no reuse forever. Development socket
watchdog uses wall time separately from logical action expiry.

Authority is HUMAN or POLICY with explicit enable and takeover. Meaningful manual
stick motion or cancel takes control within one tick; do not auto-rearm policy when
sticks return to zero. STOP outranks both. Driver mechanism inputs stay available.
When collecting demonstrations, log intent BEFORE safety limiting and effective
output AFTER it, plus source and intervention reason.

No policy-controlled RPM, PID gains, turret raw power or engine switching. First
task is AI driving during teleop while driver/engine handles intake/shooting. In sim,
a deterministic co-operator script issues mechanism requests using the SAME public
feedback as a driver/robot could obtain, not privileged ball positions. Optional
operator-selected objective/target is an observed mission hint, never a hidden
reward-only target. Later full strategy needs a separately versioned action schema.

Tests: +/- axis signs, diagonal saturation, both alliances without double rotation,
five-tick hold, expiry, malformed action, takeover mid-hold, disconnect and reset.
Exit: a hard-coded (not learned) controller drives an entire legal scenario through
the same seam as a future policy; human takeover always works.

## G02 — fixed, auditable observation schema

R builds observation exclusively from current public feedback/world beliefs. S
receives that serialized observation; it must not silently enrich it from truth.
Version/hash the schema, normalization constants and field order. Use a flat float32
vector for first MLP, plus a documented structured view for debugging. No pixels.

Proposed per-frame `obs-v1` layout (freeze after capability audit, before recording):

| Block | Shape | Fields/order |
|---|---|---|
| Self | 32 | Enumerated below |
| Self validity | 32 | One validity bit per self field |
| Pollen tracks | 8 x 9 | present, relative x/y, relative vx/vy, confidence, age, uncertainty radius, currently visible |
| Other robots | 3 x 10 | present, relative x/y, relative vx/vy, radius estimate, confidence, age, uncertainty, currently visible |
| Range mounts | 8 x 5 | configured, valid, normalized range, age, uncertainty |
| Target beliefs | 8 x 10 | configured, relative x/y, height, load lower/upper estimate, confidence, age, owner belief, owner confidence |
| Mission hint | 6 | valid, relative goal x/y, desired-heading sin/cos, heading-valid |

Total 292 floats/frame. Pollen rows are deterministic nearest-first using estimated
range then local track ID; no ID encoded into policy features. Robot rows similarly
ordered. Range/target rows are fixed profile IDs known at deployment; reject a
profile exceeding schema capacity rather than silently losing required coverage.
Targets without count evidence have low confidence/unknown bounds, not exact zero.
No nectar collection row: external nectar can appear as noncollectable obstacle/
target uncertainty through existing observations; don't grant perfect nectar truth.

Self indices 0–31:
`remaining-time, auto-active, transition-active, teleop-active, estimated-x,
estimated-y, sin-heading, cos-heading, body-vx, body-vy, yaw-rate, pose-age,
pose-confidence, voltage, turret-angle, turret-rate, flywheel-rpm, flywheel-target,
shooter-ready, hood-command, hood-settled-estimate, inventory-estimate,
inventory-confidence, intake-direction, feeder-busy, shot-active, scan-active,
drive-limited, fault-active, previous-forward, previous-strafe, previous-turn`.

Normalize distances by field width, speeds by declared profile maxima, time ages by
their expiry horizon, remaining time by task horizon, angles by sin/cos or explicit
mechanical range, RPM by profile max, counts by capacity/belief cap. Clamp only the
encoded feature, retain out-of-range diagnostic flag; reject NaN at source. Missing
values encode zero with invalid/present mask. Do not replace absent pose with truth.
Telemetry availability determines validity: official live score/opponent inventory
are NOT included unless an equally legal real source is established later.

Optional stack of four frames produces 1,168 floats; reset pads with the initial
frame and explicit zero history age semantics. Do not introduce LSTM yet. Evaluate
whether partial observation actually needs history using scripted smoke cases.

Tests: exact dimension/index/units, missing devices, object reorder, capacity overflow,
rotation/frame transforms, schema mismatch, initial stack reset and reproducible
normalization. Leak test: two hidden truths with identical permitted observations
must produce identical policy vector and co-operator choices. Private truth may
exist only in separately namespaced evaluator output never consumed by the policy.

## G03 — deterministic reset/step and terminal semantics

S exposes Gymnasium `reset(seed, options)` and `step(action)` around the actual
Java/Pymunk loop. Reset physics, objects/game ledger, RNG streams, sensors/delivery
queues, Java controllers/engines/subsystems, pose history, world tracks, inventory
belief, request IDs/epoch, action hold and observation stack. Await explicit Java
reset acknowledgement before returning the initial observation.

One step advances five synchronized ticks, or fewer if the task reaches a terminal
boundary. Return actual elapsed logical time. Seed hierarchy independently addresses
physics, sensor noise, opponent scripts and scenario generation. No wall-clock-based
seed or reward. Changing rendering must not change rollout behavior.

Actual task conclusion is `terminated=True`; an external diagnostic/time-budget cut
is `truncated=True`. Include task time remaining in observation for finite-horizon
tasks. A normal match horizon is not arbitrarily labeled truncation. Scoring may
require a bounded post-clock settle phase with commands disabled before final return;
model this explicitly from F03. A settle watchdog/infrastructure failure is an error,
not a legitimate policy terminal reward. Gymnasium explains this distinction in
[its time-limit guidance](https://gymnasium.farama.org/tutorials/gymnasium_basics/handling_time_limits/).

Provide two task registrations: a bounded navigation smoke fixture and full teleop
driving with scripted/public-feedback mechanism co-operator. Teleop initialization
comes from valid rule-consistent snapshots or scripted AUTO, never an impossible
random pile inside a mechanism. Each registration declares conditions/reward version.
Full-match evaluation remains available without implying learned AUTO behavior.

Tests: Gym checker; repeat reset/rollout equality; reset after each subsystem state;
terminal/truncated bootstrap fixtures; illegal step-after-done; close idempotence;
process crash, timeout, bad frame and reconnect. Infrastructure errors raise/report
explicitly; do not train future policies to exploit process crashes as reward.

## G04 — bounded parallel instances and reproducible evaluation

S supports one instance first, then two independent instances with isolated ports,
processes, files and seeds. No shared mutable globals. Measure tick throughput and
memory before increasing count; this task starts no large worker pool. Pin compatible
Python/Gym dependencies in an optional environment. Current sim uses Python 3.14;
verify available ML wheels later rather than upgrading/downgrading the simulator
globally. A supported separate Python environment can use the same process protocol.

Provide zero-action, simple waypoint and recorded-human replay policies for checks.
These are scripts, not trained models. Evaluate wall/robot collisions, valid score,
illegal events, intervention/fault count, observation freshness and goal progress,
not only a scalar reward. No hidden oracle planning in the public-feedback baseline.
Exit: two instances run 20 short episodes without cross-talk; full match smoke and
shutdown leave no live child processes; headless/viewer results agree.

## G05 — environment release, still no learning

Deliver API/schema docs, normalization/action golden fixtures, seed/reset contract,
rule/physics limitations, resource benchmark, public baseline rollouts and model-free
tests. Existing robot builds require neither Gym, PyTorch nor a Python runtime.
Confirm no `.learn`, optimizer step, BC fit, online adaptation or training job has
been invoked. Tag `p11a-g05-env-v1` after review. This means environment-ready within
the published fidelity envelope, not a trained or competition-approved AI driver.
