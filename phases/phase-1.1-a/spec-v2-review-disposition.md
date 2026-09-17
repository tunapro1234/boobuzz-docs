# Spec v2.2 disposition — Chapter A released; B gated

Status: **Tuna-approved v2.2 (2026-09-17). Chapter A is released now. A02 is
unblocked at protected pin `26f915b`; B is approved but gated, with B01 blocked
pending the ADR signature pin, until A05/evidence/tag. C and the far roadmap remain
unreleased. Training, ftc-reviewer, and ftc-ball remain forbidden.** The [full review](review-ftc-main-specs-2026-09-17.md)
is preserved verbatim, but its single-actuator interpretation and our v2 response
are superseded by [Tuna's direct clarification](tuna-intent-2026-09-17.md).
Mechanism count is NOT motor count. Files below use [current index](specs/README.md) and
[hardware-profile-v0](hardware-profile-v0.md). This disposition does not dispatch B
implementation. The protected protocol gate is already approved: ftc-main published
amendment `26f915b`, and docs reconciled it at `0973e86`.
"Addressed" means the specification names the behavior/owner/test; code remains at
R d5bda62 / S 5dd6daa. Far findings are deliberately not claimed implemented/resolved.

## Section 3 — all near-term findings

| Review IDs | V2 disposition |
|---|---|
| F1–F5 | Single-actuator recommendation REJECTED by latest direct Tuna clarification. Corrected profile/B01/B05–B07 preserve ONE shooter with2 motors, ONE hood with2 complementary servos, ONE turret with2 CR servos. Active constructors and power/position writes are cited; preserve followerScale and directions. |
| F6 | 00 preserves actual ACTIVE/DONE/FAILED/REJECTED; cancel stays REJECTED+note, not imaginary CANCELLED/FAULTED. |
| F7 | 00/A01/B01 use integer ms; no microseconds. |
| F8 | 00 preserves actual five-stage RobotLoop; B01 owns ActionValidator inside HAL writes; Pedro updates only in PedroDrive. |
| F9 | B01.0 owns ADR/protokol approval and proto2 sparse-servo hold; RealHal, SimHal fill removal, server/plant behavior, fixtures/test names explicit. |
| F10–F11 | Profile/A04/B01/B04: capacity3 and unused intake_dist; shooterRight speed vs shooterLeft turret resolved. shooterLeft ALSO actively drives the shooter; bind once, separate input/output roles, test isolation. Verify28 ticks/1.6 ratio physically. |
| F12 | A02 describes actual Java regex input, adds mass to binding scalar contract/parser/backend; keeps12 kg baseline. |
| F13–F14 | B01 lists single-line Java declarations and exact parser extension; explicit version/name lists, no unsupported capability negotiation. |
| F15 | A04/A05 extend existing gamepad-map-analysis, teleop-map, request-catalog rather than duplicate inventory. |
| F16–F17 | A01 fixes actual fractional truncation; A03 names a NEW harness and separates target vs sensor error, citing actual predecessor evidence. .5in/1° is a new stated gate, not a fabricated inherited tolerance. |
| F18–F19 | A/B contain named paths/test classes/seeds. A05 owns registry/order/alias replay fixtures before a third engine. |
| F20–F21 | Profile/B03/B06/B07 give exact pulse/gap/hood/turret constants. V2.2 corrects v2.1:350-ms pulse PLUS100-ms post-pulse delay;500 field is unused, not an active default. Recovery45° is RecoveryController:29, not HC.Hood. |
| F22–F23 | B08 owns 200-ms Pinpoint motion estimate/filter validity; A04 gives actual controllers/ source path. |
| F24–F25 | 00 gives checkpoint-only tags, chapter evidence and seam-only cross-review; B01 omits unused digital/analog, B07 introduces consumed analog. |

## Section 4 — findings affecting near-term/shared files

| Review IDs | V2 disposition |
|---|---|
| B1–B2 | 00 explicitly reserves D/E ADR/protocol-version, state.vision/range, RobotState batching/IHal unchanged, Hardware/RealHal/SimHal/constants/parser owners; B01/B07 schedule present CR/encoder/analog changes. Actual future sensor implementation waits. |
| B3–B4 | README's medium C outline uses AdvancedLogicConstants lookup groups, quarantines TODO/R² claims and specifies deterministic row reduction/min-max blend. 43.3–90.7 is a conservative subset, not the table's full extent. |
| B5 | B08 explicitly owns real direct/cplx1 fixed preset4000/45°/0°; legacy ShooterCalibration remains only in stub profile with updated consistency tests. No real300-RPM default. |
| B6 | B07 owns aimRelative/AimResult, target setter and hold/disable distinction; B08 removes blanket cplx1 aim rejection and arbitrates shot ownership. Future solver uses same setter. |
| M1 | A05 registry and v2 README reserve stable indices; Vision split adds an engine before range without renumbering existing0/1. |
| M7 | B08 explicitly creates planar physical release; C header says flight is its later upgrade. B09 tray demo is NOT elevated-goal/ballistics proof. |
| M8 | B01 early object dimensions in RobotConstants/parser; README C assigns true target geometry there, retains GOAL_* only as legacy placeholders until replacement. |
| Mo1/Mo4 + servo-rejection minor | Single-motor conversion rationale withdrawn: topology stays archived. Pollen/launch calibration and physical tuning still unverified. Concrete paths/tests/seeds; B01 removes nonempty-servo rejection, tests both hood outputs and shared-port semantics. |

Other section4 range/vision internals remain retained historical text with header
warnings, not approved instructions. Vision-A is AprilTag/simple detection/PID with
no map; Vision-B receives former D03/D04 spatial/tracking/sector work. Full target-
load beliefs need modeled targets. No attempt to rewrite all D/E now.

## Section 5 and scope boundary

All far files04–10 keep their bodies (10 gets the requested topology/encoder correction)
and a prominent review/header warning. E–H have not been refined. Early dimensions
moved to B01; hardware/tag/process contradictions corrected in governing near files.
Far clock ownership, synchronous environment transport, match block, obs producers,
owner table, learning/no-optimizer, game/referee and dependency findings remain
the post-B09 checklist. README notes cheap feasibility spikes can be reconsidered
after B09 without requiring all F first. No code, installs, model construction or training.

## V2.2 follow-up verification at archive d7711d0

- Counts/names/directions stay8 DC/2 Servo/2 CRServo. Corrected source citations
  distinguish left/right bindings and executable position/power writes from signatures/comments.
- Profile/B01 pin shooter FLOAT, intake/feeder BRAKE, shared turret encoder FLOAT;
  existing drive BRAKE unchanged. Archive's competing turret reset and feeder reset
  are explicit; new central ownership is an intentional fix, not a preserved fact.
- B02/B08 preserve shooting intake.8 versus default1. HC holdPower.2 is recorded as
  declared but unused. B05 names live ShooterPidfPowerStorage provenance and a narrow
  runtime-tuning snapshot port, with deterministic fixed-default fixtures.
- Profile/B01 explicitly distinguish planned declarations from today's fl/fr/bl/br,
  SERVOS={}; parser extensions are future work, not implemented capabilities.
- Pinpoint pod-axis mapping161/0, FORWARD/REVERSED, goBILDA_4_BAR_POD is pinned;
  HC -84/-168 is unused. New xPodOffsetMm measures forward POD's lateral offset,
  not Cartesian X: preserve SDK argument order, do not swap it. Adapter tests named.
- Limelight is active in archived LocalizerController with graceful absence. B's
  odometry-only subset is intentional staged scope; Vision-A still owns its port.
- Turret maxPower1 and aim-assist10°/.3/.8 are documented without adding a new
  chassis assist. No other topology/layer/process/phase or far-chapter changes.

## Documentation validation and handoff

Check relative links, hardware-profile references, A01–A05/B01–B09 headings, unmodified
review text, unchanged protected protokol/design-spec, and far-body preservation.
Numerical fixture checks: hood25/44/45/50°,4000-RPM ticks conversion/feedforward.
These are plan checks, not robot/physics test runs. Chapter A release is recorded here;
B remains gated until A05/evidence/tag. No draft tags.
