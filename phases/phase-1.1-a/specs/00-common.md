# Common rules v2 — preserve the system, keep process small

Status: DRAFT v2, not dispatched. Read [hardware-profile-v0](../hardware-profile-v0.md)
and [binding review](../review-ftc-main-specs-2026-09-17.md). These rules supersede
conflicting v1/far-draft process, topology and engine-numbering statements.

## Exact path shorthand

- R = `/home/shared/projects/boobuzz/robot-code`; S = sibling `re-cock-nize`; D = sibling `docs`.
- J = R/`TeamCode/core/src/main/java/boobuzz/core`; JT = R/`TeamCode/core/src/test/java/boobuzz/core`.
- H = R/`TeamCode/src/main/java/org/firstinspires/ftc/teamcode/hal`.
- SJ = R/`sim/src/main/java/boobuzz/sim`; SJT = R/`sim/src/test/java/boobuzz/sim`.
- OLD = `/home/shared/projects/archive/ftc/de-cock/robot-code/TeamCode/src/main/java/org/firstinspires/ftc/teamcode`.

Keep existing layers/versions. HAL binds devices; subsystems own feedback loops;
logic coordinates; controller emits intent. R/sim transports the SAME core. S owns
physical truth/plants, never a duplicate Java PID or shot coordinator.

## Actual contracts

`J/RobotLoop.java`: `hal.read -> engine.sense -> controller.decide -> engine.act ->
hal.write`. Feedback is one tick delayed. Pedro updates inside PedroDrive, not a
second loop call. Later estimation lives inside sense, not an invented sixth stage.
B01 adds `J/contract/ActionValidator.java`, called INSIDE both HAL writes before any
device/network write; retain final clamping as defense in depth.

Time stays integer **milliseconds**, `t_ms`, `dt_ms`, `IHal.now()`. Java remains TCP
client/clock owner; Python advances only on step. Baseline20 ms lockstep. Existing
coordinates stay inches/radians, +forward/+left/CCW. RequestStream remains normalized
manual demand, not physical velocity. No microsecond migration.

Keep `RequestStatus.State {ACTIVE,DONE,FAILED,REJECTED}`. No CANCELLED/FAULTED enum.
Preserve actual cancellation encoding: `REJECTED`, note `cancelled` (engine-switch
note `engine switch`). Device/timeout failure is `FAILED` with reason. At most one
terminal result per accepted request. No new generic epoch framework in B; clear
pending requests/events on reset so no stale pulse resumes.

Proto1 currently zero-fills omitted servo commands. B01.0 OWNS its breaking change
to absent-position-servo-means-hold under proto2. Do not pretend that behavior exists
already. DC/CR omission still means zero. RobotConstants is configuration truth;
S/`sim/mechanism.py` parses Java, not YAML or a transmitted constants blob. A02 owns
mass parsing; B01 owns device names/declarations/parser cases, one declaration/line.

## Protocol/ADR route — explicitly owned before code

A02 and B01 use ONE `D/phases/phase-1.1-a/adr-device-seam-v2.md`, documenting old/new
semantics, names, units and paired fixtures. Before implementing the affected seam,
the ftc-main/orchestrator owner must approve/update binding `D/protokol.md`. B07
appends analog semantics there before its paired change. Today's spec-only revision
does NOT edit protokol.md or phase-1.1/design-spec.md. Future seam authorization
must include the protocol amendment; no undocumented bypass of protected history.

Use exact ready.proto and per-type name lists, not an imaginary capabilities set.
Unsupported proto/name mismatch fails before enabling outputs. No silent proto1
fallback for mechanism profiles. Future changes are explicitly reserved, NOT B scope:

| Later entry | Required owned seam before code |
|---|---|
| Vision-A/D | ADR + protokol/version update; state.vision[], RobotState typed frames; H/Hardware + RealHal Limelight3A; SJ/SimHal decode; constants/parser and paired fixture |
| Range/E | Same route for state.range[], typed range observations, distance HardwareMap binding/mount declarations/parser and paired fixture |

IHal.now/read/write stays unchanged. Async sensor data is batched inside RobotState
on read, not out-of-band callbacks into core. Capture metadata is ms. Later camera
fixtures use25 Hz on20 ms ticks and independent seeded sensor streams. No camera,
range or unused digital channels in B; analog is introduced only at B07.

## Engines compose, never four copies

**cplxN = accepted cplx(N-1) configuration + ONE pluggable module.** Reuse
`J/logic/cplx1/{CplxEngine1,MotionLogic,ShooterLogic,TurretLogic}.java` and
`J/subsystem/Subsystems.java`. B08 retains one coordinator and adds only needed
small helpers such as `J/logic/shot/ShotPreset.java`.

At cplx2, add a narrow `J/logic/EngineModule.java` hook to configure that SAME
coordinator with ShotSolutionModule; later ImageAimModule, WorldModule, RangeAssistModule
are additions. Modules supply intents/solutions, not HAL writes or independent
Subsystems.update calls. No copied CplxEngine2/3/4 state machines or nested double
updates. Missing module retains predecessor behavior. Do not build empty future
module skeletons or a general plugin framework in A/B.

A05 owns `J/logic/EngineRegistry.java`: index0 direct, index1 cplx1, alias
cplx_engine_1. Reserve2 cplx2,3 Vision-A/cplx3,4 Vision-B/cplx4,5 range/cplx5;
unimplemented selections reject. RobotFactory and numeric SWITCH_ENGINE use the
same registry. JT/RobotFactoryTest.java and JT/RobotLoopSwitchTest.java pin order,
alias and replay semantics; adding an engine must not renumber old bindings.

## Safe behavior

STOP/fault > explicit cancel/manual recovery > shot > optional assist. One output
owner/device. DC/CR STOP zeroes power; proto2 position servo holds last explicit
setpoint. No previous setpoint = no guessed move. Stow is explicit, not STOP.
Switch tick's existing RobotAction.zero becomes power-zero/servo-hold in proto2.
Commanded hood angle is not measurement; pulse completion is not confirmed score.
Real inventory is unsensed in B. Missing required measurements cannot look healthy.

Ports: sim transport5555, tap5600, controller5601. Real profile already uses
REAL_DEBUG_TAP_PORT=0; preserve it. No development services/learning dependency in
normal robot deployment. Names allow old configuration reuse, not mechanical proof.

## Lean acceptance and publication

R owns Java, S Python, D evidence. After approval send one bounded task with exact
entry hashes/owned paths/exit; messages start `Always write in English`. No ball or
reviewer launch, training or implementation during this review. Workers may stay idle.

Commit/push each working increment, report hash. Focused tests + affected chapter
e2e; keep existing suites green, but test counts are NOT the acceptance criterion.
Cross-review ONLY R/S seam work: A02 constants/parser, A03 harness, B01 devices,
B02 geometry/capture, B03 transfer, B05 feedback, B06 servo path, B07 sensors/aim,
B08 integrated release. Pure-Java map/cancel fixes do not need a ritual cross-review.

Use ONE evidence file per chapter: `D/phases/phase-1.1-a/evidence-A.md` / `evidence-B.md`:
commands, R/S hashes, e2e outcome/trace links, concise seam-review notes, limitations.
No per-task evidence folders, manifest, acceptance.json or review.md. Tags/manifests
ONLY A05 baseline, B09 cplx1, then engine checkpoints: `p11a-baseline-v1`,
`p11a-engine-cplx1-v1`. Checkpoint manifest is a section in chapter evidence; R/S
hashes are pinned there and D tag identifies its doc commit, avoiding self-hashes.
No draft tag. Do not move published tags.

Resolve installed JDK/venv; no assumed privileged paths or package upgrades. R:
`./gradlew :core:test :sim:test :sim:installDist`; HAL/profile changes also
`:TeamCode:assembleDebug`. S: `python -m unittest discover -s tests` in its venv.
A03 assigns a NEW e2e runner; later tasks extend it. Only a few fixed scenarios gate
an engine. Physical direction/encoder/mechanical/tuning checks remain separate.

Replan for concrete safety/contract/physics evidence, not preference churn; record
the smallest alternative in chapter evidence. Material scope changes need Tuna.
