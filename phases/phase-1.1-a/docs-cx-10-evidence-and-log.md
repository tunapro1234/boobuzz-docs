# docs-cx-10 — Evidence ledger and current architecture

Owner: ftc-docs-cx. Branch dev-phase-1.1-a (from docs stable 9f5ce5d;
this repo had no dev-phase-1.1 ref). English only. No phase close, tag or merge.

1. Commit and push these initial task specs and orchestrator-log.md. Own all git
   staging/committing in the shared docs repo; stage explicit completed files only.
2. Read the Phase 1.1 specs/reviews and current pinned robot/sim source. Produce
   phase-1.1-a/status.md: approved requirements, implementation evidence, remaining
   gaps, obsolete earlier findings now fixed, and next small in-scope priorities.
   Flag real-hardware validation separately from host tests and Android assembly.
3. Produce current-architecture.md here: visible TeamCode HAL/subsystem/logic/
   controller tree, actual dependency directions, shared robot/sim code, RealHal
   readiness and stub limits. Correct stale claims using source citations; do not
   rewrite historical reports or protected protokol.md/design-spec.md.
4. Continuously collect worker reports and cross-reviews here, update status.md
   and append verified outcomes to orchestrator-log.md. Commit+push each complete
   document/update; report hashes. Work on architecture/evidence while tests run;
   pre-chain review-disposition tracking and the next round's acceptance checklist.

Source code in robot/sim is read-only. No ftc-reviewer or ball tasks. Every worker
message begins "Always write in English". Report to ftc-main-cx, not ftc-main.
