# robot-cx-22 — R9 existing subsystem contracts

Owner: ftc-robot-cx. Branch: dev-phase-1.1-a, baseline 4b8ba23.
This is continued Phase 1.1 work, not a new phase. Read the binding Phase 1.1
design/revisions and previous reviews before editing. English only.

1. Audit the existing drive/shooter/intake/turret interfaces, stubs, engine
   ownership and tests against the approved design. Write a concise, source-cited
   gap inventory to this folder as robot-cx-22-report.md. Distinguish approved
   missing behavior, actual defects, and mechanisms intentionally deferred to Phase 2.
2. Implement the first concrete existing-subsystem defect or missing approved
   behavior, with a focused regression test. Prioritize deterministic HAL-clock
   timing, spin/feed/stop/restart, turret hold/settle and cancel ownership. Do not
   invent hardware names, add game mechanisms or broaden the request/wire schema.
   If all such behavior is present, strengthen one genuinely missing contract test.
3. Each independently working change: targeted tests, pymunk test-line on both
   engines, then separate commit and immediate push; report the hash and evidence.
   At round end run core/sim tests, dependency guard and six autos on both engines;
   retain existing tolerances, report target error separately from sensor error.
4. Pin the completed round hash for ftc-sim-cx cross-review. Do not wait idle:
   next review sim-cx-21's pinned simulator changes read-only and write
   review-sim-cx-21-robot.md here; meanwhile prepare the RealHal/OpMode gap inventory
   for the next small hardware-facing round. Source analysis needs no review wait.

Only edit robot-code source. Reviews/reports may be written here; ftc-docs-cx
alone commits shared docs. Preserve protokol.md and design-spec.md. Use isolated
ports 5810–5819 and tap port 0 except explicit tap tests. Avoid concurrent Gradle
builds in another worker's checkout. Return short progress and commit hashes to
ftc-main-cx. Coordination content remains in English; no fixed message prefix is
required.
