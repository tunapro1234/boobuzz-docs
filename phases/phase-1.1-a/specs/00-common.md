# Common implementation contract and acceptance gates

Status: DRAFT for Tuna review. Not a worker assignment. Applies to A01–H05.

## 1. Ownership and unchanged architecture

Repository aliases: R = `robot-code`, S = `re-cock-nize`, D = `docs` under the
BOOBUZZ workspace. Robot worker owns R; sim worker owns S; docs worker owns D.
Cross-review is read-only at immutable commits. One writer per file/repository
checkpoint; never stage another worker's unrelated changes.

Keep these responsibilities:

- `TeamCode/core/.../contract`: typed snapshots, requests, feedback and observations.
- `.../hal`: SDK-free interfaces and device/geometry/calibration descriptions.
- `.../subsystem`: mechanism feedback loops and small state machines.
- `.../logic`: command arbitration, shot coordination and engine decisions.
- `.../controller`: human, scripted, replay and eventual policy intent.
- `TeamCode/src/.../hal`: actual FTC devices; thin OpModes select a profile/engine.
- R's `sim` module: transport/runner using exactly the same Java core. Keep it;
  remove duplicated control logic if found, not this useful adapter boundary.
- S: plants, physical truth, synthesized sensors and game rules. No duplicate Java
  PID, engine or request coordinator hidden in Python.

No ROS, new scheduler framework, event-bus framework, service mesh, generic ECS,
runtime plugin system, deep engine inheritance, or whole-tree refactor. A new
interface is justified by two actual consumers or a required hardware boundary.
Reuse ordinary immutable records, enums, small classes and existing tests.

## 2. Data and timing rules

Preserve current field coordinates, inches and radians at existing seams. New DTOs
state frame, units and sign in their definition; flight calculations may use SI
internally with one tested conversion boundary. Existing `RequestStream.vx/vy/omega`
are normalized manual drive demands, NOT measured inches/sec or rad/sec. Do not
silently reinterpret them. A future physical-velocity command would be a new type.

Control baseline: fixed 20 ms simulation tick; actual robot uses measured monotonic
elapsed time with bounded controller handling of abnormal dt. Capture sensors once,
construct an immutable input snapshot, update estimator, obtain controller intent,
arbitrate/update engine and mechanisms, then validate/apply one actuator frame.
Reconcile this with `RobotLoop` before implementation; do not add a second update
of Pedro or mechanisms in the same tick. Output persists only according to the
explicit actuator contract, never as an accidental map omission.

Use logical integer microseconds on new wire timestamps, converting explicitly from
existing timestamps. Store source capture time, receive time, sequence and uncertainty
for asynchronous observations. Never compare wall-clock milliseconds to simulation
time or camera-local time. Sensor missing/invalid/stale is distinct from numeric zero.

Mechanism status must separate requested value, commanded output, measured value,
readiness, fault and confidence. A commanded hood position is not an angle sensor.
Shared maps/lists are copied or immutable; validate finiteness, range and device
capability before any hardware write. Unsupported new wire capabilities fail at
handshake, before enabling actuators; paired R/S fixtures define compatibility.

## 3. Safety, arbitration and lifecycle

Priority: OpMode STOP/emergency stop > latched mechanism fault > explicit manual
takeover/cancel > active shot > ordinary mechanism requests > idle scanning.
Manual recovery is deliberately selected; it cannot bypass hard limits or STOP.

Request IDs are unique within an epoch. Every accepted request reaches one terminal
result exactly once: completed, cancelled, rejected or faulted, with a reason. A
timed-out operation cannot keep owning a motor. Reset/engine switch increments the
epoch and clears obsolete requests, pulse debt, estimator history when appropriate,
and pending events. Preserve valid localization across an ordinary engine switch.

DC/CR stop = zero power. Positional-servo stop = configured safe hold/stow policy,
not universally zero. On process disconnect, STOP or invalid frame, simulator and
real adapter enforce the documented safe frame. Robot fault handling must not depend
on the Python client remaining alive. Only one owner may write each actuator.

Competition profile contains no development socket controller/tap services. Debug
networking belongs in development builds. Onboard inference is the deployment target;
exact compliance is rechecked against the then-current official rules before use.

## 4. Common task completion (all conditions mandatory)

1. Record entry hashes and a clean/dirty worktree inventory. Read the relevant local
   source and predecessor report; do not assume a stale task file is still accurate.
2. Add a focused failing regression/fixture, implement the smallest change, then run
   focused and shared regression tests. Separate compatibility changes from behavior
   changes when possible. Do not widen tolerances to hide failures.
3. Run the feature through the real Java core connected to Pymunk, not only mocks.
   For documentation/data-only tasks, publish the fixture/contract check and run the
   existing smoke; do not invent a physics test for prose.
4. Existing Gradle guards, `:core:test :sim:test :sim:installDist` remain green.
   Changes touching adapters/build/profile also pass `:TeamCode:assembleDebug`.
   S uses its existing unittest discovery and relevant process/network tests.
   Resolve the installed JDK/venv from the repo; do not assume privileged paths.
5. Publish actuator/sensor traces, assertions, seed, command, runtime/dependency
   versions and hashes. A screenshot/demo is supplementary, not the acceptance oracle.
6. Commit and push each tested working increment. Cross-review the final immutable
   hash with the other worker; close every blocker/major, explicitly dispose minors.
7. D records the accepted R/S/D manifest and limitations. Tag the accepted task in
   participating repos; unchanged repos may point to their previous compatible commit.
   Use annotated immutable `p11a-<task-id>-v1` tags and engine tags at B09/C05/D05/E04.
   Never retarget published tags; corrections receive v2. No tags for this draft.

Proposed artifact layout per task: `phase-1.1-a/evidence/<ID>/manifest.md`,
`commands.md`, `acceptance.json`, trace references and `review.md`. Large generated
logs stay outside git with hash and retrieval instructions. Minimal decisive fixtures
are checked in. No claims such as "47 tests proves real hardware works."

## 5. Acceptance levels and tolerances

Every threshold in the task pack is a **proposed software test target**, not a
measured hardware guarantee, unless marked archive-derived or source-derived.
Deterministic same-environment fixtures require identical discrete events and stable
numeric results with their declared epsilon; cross-platform physics is tolerance-based.
20 ms timing events allow at most one tick quantization error unless specified.
Tests include zero/missing/NaN, limits, stale data, cancel/STOP, repeated reset and
engine fallback, not merely the nominal path.

Publish unit-tested, sim-integrated, Android-built, archive-derived and
hardware-validated as separate labels. Hardware validation remains pending now.
Before physical use: verify port/direction with power limited and mechanisms secured,
encoder sign/units, limits, hood motion, shooter calibration, STOP and watchdog,
latency/thermal budget, game rules and inspection. A failing check disables the
affected capability; a simulator tag is not permission to skip this checklist.

## 6. Change control and future worker instructions

Default dependency rule: tasks execute in listed order within a chapter, then advance
to the next chapter only after its release gate. The explicit B05–B07 exception
allows mechanism work after B01 once its device fixture is agreed; B08 still waits
for all B02–B07. C01's source-only geometry research may be prepared early, but
shooting implementation does not bypass B09. Do not parallelize two writers in R.

Before dispatch, fill this short execution header for EACH task (never send placeholders):

```text
Task: <A01..H05> / Always write in English
Authority: Tuna-approved plan revision + this specific bounded increment
Read: common gates + selected task section + predecessor report/review
Input: exact R/S/D hashes, branch dev-phase-1.1-a, selected hardware/schema profile
Owner: one worker/repository; agreed paired worker and exact seam fixture if needed
Allowed edits: specific existing files/new files within the owned layers
Forbidden: protected historical specs, other repos, next task, training, extra agents
Acceptance: named local fixtures + common commands + Pymunk scenario + thresholds
Output: commit/push/hash, evidence/<ID>, limitations, review-ready notification
Stop: acceptance evidence published; await cross-review/next authorized increment
```

H01/H02/G tasks are primarily S-owned, with R owning only controller/core adapters.
H03 splits R logging from S dataset tools at a frozen record schema. H04 is R-owned;
H05 and release manifests are D-owned after R/S evidence. Documentation decisions
are not a reason for docs to modify robot/simulator code.

Within a task, prefer at most three logical tested increments: contract/fixture,
behavior/plant, integration/fault proof. Split a task further if these cannot each
leave a working baseline. Commit and push each working increment; the task tag
follows complete cross-review, not the first compiling interface.

Allowed without roadmap rewrite: implementation-local fixes, clearer tests, replacing
an inaccurate assumed parameter with traced evidence within the approved behavior.
Require a short ADR and orchestrator review: different hardware topology, new layer,
wire semantic change, failure of the selected physics method, action/observation
schema change, safety/legality finding, or calibration evidence invalidating a gate.
Record evidence, affected tasks, smallest alternative, migration and fallback. Ask
Tuna for material scope/authority changes; do not churn the entire plan over naming.

After approval only, each worker receives one task ID plus common gate and relevant
spec, exact input hashes, owned paths and stop condition. Every message starts
`Always write in English`. A bounded goal stops at evidence/review handoff; it does
not authorize the next dependent task or any learning run. Preserve busy queues and
user input. Robot and sim may work concurrently on an agreed seam; neither invents
the other's contract. No ball agent, no reviewer launch, no extra supervisors by default.
