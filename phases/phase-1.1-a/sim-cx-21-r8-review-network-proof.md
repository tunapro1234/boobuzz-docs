# sim-cx-21 — R8 review and process-boundary determinism

Owner: ftc-sim-cx. Branch: dev-phase-1.1-a, simulator baseline 518bf9c.
English only; continued Phase 1.1. Read the existing design, protocol and reviews.

1. Independently review robot R8, 05d79ff..4b8ba23, especially R7 M2/M3
   writer shutdown and terminal bag errors. Pin 4b8ba23 in an isolated checkout
   when executing Java checks so robot-cx can work concurrently. Report findings
   with severity, source lines and reproducer in review-robot-r8-sim.md here.
   No arbitrary ten-minute inactivity gate: a published immutable hash is the gate.
2. Close the already-recorded simulator test gap: fresh-process/network seeded
   determinism for pymunk, including ready/reset/state payloads and two-robot
   lockstep. Reuse existing harnesses; test a deliberately staggered reset/start
   to characterize the previously reported barrier race. Preserve the protocol;
   isolate nondeterministic transport timing from the deterministic physics claim.
   Implement only a reproduced in-scope server defect if needed, in its own
   tested/pushed commit. No changes to robot-code, game physics or protected docs.
3. Each working step gets targeted tests plus a pymunk Java smoke, separate
   commit and immediate push. Run the Python suite at round end and record exact
   pass/skip counts, commands and artifact locations in sim-cx-21-report.md.
4. Pre-chained next: independently cross-review robot-cx-22 at its published
   completed hash, run its pymunk acceptance against a pinned build, and write
   review-robot-cx-22-sim.md. While awaiting that hash, finish process/reconnect
   coverage and analyze any remaining Phase 1.1 acceptance gaps.

Use ports 5830–5849, tap port 0 except explicit tap tests. Reports live here;
ftc-docs-cx alone commits shared docs. Send pinned review-ready hashes promptly to
ftc-main-cx. Every worker message begins "Always write in English".
