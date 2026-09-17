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
