# Phase 1.1-a — detailed plan for Tuna's review

Status: **DRAFT — NOT AUTHORIZED FOR IMPLEMENTATION OR WORKER DISPATCH.**
Prepared 2026-09-17 by ftc-main-cx. No training is authorized, including imitation
learning. The sole worker follow-up during this draft is Tuna's separate request
to preserve agent-organization notes for the eventual control document.

This pack expands [roadmap v1](../roadmap-v1.md). Where they differ, this pack is the
new proposal, not an already-approved change. Read [Tuna's intent](../tuna-intent-2026-09-17.md)
after compaction. Remain on `dev-phase-1.1-a`; do not rewrite historical contracts.

## The governing design

Build a small working robot, then extend it. Preserve `contract / hal / subsystem /
logic / controller`, shared Java control code, and selectable simpler engines.
RL is the north star: eventually an onboard controller drives during teleop while
the same tested engines operate mechanisms. RL is not a dependency of a useful robot.

Our robot collects **POLLEN only**. Do not build a nectar-intake path, nectar shooter
calibration, dual-size inventory, or a nectar collection policy. Nectar remains an
external game object: it can obstruct, appear in observations, and affect the score
and field mechanisms. Detecting pollen must not mean treating every round object as
collectable pollen. Actual physical rejection is a mechanical assumption to verify.

Every microstep leaves the last accepted engine runnable. Publish a NEW engine only
when it supports a complete operator workflow, has no required mechanism stubs,
passes fault tests, and preserves manual recovery. An engine is not a name for every
commit. With no robot available, releases are **competition-oriented software
candidates**, not hardware-validated or inspection-certified robots.

## Read order and executable work units

Each numbered task below is a bounded future assignment. Its entry conditions,
implementation, tests, exclusions and exit are in the linked file; the common gate
is mandatory in addition to its local gate. Do not hand an entire chapter to a worker
as an unbounded goal. Fill execution hashes from the previous accepted manifest.

| Order | Spec | Small tasks | Result available at this checkpoint |
|---|---|---|---|
| 0 | [Common contract and release gates](00-common.md) | All tasks | Consistent ownership, evidence and fallback rules |
| 1 | [Baseline and last-season behavior](01-baseline.md) | A01–A05 | Trustworthy current chassis; traced old controls |
| 2 | [Device seam, intake and feeder](02-intake-feeder.md) | B01–B04 | Real actuator paths; pollen-only capture and feeding |
| 3 | [Shooter, hood, turret, cplx1](03-mechanisms-cplx1.md) | B05–B09 | Complete low-complexity fixed-preset teleop robot |
| 4 | [Shot calculation and flight, cplx2](04-shooting-cplx2.md) | C01–C05 | Calibrated stationary distance-based shooting |
| 5 | [Limelight, tracking, scanning, cplx3](05-vision-cplx3.md) | D01–D05 | Vision-only world model and useful scan/shot scheduling |
| 6 | [Chassis range and fusion, cplx4](06-range-cplx4.md) | E01–E04 | Conservative obstacle response and bounded fusion |
| 7 | [Faithful game and full-match integration](07-game.md) | F01–F04 | Scoring, tipping, match clocks and multi-robot fixtures |
| 8 | [Gymnasium and controller seam](08-environment.md) | G01–G05 | Auditable RL-ready environment, no learner |
| 9 | [Model/reward/data/deployment preparation](09-learning-preparation.md) | H01–H05 | Inert learning configs, dataset schema, inference feasibility |
| Reference | [Research and decision record](10-research.md) | No work order | Sources, choices, alternatives and unresolved evidence |

The order is deliberate. C01 reads only enough field geometry for honest shot tests;
complete game physics stays in F. There is no hidden requirement to build F before
using cplx1–4. Controller/environment work must not introduce an RL dependency into
the robot's normal build.

## Engine ladder — what the driver can actually use

| Release | Complete behavior | Added dependency | Loss-of-capability response |
|---|---|---|---|
| `cplx1` | Drive, pollen intake/reverse, flywheel, hood, bounded turret, fixed-preset shots, abort/recovery | Mechanism feedback and inherited profile | Fault affected mechanism; drive/recovery remain available |
| `cplx2` | All cplx1 functions plus stationary distance-based solutions | Valid pose/target and shot table | Fixed preset/manual aim; no blind auto-feed |
| `cplx3` | All cplx2 functions plus sector scan, tracks and target-load estimates | Single turret Limelight | cplx2 behavior; uncertain world state is shown as uncertain |
| `cplx4` | All cplx3 functions plus range braking and conservative fusion | Configured range devices | Explicit degraded/manual mode; no fabricated free space |
| Policy controller, later | AI chooses driving actions during teleop through one of these engines | Approved onboard model and authority switch | Immediate human takeover or zero drive on policy fault |

`direct` remains a guarded diagnostic/recovery mode, not a claim of autonomous
competition completeness. The present stub-based cplx1 is the starting scaffold;
B09 is its first mechanism-complete candidate. We do not create `cplx5` merely to
change the driver from human to policy.

## Decisions proposed for discussion

1. Restore last season's match-used button semantics as a named `legacy-match`
   profile, retaining the present map as `diagnostic`. Do not silently replace it.
2. Use the archived dual-flywheel, paired-hood, dual-CR-servo limited turret as a
   provisional hardware profile. Its calibration is not automatically pollen-valid.
3. Shoot while stationary first. Keep empirical calibration primary; use elementary
   projectile calculations as checks/initial estimates, not an RK4 project.
4. First learned controller controls three driving demands only. Driver/engine
   handles shooting and intake initially; full automated strategy is a later action
   schema, not a prerequisite for AI-driven teleop.
5. Keep Pymunk; add only height-aware ball flight and a small one-axis Hive model.
6. Choose simple classical tracking first. A learned world model is a separately
   gated experiment, never a dependency of cplx3/cplx4 or the first environment.

Unknown physical wiring/calibration is recorded, not guessed into a production
profile. Serious evidence may change the plan through a short decision record.
The next action after this deliverable is Tuna's discussion, not execution.
