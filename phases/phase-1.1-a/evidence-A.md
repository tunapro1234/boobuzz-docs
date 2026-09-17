# Chapter A evidence ledger

Status: **Chapter A released; documentation-only evidence ledger.** This is the sole
Chapter A evidence file. It records approved pins, task slots, commands and
limitations; an empty result is not a passing result. No unrun implementation or
acceptance outcome is claimed here. A02 is unblocked at protected pin `26f915b`;
the record-signature protocol gate is satisfied at ftc-main pin `7447546`.
Chapter B becomes eligible only after this A05 evidence commit and
`p11a-baseline-v1` tag are verified.

## Pinned inputs

| Repository / source | Branch | Pin | Role |
|---|---|---|---|
| docs | `dev-phase-1.1-a` | `e5796b7c1b005d4c1559d5339621c99080de0903` | v2.2 docs entry |
| robot-code (R) | `dev-phase-1.1-a` | `d5bda622d5bba6dfef6c4bfefed69e0cc20d7e67` | Java core, FTC adapter, Java sim |
| re-cock-nize (S) | `dev-phase-1.1-a` | `5ba0a9671eeedc84f2a628ff970133c1e86f656f` | Python server, physics and tests; A01 publication |
| archive (OLD) | archived source | `d7711d043280034ab5c75ae26a253629fd2d4a7b` | behavior/calibration provenance |

The protected `protokol.md` and `phases/phase-1.1/design-spec.md` are read-only.
R and S source are read-only for this documentation checkpoint. A source pin is
not a test result; later entries must name the exact command and artifact.

## Approved Chapter A slots

| Slot | Owner / seam | Planned evidence | State |
|---|---|---|---|
| A00 | D release cleanup | fixed-prefix retirement, English-content rule, ADR/evidence paths | **Recorded in this docs increment; no implementation outcome** |
| A01 | S transport/events | bounded fragmented I/O, integral millisecond events, no mixed-world advance | **Accepted at S `5ba0a96`; final compatible S pin is `4cc1201`** |
| A02.0 | D + ftc-main protocol owner | `adr-device-seam-v2.md`; protected protocol amendment gate | **Unblocked at `26f915b`; record-signature protocol gate satisfied at `7447546`; B eligibility waits for this evidence commit/tag** |
| A02 | R/S mass seam + R regression | Java-source mass parsing, 18 kg isolated fixture, cancellation/deadband tests | **Accepted at R `97995ca` / S `4cc1201` after the mass escalation fix** |
| A03 | R/S e2e seam | two fixed Pymunk scenarios and JSONL traces | **Accepted on the final post-A02 rerun at R `72d3ac9` / S `4cc1201`; trace gates below** |
| A04 | R analysis + D evidence | extension of predecessor gamepad/request evidence with archive file:line handoff | **Accepted as archive-derived handoff at OLD `d7711d0`; no runtime test is implied** |
| A05 | R + D checkpoint | registry/order fixtures, A-drive/A-cancel gate, chapter manifest/tag only after approval | **Accepted at R `72d3ac9` / S `4cc1201`; manifest and tag below** |

## A00/A02 documentation record

- `00-common.md` now retains the English-content rule but no fixed message prefix.
- `adr-device-seam-v2.md` distinguishes current proto1 zero-fill from proposed
  proto2 positional-servo hold, keeps DC/CR omission at zero, lists paired devices,
  units, ownership and validation, and records the exact B01 signatures now bound by
  ftc-main at `7447546`. A02 is unblocked at amendment `26f915b`; B eligibility waits
  for verification of this A05 evidence commit and tag.
  The amendment fixes optional `reset.proto` absent=`1` versus `ready.proto`,
  pre-output failure on mismatch, exactly two `RobotAction` maps (`motors` for DC+CR
  power and `servos` for positional hold), declared initial positions for never-commanded
  servos, reset-cleared holds, proto1 full-map/zero-fill behavior, and Java validation
  of both ready name lists. `ActionValidator` rejects half-pairs before writes; paired
  seam fixtures 1–6 are binding and still have no run outcome here.
- A02's planned Java-source reader rule requires a finite positive
  `ROBOT_MASS_KG` in kg, clear missing/invalid failure, and an isolated 18 kg body/
  inertia fixture. These are requirements for a future task, not completed tests.

## Forward-only A03/A02 ordering (provisional)

- The forward-only decision keeps provisional R A03 history at `c939f16..e80b8c9`.
  R A02 uses base `e80b8c9`, or a coherent separately labeled A03 WIP commit may
  be used; neither provisional lineage is an A03 acceptance pin.
- S must first publish only `tests/test_acceptance_scenarios.py` as A03 WIP/not
  accepted on top of S `5ba0a96`, then publish A02. No A03 acceptance is valid
  until a post-A02 rerun. A05 pins only final post-A02 R/S hashes.
- This is ordering metadata, not an A03 result. A02 documentation propagation
  continues; the protocol gate is now satisfied at `7447546`, while B eligibility
  waits for verification of this A05 evidence commit and tag.

## ESCALATION to ftc-main

- The A02 cross-review found `re-cock-nize/sim/physics/pybullet_backend.py:185-201`
  hardcoding a 12 kg mass. ftc-main resolved that `ROBOT_MASS_KG` binding is
  backend-agnostic and authorized the narrow PyBullet fix only.
- Review provenance remains R `97995ca`, S `5849e58`, and provisional A03 WIP
  `635741d`; the earlier A01 S pin `5ba0a96` and the forward-only ordering note
  remain unchanged.
- Resolution: S `4cc1201` applies the authorized narrow backend-agnostic
  `ROBOT_MASS_KG` fix, with the final A02 tests recorded in the A05 manifest below.

## Commands and outcomes

| Check | Command / artifact | Outcome |
|---|---|---|
| Documentation diff | `git diff --check` | **Passed for this evidence increment** (no output) |
| Mass parser | named A02 isolated fixture | Not run; no implementation dispatched |
| Protocol fixture | proto1/proto2 paired golden frames | Not run; amendment `26f915b` and record-signature gate `7447546` are published; B eligibility still waits for this A05 evidence/tag and paired-fixture evidence |
| Chapter A e2e | A03 runner and two Pymunk scenarios | Not run; A03 not started |

Prior robot/simulator reports remain provenance references, not new Chapter A
outcomes. Their test counts and smoke results must not be copied into this ledger as
fresh evidence.

## A01 published simulator increment — independently verified

S published `5ba0a9671eeedc84f2a628ff970133c1e86f656f` (`5ba0a96`) on
`dev-phase-1.1-a`; `git ls-remote origin refs/heads/dev-phase-1.1-a` resolves to
the same hash. The parent is the planning pin `5dd6daa`. The commit changes exactly
`sim/server.py`, `tests/test_events.py`, and `tests/test_multi_robot.py`. The S
worktree was clean relative to its branch except for the preserved pre-existing
untracked `.claude/` directory; no other path was staged by the worker.

Independent checks from the S checkout:

| Check | Command | Result |
|---|---|---|
| A01 focused regressions | `../.venv/bin/python -m unittest -v test_multi_robot.TestMultiRobotServer.test_partial_frame_deadline test_multi_robot.TestMultiRobotServer.test_slow_peer_does_not_advance_world test_events.TestStepEvents.test_fractional_timestamp_rejected` (cwd `tests`) | **3 passed** |
| Focused multi-robot suite | `PYTHON="$PWD/.venv/bin/python" ./run_tests.sh -k multi_robot` | **9 passed** |
| Focused events suite | `PYTHON="$PWD/.venv/bin/python" ./run_tests.sh -k events` | **7 passed** |
| Focused server-I/O timeout | `PYTHON="$PWD/.venv/bin/python" ./run_tests.sh -k server_io_timeout` | **1 passed** |
| Focused protocol validation | `PYTHON="$PWD/.venv/bin/python" ./run_tests.sh -k protocol_validation` | **4 passed** |
| Process-boundary determinism | `PYTHON="$PWD/.venv/bin/python" ./run_tests.sh -k process_network` | **2 passed** |
| Multi-robot subset | `PYTHON="$PWD/.venv/bin/python" ./run_tests.sh -k multi_robot` | **9 passed** |
| Full S suite | `PYTHON="$PWD/.venv/bin/python" ./run_tests.sh` | **85 passed, 0 skipped** |

The source diff also passes `git diff --check` against `5dd6daa`. A01 now carries
one monotonic budget across fragmented frame I/O and multi-robot reset/step work;
integral, finite, non-negative millisecond event timestamps are canonicalized and
fractional/NaN/infinite/boolean/out-of-range values are rejected. A failed
synchronized operation aborts the connected session, clears pending state/output,
and requires a fresh reset barrier; a remaining client is not advanced alone. This
increment does not provide A03's Java/Python acceptance runner or physical-robot
validation, and no A03 outcome is inferred here.

## A04 source-grounded handoff — preserve, correct, defer

ftc-watchdog supplied the archive handoff against OLD `d7711d0` (approved docs pin
`e5796b7` and R entry `d5bda62`). The entries below are archive-derived facts and
planned trace vectors, not newly run tests or implementation outcomes.

### Preserve

- GP1 mecanum: Blue uses `ly/lx/-rx`; Red negates `ly/lx`. Normal teleop is
  field-oriented false; Recovery is robot-oriented true. RT `> .5` requests
  `AUTO_SHOOT` in the zone and WARMUP outside. LB runs intake and feeder at `-1`
  while the shooter keeps running. LT `> .1` drives the default intake only while
  IDLE. GP1 D-pad applies configured turret steps and hood ±1°; Recovery applies
  turret ±2° and hood ±1°. B press parks/releases teleop; BACK held 2 s enters
  Recovery; START+Y held 2 s hard-resets (`contingency/lvbelc5/teleop/{BlueTeleop,RedTeleop}.java:74-171,184-217`; `controllers/RecoveryController.java:27-37,68-177`).
- Normal GP1 manual offsets are edge-triggered: the default turret step is
  2.0° and the accumulated offset clamps to ±30° (`TelemetryManager.java:64-79,450-465`);
  hood steps are ±1° and clamp to ±10° (`TelemetryManager.java:483-500`). Recovery
  has separate edge-triggered offsets of ±2° turret and ±1° hood
  (`RecoveryController.java:107-138`); these normal and Recovery limits must not be merged.
- Hardware remains one shooter mechanism with two DC motors, one hood with two
  complementary position servos, one turret with two equal CR-servo outputs, plus
  intake1, feeder1 and drive4. `shooterRight` is the speed source; `shooterLeft`
  actively drives the shooter and its encoder is the turret input (`HardwareConstants.java:147-160,282-307`).

### Correct / record

- RB's burst branch is disabled by `false &&`; RB therefore falls through the
  AUTO_SHOOT pulse-plus-delay path (`ShootingController.java:103-110`). GP1 A's
  manual-feeder branch is commented/cleared (`:165-169,465-471`).
- Y without START toggles shooter and feeder sign every 500 ms and commands intake
  `+1` (`ShootingController.java:89-103,292-305`). Shooting intake is `.8`, idle
  default is `1`; HC `holdPower=.2` is declared but unused (`HardwareConstants.java:90-114`; `ShootingController.java:321-357,457-463`).
- Active feeder timing is a 350 ms pulse plus a 100 ms post-pulse delay
  (`ShootingController.java:38-40,321-334`); HC `postPulseDelayMs=500` has no caller
  (`HardwareConstants.java:611-612`). Recovery hood 45° is from
  `RecoveryController.DEFAULT_HOOD_ANGLE` (`RecoveryController.java:27-30,163-165`),
  not HC's default 44°.
- Reset precedence remains a decision before porting: Teleop BACK calls
  `RecoveryController.checkToggle` (`BlueTeleop.java:81-82`), while
  `LocalizerController.handleBackButtonReset` is a distinct rising-edge vision
  reset (`LocalizerController.java:125-145`); START+Y uses
  `System.currentTimeMillis`. Central encoder reset is a new fix, not archive behavior.

### Defer

- GP2 tuning UI and the disabled RPM test remain out of A04. The archive Limelight
  is active but tolerates absence (`Limelight.java:43-50,80-109`; `LocalizerController.java:75-109,150-188`); its adapter belongs to Vision-A, while B remains odometry-only.
- `intake_dist` is an unused declaration; capacity3 is archive configuration.
  Turret analog calibration still needs physical work. Runtime shooter tuning is
  applied from `ShooterPidfPowerStorage.java:13-43` by
  `ShooterPidfPowerSubsystem.java:42-53`; HC values are boot defaults.
- Pinpoint uses active forwardPodY=161 / strafePodX=0, FORWARD/REVERSED and 4_BAR
  (`drivetrain/pedroPathing/Constants.java:41-48`); HC `-84/-168` is unused.
  Archive shooter constants use 28 ticks and ratio 1.6, while turret uses 8192/.715
  (`HardwareConstants.java:154-160,287-296`).

## A04 planned golden actuator traces (not run)

| ID | Planned vector and expected archive-derived shape | Source anchor |
|---|---|---|
| T1 IDLE | shooter R/L=0; hood holds explicit pair; turret CR pair=0; intake/feeder=0 | `HardwareConstants.java:90-114,147-160,282-307` |
| T2 RT/RB | shooter R=`p`, L=`p*followerScale`; speed reads RIGHT; hood aims; turret=`(q,q)`; feeder waits ready then 350+100 ms; intake=.8; RB uses AUTO_SHOOT because burst is disabled | `ShootingController.java:103-110,321-357`; `HardwareConstants.java:147-160` |
| T3 LB | shooter unchanged; hood/turret track; intake=-1 and feeder=-1 | `BlueTeleop.java:89-103`; `ShootingController.java:321-357` |
| T4 Y | shooter R/L signs toggle together every 500 ms; feeder follows; intake=+1; hood=25°; turret=`(q,q)` | `ShootingController.java:89-103,292-305` |
| T5 Recovery | shooter target 4000 RPM; hood 45° = `(0.4266667,0.5733333)`; turret target 0 with equal CR power | `RecoveryController.java:27-30,163-165`; `HardwareConstants.java:668-688` |
| T6 pairs | `s=215*(clamp(a,25,50)-25)/25`; left=`1-s/300`, right=`s/300`; 25°→(1,0), 44°→(.4553333,.5446667), 50°→(.2833333,.7166667); turret outputs equal | `HardwareConstants.java:668-688`; `TurretPidPazarSubsystem.java:309-310` |
| T7 shared port | shooter writes R=`p`, L=`p*follower`; speed reads RIGHT; turret reads `shooterLeft` position/sign/gear and writes only both CR outputs | `ShooterPidfPowerSubsystem.java:268-275`; `TurretPidPazarSubsystem.java:146-212,298-310` |

These vectors define what a later A04/B01 fixture should compare; they do not claim
that the current Java core, adapter, plant or physical robot already produces them.
No `legacy-behavior-matrix.md` is created.

## A05 baseline manifest — p11a-baseline-v1

This is the sole Chapter A baseline manifest. The annotated D tag identifies the
docs commit containing this section; the compatible R/S source pins are immutable.
The record-signature protocol gate is satisfied at ftc-main pin `7447546`. The tag
does not authorize source or protocol edits; Chapter B becomes eligible only after
this A05 evidence commit and `p11a-baseline-v1` tag are verified.

| Slot | Accepted pin(s) | Accepted outcome |
|---|---|---|
| A01 | S `5ba0a9671eeedc84f2a628ff970133c1e86f656f` (contained by final S `4cc1201f6ba4861815f37625cc03ea973a84755f`) | Fragmented I/O, reset/step barrier, and integral event validation accepted; the A01 focused three-test check and prior full 85/85 suite were green with no skipped tests. |
| A02 | R `97995cafe65db9114dd1bdde9a251cdb9aa1bd47`; S `5849e58fc74e7e294bf61a48d1ca7a2cdcf98b03` plus final `4cc1201f6ba4861815f37625cc03ea973a84755f` | The cross-review escalation found the PyBullet 12 kg literal at `sim/physics/pybullet_backend.py:185-201`; ftc-main authorized the narrow backend-agnostic `ROBOT_MASS_KG` fix. Final S binds both rigid-body backends to parsed mass and its 18 kg fixture/inertia checks pass; R cancellation/deadband regressions are in the accepted lineage. |
| A03 | Final R `72d3ac9fa81209f5bf31fd88eb1b99927bfdcaee`; final S `4cc1201f6ba4861815f37625cc03ea973a84755f` | The R-owned runner exited `0`: six A-drive runs at 1000 ticks each (direct/cplx1, seed-1 repeat and seed-42 coverage) and two A-cancel runs at 101 ticks each. The earlier S `635741dbb7fd5c9ef1fe0c3190ddfe6cd7883cf4` remains WIP history, not an acceptance pin; this acceptance is post-A02. |
| A04 | OLD `d7711d043280034ab5c75ae26a253629fd2d4a7b` and the source-grounded handoff | Preserve/correct/defer archive behavior and actuator traces are recorded with file-line sources; this is provenance analysis, not a physical-robot result. |
| A05 | R `72d3ac9fa81209f5bf31fd88eb1b99927bfdcaee`; S `4cc1201f6ba4861815f37625cc03ea973a84755f`; D = this docs commit | Stable registry selects direct `0`, cplx1 `1`, and alias `cplx_engine_1` without renumbering. Registry/switch regressions, the baseline runner, and the binding build command are green; the requested annotated tag points to this D commit. |

### A05 verification commands and gates

- R binding command, run at final R: `JAVA_HOME=/usr/lib/jvm/java-21-openjdk
  ./gradlew :core:test :sim:test :sim:installDist` — **BUILD SUCCESSFUL**;
  XML totals are **127 core tests + 11 sim tests, 0 failures/errors/skips**.
- S focused command: `PYTHON="$PWD/.venv/bin/python" ./run_tests.sh
  -k acceptance_scenarios` — **2 passed, 0 skipped**. S full command:
  `PYTHON="$PWD/.venv/bin/python" ./run_tests.sh` — **93 passed, 0 skipped**.
- Runner traces satisfy the required schema and finite-value checks at 20 ms
  cadence. Every A-drive run ended with one `DONE` status within the .5 in/1°
  target gate; A-cancel ended non-`DONE`, carried switch IDs 60/80, and held all
  wheel outputs at zero from cancellation onward. Seed-1 repeats are byte-identical
  per engine; all eight owned server ports were free after cleanup; the 30 s Java
  timeout-bound test passed.

### Limitations retained at the checkpoint

- A03 is the Pymunk host acceptance only. It does not validate PyBullet/kinematic
  parity, a Control Hub, physical Pinpoint/mechanisms, or real-hardware cadence;
  shooter, intake, and turret production actuators remain outside this baseline.
- An extra non-binding `:TeamCode:assembleDebug` attempt hit
  `java.lang.OutOfMemoryError: Java heap space` in Android `ApkFlinger`/zipflinger.
  This is an environment limitation, not a product failure; no build configuration
  or source was changed, and it does not block the binding core/sim/installDist gate.
- A04 outcomes are archive-derived behavior and source citations, not current
  hardware measurements. No training, reviewer, ball, phase transition, or protocol
  edit is included in this checkpoint.

## Safety and publication boundary

Only this requested docs commit and the `p11a-baseline-v1` checkpoint tag are
authorized by this ledger; no source, protocol, reviewer, ball, training or phase
change is included. The protocol gate is satisfied at `7447546`; Chapter B becomes
eligible only after this evidence commit and tag are verified. Future evidence must
separate `unit-tested`, `sim-integrated`,
`Android-built`, `archive-derived`, and `hardware-validated`; the last label remains
absent until a physical robot is available.
