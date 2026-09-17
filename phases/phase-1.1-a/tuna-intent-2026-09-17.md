# Tuna's direction — 2026-09-17

Status: English distillation of Tuna's messages, followed by a planning hold.
Read this after compaction, before resuming work. The current detailed discussion
draft is [the spec pack](specs/README.md), expanding [roadmap-v1.md](roadmap-v1.md).
Both are proposals, not execution orders.

## Latest instruction: plan first

Before distributing the expanded requirements to workers, ftc-main-cx must personally
prepare a detailed roadmap: implementation steps, framework choices, dependencies,
verification and tradeoffs. Show it to Tuna and discuss it together. Do not start
new implementation goals from this roadmap before that discussion.

Existing workers may finish their already-running test/report/commit checkpoint;
no new implementation, pre-chained work or `/goal` assignment is authorized during
this planning hold. Earlier keep-workers-busy instructions do not override this hold.

### Latest refinements (also binding after compaction)

- Write worker-ready detail for every substep: implementation behavior, framework
  choices, dependencies, failure cases and measurable completion. Research the
  choices. Give the specs to Tuna first; do not dispatch them before discussion.
- Gall's law is central: grow from a working simple system. Preserve the current
  layer structure. Each released engine must offer a complete useful operator
  workflow without requiring the last engine or RL. Keep earlier engines working.
- Our planned intake takes only small POLLEN, not NECTAR. Single-target collection
  simplifies mechanisms/detection; it does not remove nectar from field physics,
  interference, ownership or scoring. Do not add a nectar collection workflow.
- The RL north star is AI driving during TELEOP. Model architecture/reward weights
  and imitation-learning data feasibility may be prepared AFTER the environment,
  but no model training of any kind may start without a new explicit instruction.
- Prefer simple justified methods, and adjust the plan for serious evidence/blockers
  rather than either rigidly following a broken plan or constantly changing it.
- Tuna separately authorized telling docs to record the working organization in the
  future control document: user-named Astra/Fable orchestrator role over Luna Max
  robot/sim/docs workers. This documentation-only note is the sole new delegation
  during the planning hold, not approval to execute these specs.
- After a BP send, check the recipient screen. Tuna explicitly permits pressing
  Enter when a known intended message is visibly stuck unsubmitted. Do not resend
  duplicates, clear unrelated input or infer execution approval from that permission.

## Meaning of phase-1.1-a

- Remain on `dev-phase-1.1-a` and keep task/review artifacts in this directory.
- The name records the branch taken when Tuna skipped a planned review and let an
  agent continue. It does not freeze the feature scope to the old Phase 1.1 spec.
- Historical `protokol.md` and `phase-1.1/design-spec.md` remain untouched. Proposed
  new contracts and decisions belong in new, explicitly versioned documents here.
- Progress in small, understandable pieces; a large speculative rewrite is unwanted.

## Priority and intended behavior

0. First prove the current robot actually works in the simulator.
1. Develop the subsystems using last season's robot code and calibration evidence.
2. Develop reliable shooting and ballistic calculations before scanning or vision.
3. Add one turret-mounted Limelight, bounded scanning and a useful world model.
4. Add chassis distance sensors and then their observation/fusion behavior.
5. Later complete faithful game/field simulation and an RL-ready environment.

There is no physical robot available. Preserve the actual behavior of last season's
mecanum, turret, shooter and intake as closely as practical: a controller button
should produce the corresponding actuator behavior, including mechanism timing.
Study subsystem complexity and retain useful behavior without copying the old
entanglement between device code, subsystem state and higher-level decisions.

Each meaningful capability should leave a selectable engine behind. `cplx1` should
be the lowest-risk working engine; progressively more complex engines must retain
a fallback to earlier working behavior. Fixes do not require a new engine per commit.

## Shooting, perception and world state

- Favor last season's useful shooting/calibration methods. Focus on automation;
  do not revive an RK4 research project or activate ball-auto-istic's agent.
- A single Limelight sits on the turret. When not shooting, look at a chosen field
  region, settle and detect, then look elsewhere. Continuous spinning is not the goal.
- Track balls and robots, remember where objects were observed and estimate how many
  balls are in the places being shot into. Use that knowledge for sensible transitions
  between scanning and shooting, and eventually collection/other behavior.
- Include a distinct engine that uses vision to build the world model while keeping
  its control behavior simple and understandable.
- Simulate detections and sensor limitations, not image processing: noise, latency,
  missed detections and degraded observations during fast motion are useful.
- Chassis range and Limelight observations eventually need association/fusion.
  Their measurements must not be treated as magically labeled ground truth.
- A learned observation-to-world-model component is a possible future option, not
  a requirement to begin with AI or train a model now.

## Simulator, game and RL

- Keep simulator and robot development synchronized at every step.
- Pymunk is sufficient as the primary backend; spending effort on PyBullet is not
  requested. Balls still need plausible physical motion and interaction.
- The central field mechanisms tip when enough balls arrive. Correct field mechanics,
  match timing and scoring are essential before claiming an RL-ready game environment.
  This difficult completeness work comes late, after the robot capabilities above.
- The final intention is RL at the controller layer. Preparing the environment is
  permitted later. Starting training is explicitly prohibited.

## Working style and publication

- All new writing and worker messages are English.
- Keep ftc-main-cx's token/workload low; use Luna/max workers with detailed task files
  and bounded persistent `/goal` assignments after the roadmap discussion.
- Commit and push every tested working increment; report hashes.
- Add a tag after each accepted meaningful step and engine checkpoint. This replaces
  the earlier no-tags restriction; do not tag unreviewed or unfinished work.
- Cross-review robot and simulator work; do not launch ftc-reviewer unless Tuna says so.
- Do not give ball-auto-istic/ftc-ball tasks.
- Preserve these instructions and the roadmap in Markdown for future sessions.
