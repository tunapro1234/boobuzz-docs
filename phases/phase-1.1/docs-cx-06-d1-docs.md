# docs-cx-06 — D1 part A: CHANGELOG + journal for 2026-09-16, LaTeX pipeline, architecture draft

Repo: `docs` (branch `stable`). Read before writing: `README.md`, `CHANGELOG.md` (format and
agent abbreviations), `gunluk/SABLON.md`, `gunluk/2026-09-15.md`, `architecture/architecture.md`,
`mimari.md`, `phases/phase-1.1/design-spec.md` (incl. Revisions), `request-flow.md`,
`gamepad-map-analysis.md`. Documents stay in the language they are in (Turkish narrative,
English code identifiers). Commit + push per step, report hashes. Do not edit `protokol.md`
or `design-spec.md` (ftc-main only).

## A1 — CHANGELOG 2026-09-16 + `gunluk/2026-09-16.md`
Sources: `git log --since=2026-09-16 --format='%h %ad %s' --date=short` in
`/home/shared/projects/boobuzz/robot-code` (branches `dev-phase-1` and `dev-phase-1.1`),
`/home/shared/projects/boobuzz/re-cock-nize` (same branches) and this repo. Events of the day
to narrate (verify against commits, do not invent): GitHub repos renamed to
`boobuzz-robocode`, `boobuzz-ballautoistic`, `boobuzz-recocknize` (local folder names unchanged);
Codex agents moved to gpt-5.6-luna max; Claude Opus reviews stopped (usage limits) → cross review
by Codex agents; all code/comments/task files switched to English; `mechanism.yaml` →
`RobotConstants.java`; Phase 1.1 opened with a pre-written design spec (subsystem layer,
passthrough DirectEngine, AutoBuilder port with six autos proven in sim, pymunk + PyBullet
backends with wall slide); pymunk encoder bug (NaN at tick 147) found by ftc-main from a 10×
encoder mismatch and fixed (8af8281) + finite-power guard on robot side (9e4b776); md cleanup
into `_parked/`; R3 design (naming, Request/RequestStream, logic modules) agreed and dispatched
(robot-cx-13, still running — mark as "in progress"). Journal: follow SABLON; "Yarına kalan"
lists R3 completion, cross review, tag.

## A2 — LaTeX pipeline
`architecture/build.sh` that turns `architecture/architecture.md` into
`architecture/architecture.pdf` with whatever is installed (check `pandoc`, `pdflatex`,
`xelatex`, `tectonic`; report if none works — do not install system packages). Mermaid blocks:
if no renderer is available, include them as verbatim code with a caption "diagram source";
do not add npm tooling. Commit the script and the generated PDF (small).

## A3 — architecture.md refresh, DRAFT
Rewrite `architecture/architecture.md` to Phase 1.1 state: five packages with the R3 tree
(from robot-cx-13 task file), tick order, Request vs RequestStream, DirectEngine/DirectMap,
cplx1 logic modules, controller helpers, sim backends, events. Embed the six Mermaid diagrams
from `request-flow.md`. Mark the header "DRAFT — R3 in progress, final pass after robot-cx-13".
Keep `mimari.md` untouched (historical), add a one-line pointer at its top if it lacks one.

## Report
Hashes; which LaTeX path worked; PDF page count; anything in the sources that contradicted
each other (list, do not resolve).
