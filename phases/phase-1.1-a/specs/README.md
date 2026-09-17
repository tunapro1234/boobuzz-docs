# Phase 1.1-a spec pack v2 — review before implementation

Status: **DRAFT v2, 2026-09-17. No implementation dispatch or training authorized.**
Authority: [Tuna's decisions and reviews](../review-ftc-main-specs-2026-09-17.md).
Every chapter uses [hardware-profile-v0](../hardware-profile-v0.md).
Starting commits: R `d5bda62`, S `5dd6daa`; remain on `dev-phase-1.1-a`.

## Binding decisions

1. Preserve `contract / hal / subsystem / logic / controller` and shared Java core.
   Keep R's `sim` as a thin adapter, not a second robot implementation.
2. ONE intake motor, ONE feeder motor, ONE single-flywheel shooter, ONE hood servo,
   ONE turret CR servo; POLLEN only. Archive is a behavior/calibration/name reference,
   NOT a mandate to reproduce its multi-actuator hardware.
3. RealHal keeps archived HardwareMap names, including drive names, `shooterRight`,
   encoder-only `shooterLeft`, `turret_servo`, `hood_left`, `intake_dist`. No device
   renaming/reconfiguration required. Mechanical compatibility still needs bench proof.
4. Gall's law: preserve the previous useful engine; add one composed module, not a
   copied engine. Each release must support a complete useful operator workflow.
5. Commit/push working increments. Tags/manifests ONLY at A05 baseline and engine
   checkpoints. Evidence per chapter; cross-review ONLY R/S seam changes.
6. Acceptance is a few Java-on-Pymunk scenarios, not test counts. Focused unit tests
   support the demos. Software acceptance does not claim hardware validation.

## Detail near, sketch far

| Spec | Status / purpose |
|---|---|
| [00 Common](00-common.md) | Actual contracts, composition and lean acceptance |
| [01 Baseline](01-baseline.md) | A01–A05 worker detail: files, tests, seeds, thresholds |
| [02 Devices/intake/feeder](02-intake-feeder.md) | B01–B04 worker detail; owned protocol migration |
| [03 Mechanisms/cplx1](03-mechanisms-cplx1.md) | B05–B09 worker detail; single devices, three e2e gates |
| [04 Shooting](04-shooting-cplx2.md) | Historical detail preserved; C outline below governs until refined |
| [05 Vision](05-vision-cplx3.md) | Split into Vision-A/B below; refine after B09 |
| [06 Range](06-range-cplx4.md), [07 Game](07-game.md) | Roadmap only; preserve bodies, revise after B09 |
| [08 Environment](08-environment.md), [09 Learning preparation](09-learning-preparation.md) | Roadmap only; no training or early implementation |
| [10 Research](10-research.md) | Reference; corrected topology, remaining issues deferred |

Only A/B are near-term worker-ready proposals. Far-draft details are NOT frozen
contracts or work orders. Read hardware profile + 00 + assigned section, not 42 tasks.

## Composed engine ladder (future indices reserved, not implemented)

| Index/name | One addition | Useful behavior |
|---|---|---|
| 0 `direct` | Separate guarded diagnostic baseline | Mechanism exercise/recovery |
| 1 `cplx1` | Shared base coordinator | Drive, intake/reverse, fixed-preset aim/feed |
| 2 `cplx2` | ShotSolutionModule | Stationary distance solution, preset fallback |
| 3 `cplx3` / Vision-A | ImageAimModule | AprilTag/simple detector input; screen-offset/size PID aim/approach; no map |
| 4 `cplx4` / Vision-B | WorldModule | Spatial/3D interpretation, ball distance/tracking, sector scan |
| 5 `cplx5` / range | RangeAssistModule | Range-only reflex, then justified fusion |

Keep existing indices0/1 and `cplx_engine_1` alias. This supersedes v1's world/range
numbering; no released third engine exists to renumber. Vision-A works without B;
its bounded approach is operator-enabled and stops on stale detection. Vision-B
load beliefs wait for actual modeled target mechanics, not imaginary Hive truth.

## C — medium-depth outline

- C01: primary archive source is `config/logic/AdvancedLogicConstants.java`,
  `Solvers.Ronaldo.lookupTable` (distance/hood/minRPM/maxRPM). The four hood=38 video
  fits are NOT a distance table. Quarantine Ronaldo LINEAR/POLY TODO coefficients
  and unsupported R² claim. B08 owns replacing real-mechanism use of the current
  `ShooterCalibration` 300+distance/zero-hood placeholders with a fixed preset.
- C02: proposed `logic/shot/ShotSolver.java`: group table rows by distance; choose
  the hood row closest to the cplx1 45° preset (lower hood breaks ties), then RPM =
  minRPM + .55*(maxRPM-minRPM). Interpolate resulting hood/RPM pairs; reject outside
  [43.3,90.7] in or unsupported height (an intentionally conservative subset: the
  actual table also contains longer distances). This is a documented NEW simplification,
  not the archived placeholder LINEAR algorithm. Pollen/single-flywheel calibration
  remains unverified; old multi-actuator data cannot prove the new launch mapping.
- C03: upgrade B08 planar release to height-aware flight/contact including barrel
  world velocity from chassis/turret motion. No RK4 program. Target dimensions go
  into RobotConstants and the S parser, not pixel measurements of field artwork.
- C04/C05: solver field azimuth is radians CCW from +x; B07 maps it through bounded
  relative-angle API. ShotSolutionModule supplies shared TurretLogic/ShooterLogic.
  Gate: pickup-drive-stop-shoot at two ranges plus invalid-range preset fallback.

## Far roadmap only

Vision-A then Vision-B; range reflex before fusion; full game/tipping/clock/scorer;
deterministic controller environment; inert model/reward/data/inference preparation.
Nectar remains in the game, never our inventory. After B09, consider inexpensive
controller/inference/xRC feasibility spikes independently of full-game fidelity;
do not assume they must wait behind all F. No learning runs of any kind.

[Review disposition](../spec-v2-review-disposition.md) maps findings to revisions.
Next: Tuna reviews v2. Only documentation publication is delegated now.
