# docs-cx-09 — Three variants of the architecture document (layer structure first)

Repo: `docs`, branch `stable`. English only. Read before edit. Commit + push per variant, report
hashes and PDF paths. Tuna's verdict on `architecture/architecture.md` (fed3467): "it never shows
the layer structure". The document must open with, and be organised around, the **layer stack**
and what crosses each seam. Everything else is secondary.

## The layer stack that must be the spine of every variant
```
Controller (teleop gamepad / auto sequence / replay bag / socket agent)
   ↓ RequestBatch (stream + requests + cancels)      ↑ Feedback (WorldSnapshot + statuses)
Logic engine (direct | cplx1: ShooterLogic, TurretLogic, MotionLogic)
   ↓ subsystem calls (drive.manual/follow, shooter.spinUp/feed, intake, turret)   ↑ ready/done/events
Subsystem (PedroDrive, stub shooter/intake/turret; Subsystems record)
   ↓ RobotAction (motors, servos, events)             ↑ RobotState (enc, vel, yaw, pinpoint, voltage)
HAL (IHal: SimHal over TCP JSON | RealHal over FTC SDK)
   ↓ step JSON / hardware writes                       ↑ state JSON / sensor reads
World (re-cock-nize Python sim: pymunk|pybullet|kinematic | real robot)
```
Side rails: RobotLoop drives the tick (sense → controller → engine → subsystems → hal); DebugTap
publishes one line per seam (hal/subsystem/logic) per tick; bag = same lines to .jsonl; Replay and
Socket controllers sit at the top of the stack. Every seam has a Java record type — name it.

## Common rules
- Diagram-first (prose ≤ 1/3 of the page count), every diagram rendered (mermaid via the existing
  `build.sh` pipeline, or TikZ), real pdfTeX PDF, `pdfinfo` Producer check.
- Page 1 = the layer stack diagram, full page, nothing else. Page 2 = the same stack with the
  tick-time data flow drawn as arrows with the record names on them.
- Each layer then gets its own section in stack order: what it owns, its interface (signatures),
  who calls it, what it must never import (from the `:core` dependency test), 1–3 diagrams.
- Sim and docs of tools (tap/bag/demo) come last, short.
- Each variant is a separate folder: `architecture/variant-A/`, `variant-B/`, `variant-C/`, each
  with `architecture.md`, `build.sh` (may reuse `../build.sh`), `architecture.pdf`, `diagrams/`.
  Leave the current `architecture/architecture.md` untouched.

## Variant A — "Poster"
Max 8 pages. Big diagrams, almost no prose (captions only, ≤ 2 sentences each). Layer stack, seam
records, tick sequence, engine internals, controllers, sim. Landscape pages allowed.

## Variant B — "Layer handbook"
12–20 pages. One chapter per layer in stack order, each chapter opening with a diagram of that
layer highlighted inside the full stack (the rest greyed), then interface table (method, args,
returns, who calls), then one sequence diagram for the layer's typical tick, then bullets (≤ 10).

## Variant C — "Follow one request"
10–16 pages. Narrative by example: a SHOOT(3) request from the gamepad press to the servo pulse
and back to DONE, drawn as one long swimlane per layer across pages; then the same for GOTO(path)
and for an engine switch. Each step shows the exact record/JSON that crosses the seam. Layer
stack page first as in all variants.

## Report
Three hashes, three PDF paths, page counts, diagram counts, anything that did not fit.
