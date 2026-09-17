# A v2.2 — baseline first, extend existing archive analysis

Status: **Chapter A is released now under Tuna-approved v2.2 (2026-09-17).**
Evidence-A remains authoritative for per-task outcomes. A02 is unblocked at protected
protocol pin `26f915b`; B01 is blocked pending the ADR signature pin. B is approved but
gated until A05/evidence/tag; C and the far roadmap remain unreleased. Training,
ftc-reviewer, and ftc-ball remain forbidden. Read [00](00-common.md) and
[hardware-profile-v0](../hardware-profile-v0.md); path aliases are defined in 00.
R d5bda62 / S 5dd6daa are the planning pins, not new verification claims.
Evidence: ONE `D/phases/phase-1.1-a/evidence-A.md`. A05 is the only chapter tag.
Protected protocol gate: ftc-main amendment `26f915b`, reconciled in docs at `0973e86`.

## A01 — bounded transport and integral event timestamps

Owner S. Files: `S/sim/server.py`, existing `S/tests/test_server_io_timeout.py`,
`test_multi_robot.py`, `test_events.py`, `test_protocol_validation.py`,
`test_process_network.py`. No wire-format expansion in this task.

1. Existing single-client per-recv timeout is insufficient for a multi-client partial
   frame. Apply one monotonic operation deadline across fragmented reads/writes and
   multi-robot reset/step barriers; do not restart the budget for each byte. Preserve
   the accepted staggered-start barrier. A failed synchronized step must not advance
   with one missing robot; follow documented session failure/zero-output cleanup.
2. `_parse_events` already rejects bool; retain that test. Fix `int(t_raw)` silently
   truncating fractional t_ms: accept only finite, nonnegative integral numeric values
   within signed-long range; reject1.5, NaN, infinity and bool. Decide1.0 as accepted
   numeric integer in fixture; canonical outgoing form is integer. Unit remains ms.
3. Tests: `test_multi_robot.py::test_partial_frame_deadline`,
   `::test_slow_peer_does_not_advance_world`,
   `test_events.py::test_fractional_timestamp_rejected`; use reset seed42,
   test deadline500 ms with wall-time completion bound2 s on failure path. No long sleeps.

Exit: fragmented/hung/disconnected peer terminates boundedly with no advanced mixed
world; timestamps cannot be truncated. Focused tests + A03 A-drive smoke when runner
lands. Single-repo fix: no new cross-review ceremony. No unrelated physics rewrite.

## A02 — actual mass source, cancellation coverage, deadband

Owners S parser/backend and R regression; cross-review mass seam only.
Read J/hal/RobotConstants.java (already ROBOT_MASS_KG=12), S/sim/mechanism.py,
S/sim/physics/pymunk_backend.py (still hard-coded12), J/subsystem/stub/StubTurret.java,
J/controller/teleop/TeleopMap.java. Constants are parsed from Java, NOT transmitted.

A02.0: the protected amendment `26f915b` adds ROBOT_MASS_KG to the binding scalar list;
A02 is unblocked at that pin. Do not change12 kg to archive13.8 here.
The exact B01 record signatures remain an ADR/protected-protocol gate; B01 is blocked
until ftc-main pins them.
Then extend `Mechanism.Physics`/`PhysicsConfig` and parser as needed; Pymunk body uses
parsed mass. Test fixture copies RobotConstants into an isolated temporary file and
sets mass18; assert actual body mass/inertia derivation changes. Do not demand changed
free-space velocity if the existing drive law scales force with mass.

Tests: extend JT/hal/MechanismTest.java and S/tests/test_mechanism.py with mass/source
validation; S/tests/test_pymunk_backend.py::test_body_uses_configured_mass. Invalid/
missing mass fails clearly. Extend JT/subsystem/stub/StubTurretTest.java with
`holdClearsPendingScanEvent`; no deferred scan emission after hold. Extend
JT/controller/teleop/TeleopControllerTest.java with `subDeadbandStickDoesNotCancelPath`;
manualDrive uses the same .05 deadband as output, not raw nonzero input. Preserve
normal intentional manual takeover. Exit: baseline A-drive unaffected; no fake
claim that mass now validates the entire dynamic model.

## A03 — NEW small e2e runner, not an existing acceptance script

Owners R runner/Java scenario, S process/physics integration seam.
Create `R/tools/acceptance.py`, `R/tools/fixtures/phase11a-A.json`,
`SJ/AcceptanceMain.java`, `SJT/AcceptanceMainTest.java`, and
`S/tests/test_acceptance_scenarios.py`. Reuse SimHal/RobotFactory/AutoRegistry and
existing process-test helpers; do not duplicate transport or add a test framework.
Runner discovers sibling S and installed Java distribution, accepts explicit paths,
starts owned headless Pymunk processes, chooses free ports and closes only its own
children. It does not submit tests through the lossy debug SocketController.

Proposed command after implementation:
`python tools/acceptance.py --chapter A --physics pymunk --seeds 1,42` (from R).
A `--viewer` rerun is optional for Tuna, using identical scenario input.

Only TWO scenarios gate baseline:

- **A-drive**: reset(72,72,0), test-line ->(120,72,0), then neutral hold; 1000 ticks,
  20 ms, both direct/cplx1, seed1 repeated fresh-process; seed42 once. Require
  request DONE, final truth within .5 in/1° target and no stuck active request.
  These are NEW v2 acceptance targets based on existing much smaller observed errors,
  not an invented inherited3 in/5° rule. Report sensor-to-truth separately.
- **A-cancel**: reset(72,72,0); begin test-line, manual takeover at tick20; cancel-all
  at tick40; engine0/1 switch at ticks60/80; neutral until tick100. Wheels zero on
  cancel/switch tick, no stale resumed path, one terminal per old request; pose stays
  finite and unchanged by switch itself. Seed42; rerun1 for smoke.

Output to stdout plus ONE JSONL trace per scenario under caller-chosen output dir:
`scenario,seed,t_ms,engine,request_statuses,commanded_target,truth,sensed_pose,motors,
servos,events`. Summary in evidence-A has request outcome, target error, sensor error,
wall-time and hashes. Fresh-process seed1 transcript matches exactly in pinned runtime;
ignore only wall-time diagnostic fields. Wall timeout30 s per scenario, fail nonzero.

Historical reference: D/phases/phase-1.1/acceptance-sim-cx-19.md §notes reports
.15 in/.3° thresholds for SENSOR-to-truth error, not old/new trajectory drift. Preserve
that diagnostic interpretation, not the erroneous v1 regression label. R/robot-cx-22-report.md
is the current target-error evidence. Six old autos remain existing regression
coverage, not six mandatory new gate demos. Test counts are not the release result.

## A04 — extend predecessor evidence, do not re-inventory from scratch

Owner R analysis; D appends concise findings to evidence-A. Read first:
D/phases/phase-1.1/{gamepad-map-analysis.md,teleop-map.md,request-catalog.md}.
Keep historical files intact; append only corrections/new-topology column in evidence-A.
Source: OLD/contingency/lvbelc5/teleop/{BlueTeleop,RedTeleop}.java and
OLD/contingency/lvbelc5/controllers/{ShootingController,AimingController,RecoveryController}.java;
OLD/config/HardwareConstants.java and active subsystem implementations. Controllers
are in controllers/, not teleop/. Exclude disabled experiments/GP2 tuning UI from port.

Confirmed facts to record: RT>.5 auto-shoot/warmup; RB follows AUTO_SHOOT because
burst branch is disabled; LB intake+feeder reverse; Y without START toggles shooter/
feeder sign every500 ms; LT>.1 intake in idle; D-pad offsets; B held park/release
cancel; BACK2 s recovery toggle (4000 RPM,45° hood,0° turret); START+Y2 s reset.
Differences from today's diagnostic map are explicit, not silent replacements.

Shooter speed uses RIGHT/shooterRight; turret encoder uses shooterLeft, whose MOTOR
OUTPUT simultaneously drives the shooter follower. Trace BOTH input/output roles;
not an encoder-only device or a second turret motor. Flag actual28-tick/1.6-ratio
versus stale8192/1:1 comments. Trace active Blue/RedTeleop -> lvbelc5/Robot construction
before choosing implementations, not just declarations or abandoned variants.
intake_dist exists only as an unused declaration in active intake; capacity3 is real
archive configuration. Active match feeder uses350 ms pulse PLUS100 ms post-pulse
delay; HC.Feeder.postPulseDelayMs500 has no call sites, NOT an active fallback.
Record shooting intake.8 versus default1; HC.Intake.holdPower.2 is declared, not
used by active intake. Recovery hood45° is RecoveryController:29, not HC.Hood.
Shooter runtime gains/readiness come from ShooterPidfPowerStorage; HC supplies boot
defaults. Record the actual values when making reference traces, not just defaults.
Archive turret ctor reconfigures/resets shooterLeft AFTER shooter construction;
feeder ctor also resets its own encoder. B01 intentionally centralizes these resets.
Record active Limelight -> LocalizerController, missing-camera fallback, and B's
deliberate odometry-only subset. Pinpoint forwardPodY161/strafePodX0 maps to new
xPodOffsetMm161/yPodOffsetMm0 by MEASURED pod axis; unused HC -84/-168 is not a second
valid geometry. Counts, names, paired motion and directions MUST match the active archive:
shooter2 motors, hood2 position servos, turret2 CR servos, intake1, feeder1, drive4.
Golden traces include both outputs per pair and the shared-port isolation case;
hardware-profile-v0 supplies the source locations, not permission to delete actuators.

Exit: existing analysis annotated preserve/correct/defer per relevant gesture, exact
constants/source fields, and a short golden actuator trace table. No redundant
legacy-behavior-matrix.md. Focused later tests compare these calculations, not new
code against itself. No implementation of future mechanisms in this analysis task.

## A05 — stable engine registry and baseline checkpoint

Owner R: J/logic/EngineRegistry.java, J/RobotFactory.java, J/RobotLoop.java;
JT/RobotFactoryTest.java, JT/RobotLoopSwitchTest.java, JT/controller/teleop/TeleopControllerTest.java.
Pin direct0/cplx1=1 and cplx_engine_1 alias; unknown/reserved index rejects, old replay
indices still select same engine. Explicitly name selector constants, not magic
list positions. Keep today's diagnostic map runnable. A04 specifies legacy-match;
its actual mechanism commands/requests are owned by B08, not emitted before APIs exist.

Gate: A-drive and A-cancel pass with concise trace/demo, existing relevant regressions
pass, mass amendment recorded. D publishes baseline manifest section in evidence-A
and tag p11a-baseline-v1 at compatible R/S/D commits. No per-A-task tags/manifests.
Stop at checkpoint; B remains gated until A05/evidence/tag.
