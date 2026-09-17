# A — prove the baseline and recover last-season behavior

Status: DRAFT, not dispatched. All tasks also require [common gates](00-common.md).

Planning snapshot: R `d5bda622d5bba6dfef6c4bfefed69e0cc20d7e67`,
S `5dd6daacedbd629deb0827b36240f3064a808f3b`. Reported evidence: 122 core and
10 Java sim tests, Android build, 83 Python tests, six autos plus test-line with
both engines. These are worker reports, not a fresh audit performed by this plan.
Freeze current hashes again at execution; retain baseline evidence for comparison.

## A01 — bounded transport and truthful event validation

Entry: current socket/multi-robot reports and pinned commits.
Owner: S; R reviews wire effects. Inspect `sim/server.py`, protocol validation,
`tests/test_server_io_timeout.py`, `test_multi_robot.py`, `test_process_network.py`.

1. Audit all accept/read/write/reset barriers, including partial frames and one
   slow peer while other robots are ready. Use monotonic deadlines across the whole
   operation, not a fresh timeout for each received byte. Keep startup barrier fix.
2. Define one deterministic session-fault result; zero affected outputs, unblock
   healthy sessions or close the synchronized episode according to existing policy.
   Do not continue a supposedly synchronized world with a missing robot tick.
3. Reject fractional event timestamps rather than silently truncating them. Preserve
   the established integer unit and reject booleans masquerading as integers.
4. Add hung/fragmented client, disconnect-mid-frame, slow-send, reset race and invalid
   timestamp regressions. Assert bounded completion without long sleeps/flaky timing.

Exit: all existing socket/process tests pass plus new cases; two independent runs
of a two-robot script give the same complete transcript. No unrelated physics edits.

## A02 — configuration truth and cancellation coverage

Owners: R/S paired, one seam fixture first.

1. Trace `RobotConstants -> Mechanism -> wire -> Python backend`. Verify which mass
   and dimensions are actually consumed; remove the duplicate hard-coded chassis
   mass only after a fixture proves the transmitted value is used.
2. A fixture changes mass and proves the relevant dynamic response changes where
   the backend models mass. If motion is kinematic, document that limitation instead
   of claiming mass fidelity. Do not redesign the chassis plant to satisfy a label.
3. Extend turret hold/cancel regression to pending scan events as well as active aim.
   Assert one terminal result, no delayed scan emission, zero orphan ownership.
4. Inspect manualDrive's raw-stick/nonzero test versus its deadband. Add a fixture
   specifying that sub-deadband noise must not cancel a trajectory; propose the small
   correction explicitly if current behavior violates it.

Exit: tests demonstrate actual consumed constants and cancellation behavior; current
engine paths still pass. Report any unmodeled physical effect explicitly.

## A03 — reproducible Java-on-Pymunk acceptance harness

Owners: S harness, R target/error review. Preserve existing successful scripts.

Run all six autos and test-line under direct/cplx1 at fixed seed, then rerun in a
fresh process. Store distinct metrics: truth-to-command target error, sensor-to-truth
error, baseline-to-new trajectory error, request terminal status and timeout count.
Do not substitute one metric for another. Use current acceptance limits (3 in / 5°
auto target; prior 0.15 in / 0.3° regression envelope where applicable) without
loosening them. Record maxima AND final errors; never accept an incomplete request
because it briefly crossed the target. Preserve detailed existing task semantics.

Add a deterministic controller-recording fixture: neutral, drive, stop, reverse,
rotate, cancel, engine switch, reset. Save actual motor traces and a short viewer
demo; compare entire repeat transcripts in the pinned runtime. Exit: a single
documented command reproduces the matrix, failures return nonzero, no hidden truth
is injected into controller state. This becomes every later release's smoke suite.

## A04 — match-used legacy behavior and parameter provenance

Owner: R analysis, S independently reviews executable fixtures; D publishes table.
Archive root: `/home/shared/projects/archive/ftc/de-cock/robot-code/TeamCode/src/main/java/org/firstinspires/ftc/teamcode`.
Read match entrypoints/call chains, not every abandoned subsystem variant:

- `contingency/lvbelc5/teleop` and its Shooting/Aiming/Recovery controllers.
- `hardware/subsystems/{intake,feeder,shooter,hood,turret}` implementations used there.
- `config/HardwareConstants.java`, shooter storage and `RonaldoShEngine` coefficients.

Produce `legacy-behavior-matrix.md`: button edge/hold/release, input priority,
mechanism request, actuator direction/power/position, sensor dependence, timing,
normal release, explicit cancel, STOP, source path and preserve/correct/unknown.
Produce a separate parameter table: name/unit/value/source, active caller, confidence,
applies-to-old-ball versus pollen-unverified, and physical remeasurement required.

Mandatory findings to resolve: feeder 350 ms pulse and request coalescing; shooter
power PIDF and readiness dwell; mirrored hood mapping; limited dual-CR turret;
turret incremental encoder sharing the `shooterLeft` hardware port name; independent
encoder polarity; analog startup behavior; joystick and recovery priorities.
Do not assume that the turret encoder port also measures flywheel speed.

Extract small golden calculations/traces, not a second complete legacy runtime.
Expected output must come from the traced archive/reference calculation, not the new
class under test. Account for Android wall clock replacement with HAL monotonic time.
Exit: each driver-visible behavior has evidence or an explicit unresolved row.

## A05 — control profiles and first release manifest

Entry: A01–A04 accepted. Owner: R map/fixtures, D human-readable control sheet.
Proposal requiring Tuna discussion: named legacy-match map for familiar gestures,
current diagnostic map retained. Bind intake forward/reverse, shooting hold/release,
jam clearing, aim/manual turret, engine select, heading reset and hard abort without
conflicting chords. Verify exact archive bindings before assigning button names.

Test every binding, simultaneous buttons, held buttons across reset/engine switch,
deadband, duplicate edges and gamepad disconnect. Replay demonstrates same direction
and sequencing as archive for preserved behavior (timing within one control tick).
Do not claim mechanism parity until B adds actual mechanisms; stubs are labeled.
Exit: baseline manifest, approved proposed control map, documented unknowns and
reproducible proof. Tag A tasks only after cross-review. B starts from this manifest.
