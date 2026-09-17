# Phase 1.1 continuation — orchestrator log

## 2026-09-17 — coordination handover

- Tuna delegated today's orchestration to ftc-main-cx; ftc-main steps back.
- Scope remains Phase 1.1. No phase transition, closure/tag, reviewer launch or ball work.
- Verified all three workers created and pushed dev-phase-1.1-a:
  robot-code 4b8ba23; re-cock-nize 518bf9c; docs 9f5ce5d.
- Docs branched from stable because no dev-phase-1.1 branch existed there.
- Robot/docs worktrees clean; simulator's pre-existing untracked .claude/ preserved.
- Read protocol, design/revisions, prior task specs/reviews and latest code logs.
- First round: robot-cx-22 existing subsystem contracts; sim-cx-21 independent R8
  review and network determinism proof; docs-cx-10 evidence ledger/architecture.
- Cross-review is robot ↔ sim at immutable published hashes. Follow-on reviews
  and hardware-facing gap analysis are pre-chained to avoid idle workers.
- Each tested working change must be committed and immediately pushed. Docs-cx
  is the single git writer for shared task specs, logs, reports and reviews.
- Direct tmux delivery is explicitly requested in the current handover; verified
  worker panes are %40 robot, %41 sim and %47 docs, all gpt-5.6-luna max.

## 2026-09-17 — R9/R8 worker snapshots

- robot-cx-22 completed and pushed robot-code `1e555cb` (turret hold cancellation
  and regression test), then `d5bda62` (audit/report artifacts). The published
  report is `robot-cx-22-report.md`; its full verification reports 122 `:core`
  tests, 10 `:sim` tests, both SDK guards, and `:TeamCode:assembleDebug` green.
- robot-cx-22's hardware inventory confirms that `Hardware`/`RealHal` expose
  wheel motors, Pinpoint, voltage and gamepad only; shooter/intake/turret remain
  Phase 2 stubs. No source files outside the selected turret fix were changed.
- sim-cx-21 published `review-robot-r8-sim.md`, reviewing robot `4b8ba23` at
  immutable hash with zero findings; focused tap/socket/bag tests and a 1,000-tick
  Pymunk Java smoke passed. `review-robot-r8-sim.md` is ready for docs staging.
- The R9 robot report pins `review-sim-cx-21-robot.md` against simulator `518bf9c`.
  It records one major multi-robot socket deadline gap and two minor gaps
  (fractional event timestamps and fresh-process determinism); these are simulator
  findings, not robot changes.
- sim-cx-21 reproduced the fresh-process staggered-start race and pushed simulator
  `78bad12`, adding the connection/reset startup barrier, followed by `5dd6daa`,
  which compares exact process-boundary JSONL transcripts. The final report records
  83 Python tests, 8 multi-robot tests, 2 process-network tests and isolated Java
  smoke against robot `4b8ba23`.
- `review-robot-cx-22-sim.md` reviews robot `d5bda62` against simulator `78bad12`:
  zero blocker/major, one coverage-only minor because the new turret-hold test does
  not exercise `scanEventPending`; the implementation itself clears that state.
- Docs now stages `sim-cx-21-report.md`, `review-robot-r8-sim.md`, and
  `review-robot-cx-22-sim.md` only after the worker published the stable simulator
  hash. No protected document, tag, reviewer, ball task, or phase transition was
  touched.

## 2026-09-17 — revised intent and planning hold

- Tuna clarified that phase-1.1-a is the branch lineage, not a freeze on the old
  Phase 1.1 feature scope. Detailed new subsystem/shooting/vision/range/game/RL
  direction is preserved in tuna-intent-2026-09-17.md.
- New priority: simulator baseline, archived mechanism behavior, practical shooting,
  turret Limelight scan/world model, chassis range fusion, then full-game/RL readiness.
  No training, ball agent or reviewer launch. Accepted checkpoints now require tags.
- Tuna then requested a detailed roadmap written personally by ftc-main-cx and
  discussed together BEFORE distributing new work. Existing workers were told to
  finish their current checkpoint and hold; no new implementation goal was started.
- ftc-main-cx wrote roadmap-v1.md as a discussion draft, with framework choices,
  ordered work packages, simulator counterparts, engine fallback ladder and gates.
- This supersedes the earlier no-tags/strict-old-spec execution assumptions.
  Historical protected documents remain unchanged. This is a documentation-only
  planning checkpoint; the roadmap itself is not approved implementation scope.

## 2026-09-17 — detailed review pack, pollen-only clarification

- Tuna requested executable-spec-level substeps before any dispatch, emphasized
  Gall's law, preserving layers and useful standalone engine releases, and clarified
  the north star as AI driving during teleop. No training, including imitation
  learning, is authorized. The planning hold remains active.
- Tuna clarified our intake collects small pollen only, not nectar. Specs distinguish
  robot collection scope from full-game nectar physics, obstruction and scoring.
- ftc-main-cx personally prepared `specs/README.md` and 00–10: 42 bounded tasks across
  baseline, device/mechanisms, cplx1–4, field/game, Gym environment and inert learning
  preparation. Each task includes implementation behavior and acceptance/fault cases;
  common gates supply release, ownership, commit/push, review and tag requirements.
- Primary-source research informed Pymunk/flight scope, Limelight integration,
  lightweight tracking, official game/deployment constraints, Gym terminal semantics,
  PPO/BC preparation and Android inference feasibility. Unknown physical calibration,
  camera pipeline, xRC export and Control Hub timing are explicitly not claimed solved.
- Only the separately requested control-document note was delegated to ftc-docs-cx.
  BP channel q655384762 was queued behind earlier unsubmitted messages. After Tuna
  authorized checking the screen and pressing Enter for stuck messages, the existing
  visible messages were submitted without clearing/retyping input. Channel later
  reported DELIVERED; recipient screen confirmed note commit `da8f7d3`, pushed and
  returned to hold. Note path: `control-doc-notes.md`; Astra/Fable and Luna Max are
  documented as user-named working role/model labels.
- No implementation spec was dispatched, no goal started, no robot/sim source edited,
  no dependency installed, no model trained and no tag created for this draft.
- Documentation checks: 12 spec files carry draft notices, 42 unique contiguous
  task IDs, 22 internal links resolve, observation schema arithmetic is 292 scalars
  per frame / 1,168 for four frames; git whitespace check passes. Code/physics test
  runs are future acceptance requirements, not tests rerun for this prose change.
- Next action is Tuna's review/discussion, not execution. Preserve all worker changes.

## 2026-09-17 — spec v2 after ftc-main/Tuna review

- Read the complete review-ftc-main-specs-2026-09-17.md and checked relevant current
  Java/Python/archive sources. Binding topology is one flywheel/hood/CR turret/intake,
  plus feeder; hardware names retained, including archive wheel names.
- Rewrote README/00/A/B and added hardware-profile-v0.md and the review-disposition
  note. Owned explicit millisecond/status/servo/protocol/parser/aim/planar-release
  corrections, concrete tests/seeds and three B09 e2e scenarios. No code implementation.
- Reduced process to chapter evidence, seam-only cross-review, baseline/engine tags.
  Composition uses the existing coordinator; Vision-A precedes Vision-B and range.
- Far04–10 retain prior detail with superseded/known-issues headers. Only requested
  hardware/encoder corrections in10 and broad roadmap topology were rewritten;
  C's corrected medium outline is in README. Further E–H work waits until after B09.
- Archive checks resolved shooterRight velocity vs shooterLeft turret; flagged28/1.6
  comment mismatch; separated default500-ms gap from match-used100-ms override and
  confirmed LEFT hood mapping. Matching names is not mechanical validation.
- Docs worker is to publish the original review plus this v2 and report hash, then
  hold. No implementation goals, code changes, installations, training or draft tags.
- Local documentation checks passed: 12 spec files reference hardware-profile-v0,
  49 relative links resolve, all14 A/B task headings are present,04–09 bodies are
  byte-preserved after the new header, hood/RPM/feedforward fixture arithmetic is
  consistent, git diff --check clean, protected documents unchanged. Review SHA-256:
  117674815998fce3f99de8aa9929287472db568a2401ca49bfb8edc2763dc2b1.

## 2026-09-17 — v2.1 correction: mechanisms are not actuator counts

- Published v2 was docs commit3969cc2. Its single-actuator topology was WRONG;
  the orchestrator failed to reconcile the review wording with archived active
  construction/output code. Tuna directly clarified: preserve last season's
  mechanism counts AND motor/servo counts. This overrides the review topology,
  not the accepted near/far, engine-composition or lean-process decisions.
- Rechecked archive robot-code d7711d0: Blue/RedTeleop -> lvbelc5/Robot constructs
  ShooterPidfPowerSubsystem, HoodSubsystem, TurretPidPazarSubsystem, Power intake
  and feeder. ONE shooter has2 DC motors; ONE hood has2 complementary position
  servos; ONE turret has2 equally commanded CR servos. Intake1, feeder1, drive4.
- Critical shared port: shooterLeft is an ACTIVE shooter motor output, while its
  encoder input measures turret. Removed the erroneous encoder-only/force-zero
  plan; Hardware binds once, power ownership remains shooter, input source turret.
- Revised profile, README/00/A/B, targeted research/roadmap statements, intent and
  review disposition. Added source file:line evidence, exact paired hood fixtures,
  paired stop/hold/validation and shared-port isolation acceptance requirements.
  B's small plant approximations are labeled, not inferred mechanical shaft layouts.
  Kept one state/controller per mechanism and the existing three engine demos.
- Original review retained verbatim for provenance; current index/intent/profile
  explicitly supersede its single-actuator interpretation. Far04–09 and protected
  protokol/design-spec unchanged. No robot/sim source edits, implementation dispatch,
  new goal, training, dependency changes or draft tags. Existing untracked S/.claude
  and archive/.gradle-user-home are unrelated and untouched.
- Docs worker is authorized only to verify/publish this correction on
  dev-phase-1.1-a, report commit/push/hash and hold. Tuna reviews before execution.
- Documentation checks passed:63 relative links,14 near-task headings, four paired
  hood fixtures and4000-RPM/feedforward arithmetic, git diff --check. Original review
  hash unchanged; far04–09/protected documents unchanged; R/S HEAD still d5bda62/
  5dd6daa. These are document checks, not a claim of newly run robot/physics tests.
