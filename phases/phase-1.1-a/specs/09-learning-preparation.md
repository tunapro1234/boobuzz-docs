# H — model, rewards, demonstrations and deployment preparation

Status: DRAFT, not dispatched. Entry: G05. **No training, including BC/DAgger, no
optimizer steps, no weight fitting, no background jobs.** These tasks prepare inert
configuration and tests only. Apply [common gates](00-common.md).

## H01 — algorithm/model decision and inert configuration

Proposed first learner, if separately authorized later: Stable-Baselines3 PPO with
PyTorch, MLP policy, continuous Box(3) drive action. SB3 supports this action space;
start with a simple stacked-observation MLP before recurrent policies.
[Official PPO documentation](https://stable-baselines3.readthedocs.io/en/master/modules/ppo.html).

Proposed starting configuration, NOT optimized or a performance promise:

| Setting | Proposed value | Reason/constraint |
|---|---|---|
| Actor and critic hidden sizes | separate [64,64], Tanh | Small inspectable onboard actor; critic never deployed |
| Observation history | 4 x obs-v1 (1,168 floats) | Short history for velocity/latency, schema-fixed |
| Action | 3 diagonal-Gaussian outputs during future learning; deterministic mean/clipped action at deployment | Same normalized drive contract |
| Policy/control rates | 10/50 Hz | Mechanism/safety loop remains faster |
| Learning rate | 0.0003 | Initial candidate; later compare deliberately |
| Rollout length | 2,048 policy steps per environment | Explicit time horizon/resource cost |
| Minibatch / epochs | 256 / 10 | Must divide total rollout batch |
| Discount / GAE lambda | 0.999 / 0.95 | Discount horizon ~100 s at 10 Hz; revisit sparse credit assignment with evidence |
| Clip / entropy / value coefficient | 0.2 / 0.0 / 0.5 | Simple initial baseline, not claimed optimal |
| Gradient norm cap | 0.5 | Bounded future updates |
| Initial environment count | 1; benchmark-gated increase | No unbounded resource usage |
| Running normalization | off initially | Fixed audited feature scaling; avoid train/deploy mismatch |

Pin a released compatible dependency set after a wheel/build check; documentation
`master` may be prerelease and is not a version-selection instruction. Don't upgrade
FTC/Pedro/sim dependencies as collateral work. Save a schema-validated inert config
with `training_authorized: false`; no auto-run launcher. Validation imports no training
entrypoint. A later learning authorization must specify budget, scenarios and eval gate.

Alternatives: SAC adds replay/offline considerations we do not need for the first
reliable baseline; recurrent PPO adds state/reset/deployment complexity. Evaluate
them only if a reproducible baseline failure supports the change. No claim PPO is
universally best. Deep perception/world models are not prerequisites.

## H02 — reward definitions and exploit tests (no fitting)

Default full-teleop reward proposal:
`r = 0.05 * [(our_score - their_score)_next - (our_score - their_score)_previous]`.
Use the F03 official-score ledger, including correctly attributed fouls, and finalize
end-state components once. This preserves interpretable units (20 points -> 1 reward)
without adding a second arbitrary score. No separate foul penalty double-counting.

| Reward component | Default weight | Decision |
|---|---|---|
| Official score-difference delta | 0.05 | Primary task objective |
| Terminal win bonus | 0 | Do not mix objectives before a baseline |
| Pickup/feed/shoot command bonus | 0 | Prevent command spam and pickup/release farming |
| Generic contact penalty | 0 | Some contact is legitimate; hard limits/rules handle safety |
| Per-step time/energy penalty | 0 | Do not silently change competition objective |
| Potential-based progress | 0 | Optional separate diagnostic navigation profile below |

For a separately named fixed-goal navigation diagnostic ONLY, propose goal reached
reward +1 and potential shaping weight 0.1 with `Phi=-clip(distance/field_width,0,1)`
and `gamma*Phi(next)-Phi(current)`, terminal potential zero. Discount matches config.
This is not the full-game reward and cannot be compared as if it were. Fixed task
goal is part of observation; changing goals requires a new task/state definition.
Potential-based shaping has formal conditions; do not promise policy invariance for
arbitrary moving targets or partially observed multi-agent play.
[Original shaping paper](https://ai.stanford.edu/~ang/papers/shaping-icml99.pdf).

Tests: sum of undiscounted score-delta rewards equals 0.05 times final-minus-initial
score difference; repeated event/pulse yields no duplicate reward; remove/reinsert
occupancy cannot create net points; early illegal score keeps its correct penalty;
reset/final settlement is not paid twice; no score from unseen command intents.
Add exploit scripts (spin, idle, wall push, feed empty, capture/release loop, timeout).
Private truth can evaluate reward but must not leak through the observation adapter.
Log each reward component independently for later audit.

## H03 — trustworthy demonstration data, xRC optional

First dependable dataset source is our own timestamped human teleop/replay through
G01. Define episode format: schema/profile/rules hashes, seed, timestamps, observation
before action, intended action, effective action, authority/intervention, mechanism
requests/status, reward components, termination and sensor validity. Record latency;
align the action with the observation the driver actually saw. No future-frame labels.

Episodes with safety overrides retain both actions; BC labels use explicit expert
intent only when appropriate, not automatically the post-limiter action. Label bad
demonstrations and intentional recovery; preserve provenance, consent and licenses.
Split by whole session/driver/scenario/seed, never random adjacent frames. Proposed
split 70/15/15 train/validation/test with fixed manifest; grouping outranks exact ratios.
Collecting new human demonstrations requires a driver; do not fabricate them from
an oracle and call them human. Existing recordings can be converted read-only.

BC requires matched observation/action examples, not just match video.
[imitation BC documentation](https://imitation.readthedocs.io/en/latest/algorithms/bc.html).
DAgger is a later option only with an available expert who can label states visited
by the policy; it is not a free offline substitute.
[DAgger documentation](https://imitation.readthedocs.io/en/latest/algorithms/dagger.html).

xRC feasibility subtask is research/read-only first: confirm compatible game/version,
supported telemetry and input/action export, clock alignment, frame/units, semantics,
license/permission and whether observations are realistically available to our robot.
The official [xRC downloads page](https://xrcsimulator.org/downloads/) establishes
distribution, not a verified dataset API or BIOBUZZ compatibility. Do not claim either
without evidence. Video-only, mismatched games or privileged truth are not drop-in BC
data. If unsuitable, document no-go and continue with our own simulator recordings.
No scraping restricted sources, driving another application or downloads beyond
agreed scope. Exit: dataset schema/validator, sample synthetic FORMAT fixture clearly
labeled, conversion tests, provenance checklist; no training or claimed expert dataset.

## H04 — onboard inference feasibility and parity

R defines minimal `DrivePolicy` interface and a fault-safe controller adapter, not a
new engine. Evaluate ONNX Runtime Android against the ACTUAL FTC minSDK, ABI, memory
and build constraints. Keep dependency only in TeamCode adapter, never in pure core.
[Official Android deployment guidance](https://onnxruntime.ai/docs/tutorials/mobile/deploy-android.html).

For this tiny fixed dense/Tanh actor, a narrow pure-Java forward evaluator is a
fallback if ORT packaging/runtime costs dominate. It must support only the explicit
operations/schema; do not write a general neural-network framework. Compare binary
size, cold start, allocations and output parity before choosing. Record an ADR.
No camera coprocessor repurposed for unrestricted control inference without a rules
check. No laptop/cloud command loop in the competition profile.

Use deterministic synthetic weights solely for numerical/transport testing; label
them non-driving/nontrained and do not expose a runnable competition policy by default.
Python-reference vs Java/Android action error target <=1e-5 over bounded fixtures;
test normalization, clipping, malformed weights/schema and model checksum. Critic
is not shipped. Manifest contains schema, action, feature normalization and profile
compatibility. No arbitrary runtime model deserialization from the network.

Physical target: p95 inference <=10 ms at 10 Hz without breaking 20 ms safety/control
ticks; this requires a real Control Hub measurement later. Desktop timings do not
prove it. Inference runs off the critical hardware-write path with bounded fresh
results, or synchronously only if measured worst-case budget permits. Late/NaN output
disables policy; human takeover works within one control tick. Do not enable an
untrained test model to drive physical motors.

## H05 — readiness dossier and optional future research, then STOP

Deliver inert PPO/model/reward configs, schema/dataset validators, exploit tests,
onboard feasibility ADR/parity report, reproducible nonlearned baselines and a
training-authorization checklist. Report unmet physical/perception/data requirements.
Tag preparation checkpoint only after review. Explicit end condition: no model was
trained, no optimizer invoked, no future training process scheduled.

Possible later learned observation-to-world updater requires a separate proposal:
real/sim dataset provenance, classical D/E baseline, calibrated uncertainty, held-out
sensor/scene splits, out-of-distribution tests, bounded onboard latency and classical
fallback. First learn a narrowly measurable correction/association if justified,
not an opaque replacement for physics, safety and the entire world model.

Before any future training: Tuna approves objective, compute/time budget, dataset,
action/reward versions, held-out evaluation and stop rules. Before policy deployment:
rule compliance, physical controls/sensors/calibration, interference/thermal tests,
operator practice and manual takeover are independently accepted. Gall's law remains
the rule: the proven robot must still operate with the policy completely removed.
