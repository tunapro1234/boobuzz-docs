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

## 2026-09-17 — v2.2 archive-provenance follow-up

- ftc-main relayed the follow-up verification and required corrections; checked
  archive d7711d0 directly. Topology remains8 DC/2 Servo/2 CRServo. Corrected source
  line citations for separate bindings and executable paired writes/computations.
- Corrected active feeder timing to350-ms pulse PLUS100-ms post-pulse delay;
  HC postPulseDelayMs500 has no references. Recovery hood45° is RecoveryController:29.
  Shooting intake.8 is active; HC holdPower.2 is declared but not used by active path.
- Profile and B01 now name all relevant BRAKE/FLOAT settings and planned adapter
  tests. Archive turret DOES reset/reconfigure shooterLeft after shooter setup;
  feeder also resets. New central reset/configuration ownership is an intentional
  correction, not an archived guarantee.
- Shooter PIDF/readiness reads runtime dashboard-tunable ShooterPidfPowerStorage;
  HC values are boot defaults. B05 adds a narrow SDK-free tuning snapshot proposal,
  with trace/replay and fixed-default fixture requirements, not a tuning framework.
- Pinpoint preserves161/0 mm, FORWARD/REVERSED and goBILDA_4_BAR_POD. New field x/y
  names identify measured pods, not spatial offsets; SDK argument order is correct.
  Unused HC -84/-168 is explicitly quarantined. Planned B01 declarations/parser
  changes are distinguished from current fl/fr/bl/br and SERVOS={}.
- Limelight actively participates in archived LocalizerController and tolerates
  missing hardware. B intentionally remains odometry-only; Vision-A owns the port.
  Turret maxPower1 and aim-assist10°/.3/.8 are recorded without enabling new assist.
- Updated profile, README/00/A/B, disposition and compaction intent. Original review,
  protected documents and far chapters unchanged. No code edit, implementation
  dispatch, install, training or tag. Docs worker publishes v2.2, then holds.
- Documentation validation:9 scoped files,31 relative links in changed files,
 14 A/B headings, paired hood arithmetic and350+100-ms tick boundaries passed;
  git diff --check clean. Original review SHA256 unchanged. R/S HEAD remain
  d5bda62/5dd6daa; these are documentation/source checks, not new physics test runs.

## 2026-09-17 — saved before user-requested compaction

- V2.2 publication confirmed on origin/dev-phase-1.1-a:
  `7423ed639020d033f4f3e55f27b223345fd7a1e0`; docs clean after publication.
- Tuna asked for small tasks and Luna workers stopped around12:10 local
  America/Chicago (17:10 UTC) for a possible model switch, then superseded the
  readiness check with "save final records, then compact." No implementation began.
- BP status observed ftc-robot-cx, ftc-sim-cx and ftc-docs-cx idle. Only docs may
  briefly publish these handoff notes, then hold. No model switch or launch.
- Readiness boundary: A/B are detailed proposals, not an approved execution order;
  C medium, far chapters deferred. ADR/protocol gate still applies before affected
  A02/B01/B07 changes. Do not claim the entire far roadmap is implementation-ready.
- Intent file now pins source/spec hashes, stop time, optional11:50/12:00 buffer,
  planning hold and resume reading order. No change to protected docs or code.

## 2026-09-17 — Chapter A A00/A02 documentation dispatch

- ftc-watchdog authorized a documentation-only release cleanup and A02.0 ADR draft
  from docs `e5796b7c1b005d4c1559d5339621c99080de0903`; planning pins remain robot
  `d5bda622d5bba6dfef6c4bfefed69e0cc20d7e67`, simulator
  `5dd6daacedbd629deb0827b36240f3064a808f3b`, archive `d7711d043280034ab5c75ae26a253629fd2d4a7b`.
- Fixed message/goal prefix requirements were removed from the owned task/spec
  files; the English-content rule remains. No implementation order is inferred.
- Added `adr-device-seam-v2.md`: current proto1 versus proposed proto2 semantics,
  paired device/type/name ownership, units, validation, servo-hold/DC-CR-zero rule,
  Java-source `ROBOT_MASS_KG` parsing in kg, missing/invalid failure, isolated 18 kg
  fixture, and explicit ftc-main protocol approval/migration gates. `protokol.md`
  and `phase-1.1/design-spec.md` were not edited.
- Added `evidence-A.md` as the sole Chapter A ledger with approved pins and A00–A05
  slots. It records no unrun outcomes; A04 is held pending ftc-watchdog's
  source-grounded handoff.
- No robot/simulator source, reviewer, ball, training, tag, phase or goal action was
  taken. This documentation increment preserves the planning hold.

## 2026-09-17 — Chapter A release/status reconciliation

- Tuna approved v2.2 on 2026-09-17. Chapter A is released now.
- B is approved but gated until A05/evidence/tag. C and the far roadmap remain
  unreleased; do not reinterpret their retained draft bodies as released work.
- Training, ftc-reviewer, and ftc-ball remain forbidden.
- ftc-main already published the protected `protokol.md` amendment `26f915b`, and
  docs reconciled it at `0973e86`; this newer approved gate state is preserved.
- The pre-compaction current handoff is superseded by this release status. Its dated
  planning-hold entries remain historical; no protected document or source file was
  edited by this consistency update.

## 2026-09-17 — A02 protocol amendment consumed

- The protected `protokol.md` amendment `26f915b` is now the binding seam: optional
  `reset.proto` absent means `1`; `ready.proto` advertises the peer version; mismatch
  fails before output; `RobotAction` has exactly two maps (`motors` for DC+CR power,
  `servos` for positional hold); reset clears positional holds and proto1 retains
  full-map/zero-fill behavior.
- A02 is unblocked at `26f915b`. At this dated entry B01 awaited ftc-main's protected
  pin of the exact record signatures now recorded in `adr-device-seam-v2.md`; that
  gate was later satisfied at `7447546` (see the A05 manifest), with fixtures 1–6
  binding and no new test outcome claimed here.
- Release metadata remains: Chapter A released; B approved/gated; C and the far
  roadmap unreleased; training, ftc-reviewer, and ftc-ball forbidden. No code or
  protocol file was edited.

## 2026-09-17 — forward-only A03/A02 ordering

- The forward-only decision records provisional R A03 hashes `c939f16..e80b8c9`.
  R A02 uses base `e80b8c9`, or a coherent separately labeled A03 WIP commit may
  be used; neither is a final A03 evidence pin.
- S must publish only `tests/test_acceptance_scenarios.py` as A03 WIP/not accepted
  on top of `5ba0a96`, then publish A02. No A03 acceptance is valid before a
  post-A02 rerun.
- A05 pins only final post-A02 hashes. A02 documentation propagation continues; this
  dated ordering note predates the `7447546` protocol resolution and the A05
  evidence/tag eligibility check. It records ordering, not test outcomes.

## A05 baseline manifest — p11a-baseline-v1

- This is the sole Chapter A baseline manifest. The annotated D tag identifies the
  docs commit containing this section; compatible source pins are R
  `72d3ac9fa81209f5bf31fd88eb1b99927bfdcaee` and S
  `4cc1201f6ba4861815f37625cc03ea973a84755f`.
- The record-signature protocol gate is satisfied at ftc-main pin `7447546`.
  Chapter B becomes eligible only after this A05 evidence commit and
  `p11a-baseline-v1` tag are verified.
- Accepted slots: A01 at S `5ba0a967` (bounded transport/events); A02 at R
  `97995ca` plus S `5849e58` and final `4cc1201` (mass seam, cancellation and
  deadband); A03 at the final R/S pins after the post-A02 rerun; A04 at OLD
  `d7711d0` (archive-derived preserve/correct/defer handoff); A05 at the final
  R/S pins (stable registry and checkpoint publication).
- A02's escalation found the S PyBullet 12 kg literal at
  `sim/physics/pybullet_backend.py:185-201`. ftc-main authorized the narrow,
  backend-agnostic `ROBOT_MASS_KG` fix; S `4cc1201` and its mass/inertia tests
  are the final accepted result.
- The R runner exited `0` with six 1000-tick A-drive traces and two 101-tick
  A-cancel traces. Schema, status, switch, zero-output, seed-repeat determinism,
  cleanup, and 30 s timeout-bound gates all passed. S acceptance coverage was
  focused `2 passed, 0 skipped` and full `93 passed, 0 skipped`.
- Binding R command `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew
  :core:test :sim:test :sim:installDist` was **BUILD SUCCESSFUL** with 127 core
  and 11 sim tests, zero failures/errors/skips.
- A non-binding `:TeamCode:assembleDebug` attempt hit Java heap exhaustion in
  Android `ApkFlinger`/zipflinger; this is an environment limitation, not a
  product failure, and no source/build configuration change was made. A03 remains
  host-Pymunk evidence only; no physical robot, Control Hub, or mechanism
  validation is claimed. Chapter B becomes eligible only after this A05 evidence
  commit and `p11a-baseline-v1` tag are verified.

## ESCALATION to ftc-main

- The A02 cross-review found `re-cock-nize/sim/physics/pybullet_backend.py:185-201`
  hardcoding a 12 kg mass. ftc-main resolved that `ROBOT_MASS_KG` binding is
  backend-agnostic and authorized the narrow PyBullet fix only.
- Review provenance remains R `97995ca`, S `5849e58`, and provisional A03 WIP
  `635741d`; the forward-only ordering note remains in force.
- Resolution: S `4cc1201` applies the authorized narrow backend-agnostic
  `ROBOT_MASS_KG` fix, with final A02 tests and A03 acceptance recorded in the
  A05 manifest above.

## 2026-09-17 — Chapter B B01 evidence scaffold

- B is eligible after the verified A05 docs commit/tag and protected protocol
  record pin: D `cec382d6380ceb209700fe3abef19684556fb51a`, annotated
  `p11a-baseline-v1` targeting that D commit, and protocol
  `74475463add0f23afd6d84b801245650712bbb62`.
- Created the sole `phases/phase-1.1-a/evidence-B.md` with immutable R/S entry
  pins (`72d3ac9fa81209f5bf31fd88eb1b99927bfdcaee` /
  `4cc1201f6ba4861815f37625cc03ea973a84755f`), B01.0/B01.1/B01.2 task slots,
  fixtures 1–6, required tests/commands, R↔S cross-review slot, and limitations.
- The scaffold records no B01 implementation or test outcome. A05 command and
  runner results are explicitly entry gates only; future entries require
  independent R/S hash, remote, worktree, command and result verification.
- No protocol, specification, source, tag, reviewer, ball, training, or phase
  change was made. Continue monitoring only for proven R/S B01 reports.

## 2026-09-17 — B01 R completion evidence (seam-review pin; S pending)

- R's final seam-review pin is `bffd71b331a7c1dfc67abe30f16df7df92165cc5`, a
  clean pushed descendant of the earlier completion pin `e234a8e5`; increments,
  changed paths, and seam scope are recorded in `evidence-B.md`.
- The final Gradle command (`core:test`, `sim:test`, `sim:installDist`, and
  `TeamCode:assembleDebug`) is green with **137 core + 17 sim tests**, all passed
  with zero skips/failures/errors. InstallDist, Android assembleDebug, and the
  Pymunk replay bit-equality check remain green; the full sim rerun exited 0.
- `bffd71b` adds `HardwareProfileTest.java` (three core tests) after e234's
  reported 134+17 totals. R worktree and local/remote refs are clean and agree at
  bffd71b.
- SDK-module Android `HardwareMap` fake-device write tests remain unavailable;
  production binding compilation and core/sim seam coverage are the limitation.
  B01 is not accepted: await bounded bidirectional R↔S seam cross-review. No
  protocol/spec/source edit or new tag was made.

## 2026-09-17 — B01 S completion evidence (cross-review pending)

- S supplied clean pushed pin `0ca3175b81fa499e8c169bbc005713aa4d63e3b2`;
  origin matches and only the preserved untracked `.claude/` directory remains.
  Changed paths cover the typed mechanism parser, physics/backend forwarding,
  protocol-v1/v2 fixtures, protocol/multi-robot/process tests and fake client; the
  exact grouped list is recorded in `evidence-B.md`.
- Independently rerun with S's repository-local venv: the focused mechanism,
  protocol, multi-robot, process-network and Pymunk command ran **48 tests, OK**;
  `PYTHON=... ./run_tests.sh` ran **106 tests, OK**. No skipped/failure/error cases
  were reported. Coverage includes typed DC/CR/PosServo parsing, identifier and
  literal rejection/hash/encoder roles, proto negotiation/lists, sparse hold/reset,
  zero-fill, backend forwarding, shared shooterLeft input, fixtures and determinism.
- S models declared actuator state/metadata only; no B02+ plant or real-HAL result
  is claimed. R and S evidence are both present, but B01 remains unaccepted until
  bounded bidirectional R↔S seam reviews are completed and recorded.

## 2026-09-17 — B01 S→R seam cross-review (FAIL)

- Bounded read-only review pins: S `0ca3175b81fa499e8c169bbc005713aa4d63e3b2`,
  R `bffd71b331a7c1dfc67abe30f16df7df92165cc5`, protected protocol D
  `74475463add0f23afd6d84b801245650712bbb62`. S/R refs matched; S retained only
  `.claude/` and R was clean.
- All wire/forwarding checks and the four paired protocol-v2 fixture comparisons
  passed byte-for-byte (SHA pairs and source anchors are in `evidence-B.md`). The
  one major failure is R-owned: `RobotConstants.constantsHash()` omits
  `ROBOT_MASS_KG`, so a mass-only change cannot change the Java hash. S includes
  mass; no cross-language hash equality is required because hashes are not on wire.
- Review commands remained green: S focused 48 and full 106 tests; R
  `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew -q :core:test :sim:test`
  exit 0 with 137 core + 17 sim and no skips/failures/errors. Review was
  read-only and made no source/protocol/tag/B02 changes.
- B01 remains unaccepted. Remediation recommendation is to add the Java mass
  contribution and a regression test, then rerun the bounded bidirectional seam
  review; no source fix is dispatched by docs.

## 2026-09-17 — B01 bounded R↔S seam rerun PASS

- The authoritative read-only rerun closes the prior R-owned mass-hash finding.
  Verified pins are R `18b1d629fa21869963b9cd678e285c770f37c9d4`
  (HEAD/origin `dev-phase-1.1-a`, clean; descendant of `b72da4a` and
  `bffd71b`), S `0ca3175b81fa499e8c169bbc005713aa4d63e3b2` (HEAD/origin,
  only preserved untracked `.claude/`), and protected D
  `74475463add0f23afd6d84b801245650712bbb62`.
- R `RobotConstants.constantsHash()` delegates to
  `constantsHashForMass(ROBOT_MASS_KG)` (`RobotConstants.java:113-116`),
  appending mass (`:120-123`), wheel efficiencies (`:124-129`), typed device
  arrays, `ENCODERS`, and `PINPOINT` (`:130-144`).
  `RobotConstantsHashTest.java:10-15` proves 12.0 kg and 18.0 kg produce
  different hashes. The reflection probe returned mass12
  `b189515a90da49e2e98a63de90daf23912f8d17e80bd937800ced3f4fba1555d` and
  mass18 `f5b1af72d2d0cabdf07c3ba5a93f062abde442d52731baeccbde88bfcfb99c51`.
- All four protocol-v2 fixture comparisons passed byte-for-byte. SHA-256 pairs:
  ready `27a14aac3b1c1666998fca315db940c00dd95aa9968394788b2a4f36d11e92e1`,
  state `308850533f16d16fad014ab1e1409167ad26823ec272c0495e68f281090cd009`,
  hold `fcc17e3b10760ab0bc880808bb00ff3fbae704abf434d8d9447d46547e80cdab`,
  explicit-zero `6253f2782c11875d2142adc79c4e2988820258d042bc7f26db8d648ff1ef5fb3`.
- Reset/ready ordering, two-map rejection, proto1 full-map zero-fill, DC/CR
  zero-fill, sparse positional hold/reset, shared `shooterLeft` roles, and
  kinematic/Pymunk/PyBullet plus multi-robot forwarding all passed. Source
  anchors and detailed fixture rows are in `evidence-B.md`.
- R `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew -q :core:test :sim:test`
  exited 0 with 138 core + 17 sim tests and zero failures/errors/skips. S's
  focused mechanism/protocol/multi/process/Pymunk command ran 48 tests OK; the
  full `run_tests.sh` ran 106 tests OK with no skips/failures/errors. The bounded
  Python seam script reported PASS for all listed parser, protocol, backend and
  two-robot checks.
- Review result: **PASS** for the bounded B01 R↔S seam gate. Java and Python
  constants hashes use different canonical encodings and are not on the wire;
  no cross-language digest equality is asserted. Java tests use `FakeSimServer`,
  and no physical Control Hub, real-HAL, or B02+ decay result is claimed. No
  source/protocol edits, tag, reviewer, ball, training, or B02 work was made.

## 2026-09-17 — B01 bounded R→S seam rerun PASS

- Reverse-direction, read-only review pins: R
  `18b1d629fa21869963b9cd678e285c770f37c9d4` (clean HEAD/origin
  `dev-phase-1.1-a`), S `0ca3175b81fa499e8c169bbc005713aa4d63e3b2`
  (HEAD/origin; only preserved untracked `.claude/`), and D
  `74475463add0f23afd6d84b801245650712bbb62`.
- R `RobotConstants.java:18,113-154` includes `ROBOT_MASS_KG` in the canonical
  hash; `RobotConstantsHashTest.java:10-15` proves mass sensitivity. Default R
  hash: `b189515a90da49e2e98a63de90daf23912f8d17e80bd937800ced3f4fba1555d`.
- Paired `ready/state/step-hold/step-explicit-zero` protocol-v2 fixtures again
  compared byte-for-byte; their equal SHA-256 values are recorded in
  `evidence-B.md`.
- D `protokol.md:94-136,150-159`, R `SimHal.java:106-149`, `Mechanism.java:89-131`,
  `RealHal.java:68-105`, `Hardware.java:36-123`, and `ActionValidator.java:19-33,54-90`
  align with S `sim/server.py:130-141,202-211,890-913,976-1029`,
  `sim/physics/motor.py:245-262`, configured-mass backends, and
  `multi.py:64-95`. Negotiation, two maps, proto1 zero-fill, sparse hold/reset,
  paired validation, shared-port isolation, and all-backend/multi forwarding
  were PASS.
- R `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew :core:test :sim:test
  --rerun-tasks` was BUILD SUCCESSFUL with 138 core + 17 sim tests and zero
  failures/errors/skips. S's six-module focused command ran 49 tests OK; parser,
  mass/name, and bounded seam probes passed.
- Reverse-direction B01 seam result: **PASS**. No live Java-to-S socket run was
  required; Java uses `FakeSimServer`. No physical-hardware/B02+ decay result,
  source/protocol edit, tag, reviewer, ball, or training work was made.
