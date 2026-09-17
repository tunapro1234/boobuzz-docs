# D — one turret Limelight, a simple world model and cplx3

Status: DRAFT, not dispatched. Entry: C05; [common gates](00-common.md) apply.
No image renderer, detector training, SLAM framework or autonomous ball pursuit.

## D01 — observation contract and actual Limelight adapter

R defines immutable `VisionFrame`: sequence, pipeline ID, capture/receive time and
uncertainty, validity, detections. A detection contains supported class/confidence,
bearing/elevation or bounding box with calibration, and optional measured range only
when the actual API supplies it. No world-coordinate oracle, simulator object ID,
exact target count or magic persistent visual identity.

Check the FTC SDK version actually pinned in R against Limelight API signatures.
Determine how pollen detection will be supplied (existing compatible pipeline/model
or later camera setup). Vendor detector-result support does not prove a pollen or
robot model exists. Define pollen/unknown/robot/nectar-or-nontarget semantics when
available; a single pollen detector may simply omit non-target detections. Unknown
objects are not collected by inference. AprilTag pose, if used, is a separate typed
observation and optional capability, not automatically mixed into ball detection.

Camera timestamps may use a different clock. Prefer documented capture timestamps
with a verified mapping; otherwise receive time minus measured capture/pipeline
latency with uncertainty. Deduplicate frames; reject negative age, unreasonable
latency and unknown pipeline. Keep a bounded robot-pose/turret-angle history for
capture-time interpolation (initial horizon 1 s; stale beyond retained history is
rejected). A late frame cannot be transformed with current turret heading.

Tests: golden vendor-result adapter fake, no target, duplicates/out-of-order, clock
offset/drift fixture, pipeline switch, stale frame, reset and invalid calibration.
Exit: same frame contract in FTC adapter and SimHal; actual camera configuration and
unavailable capabilities recorded, never implied implemented by a synthetic frame.

## D02 — sensor generation without image processing

S projects physical object geometry into one camera's calibrated pose/FOV/range.
Honor turret angle, lens height/pitch, object height and occlusion by field/robots.
Pollen is the only collection target; include nectar/unknown clutter in rejection
tests. Frame delivery is lower-rate and asynchronous to 50 Hz control (proposed
fixture 20 Hz, measured hardware value later), with bounded latency, seeded angular
noise, false negatives and optional false positives. Quantify assumptions.

Detection probability decreases with angular image motion/exposure; fast turret
motion yields fewer useful frames. Do not use an unexplained binary truth switch.
Supply raw camera-like measurements, not perfect object locations plus cosmetic
noise. Independent RNG streams isolate sensor noise from physical collision order.

Tests: FOV edge, behind-camera, distance limit, known occluder, identical seed, changed
seed, latency, turret acceleration and stationary settle. The Java policy never
receives private IDs. Exit: plots/traces of detection rate/error versus speed/range
and a reproducible scan scene with realistic dropouts. No claim of camera accuracy
without real calibration; parameters remain openly provisional.

## D03 — vision-only tracking and bounded world state

R adds a small world updater in logic, not a new architectural layer. Extend feedback
with a bounded immutable world snapshot. Use capture-time pose and turret transform.
For floor pollen, intersect bearing/elevation with the ball-center-height plane;
reject shallow/above-horizon rays or implausible range. Propagate bearing and pose
uncertainty; do not turn low-confidence long-range estimates into precise points.
Airborne detections do not fit the floor model: mark unlocalized/unknown or reject.

Start with deterministic gated nearest-neighbor association in field coordinates,
one-to-one per frame, with position/velocity alpha-beta filtering and bounded speed.
Use simple isotropic uncertainty radius if a full covariance is unjustified. Local
monotonic IDs belong to tracker, not simulator; reset namespace each epoch. Stable
tie-breaks, tentative/confirmed/lost states and age-dependent confidence are enough.
Do not copy a full multi-object framework just for its name. If crossing fixtures
fail, evaluate Kalman + Hungarian as a contained replacement behind the same API.

Initial fixture parameters: confirm after 2 of 3 frames; expire a pollen track after
2 s unseen, robot track after 0.5 s; bound extrapolation then mark stale. These are
test defaults to evaluate, not camera facts. Missing detections only provide negative
evidence in a visible, unoccluded sector with a valid settled frame. Repeated stale
frames must not repeatedly increase confidence or erase objects.

Tests: stationary objects, moving robot, crossing pollen, occlusion/reappearance,
duplicate detections, false positive, two close balls, pose error, track limit and
drop policy. Report localization error, association errors and false confirmed tracks
against private truth in evaluator only. Proposed simple scene gate: <=2 in median
pollen localization error at 48 in under declared mild noise; zero ID switches in
isolated noncrossing fixtures; bounded memory after 10,000 frames. Harder scenes
publish limitations rather than silently enlarging gates.

## D04 — sector scheduler and target-load beliefs

R adds a turret owner with states IDLE, MOVE, SETTLE, SAMPLE, NEXT, PREEMPTED. Scan
named useful sectors within turret limits; do not continuously spin. Select the
oldest useful sector with a deterministic travel penalty; no global optimizer.
Proposed settle criterion: <=5°/s and <=2° error for 100 ms, then collect two fresh
frames or a 500 ms timeout. Clamp goals to reachable sectors and report skipped ones.

Operator shoot intent immediately preempts scanning. Prepare/aim/feed owns turret;
scan resumes only after shot recovery and cancellation of old frame waits. Manual
turret and abort outrank both. No repeated scan/shot toggling: use explicit ownership,
minimum dwell where safe and an operator-selected mode, not inference from one frame.

For each shooting region, maintain target-load interval/estimate, last observation,
confidence and evidence type. A successful motor pulse is a launched-ball hypothesis,
NOT a confirmed score or exact remaining load. Predict possible arrival from C03,
then confirm only through observable evidence. Unobserved opponent actions and Hive
tips widen/invalidate belief. Our pollen-only robot still needs uncertainty about
nectar/opponent effects. Do not infer exact mass from a blurry pile.

Initially beliefs inform display, suggested target and scan priority. They must not
silently suppress an explicit valid operator shot merely because an uncertain count
looks sufficient. Automatic rescan occurs when no shot is requested, belief is stale
and turret is available. Autonomous strategy is deferred. Tests: shot during MOVE/
SETTLE/SAMPLE, multiple requests, dropout, no reachable sector, unknown target load,
unseen tip and restart. One owner, no phantom count increments, bounded scan cycle.

## D05 — cplx3 release (the requested vision-world engine)

Complete cplx2 behavior plus D01–D04 behind a selectable engine option. No range
fusion dependency and no autonomous collection. Demonstrate pickup, travel, stop,
scan sectors, inspect world tracks/load uncertainty, shoot on request, resume scan,
lose camera, continue fixed/calculated shooting and manual recovery.

Acceptance: all cplx1/2 suites; seeded vision scenes; 100 shot-preemption trials with
no scan output after ownership transfer; stale/repeated-frame fault tests; bounded
world memory; snapshot contains no private truth. Show vision-off ablation and honest
uncertainty overlays. Tag `p11a-engine-cplx3-v1` after cross-review. Real detector
setup/calibration remains an explicit hardware gate if camera access is unavailable.
