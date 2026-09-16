# docs-cx-04 — Markdown cleanup across the three repos

Rules: English task, but existing Turkish doc content stays Turkish (do not translate).
Read every file before deciding. Do not delete anything. Separate commit + push per repo,
report hashes. Do not touch `docs/protokol.md` (ftc-main owns it), `docs/phases/phase-1.1/*`,
`docs/architecture/architecture.md`, or any source code.

## Goal
Tuna: "throw-away md files and README-like handoff files should not litter the repos; keep
them, but move them into one folder that is gitignored." The living documents stay where
they are: `README.md`, `plan.md`, `mimari.md`, `protokol.md`, `CHANGELOG.md`,
`gunluk/`, `engine-iterasyonlari/`, `architecture/`, `phases/`.

## Steps
**D4.1 — docs repo (`/home/shared/projects/boobuzz/docs`, branch `stable`).**
Classify every tracked `.md` outside the living set above. Candidates for the parking
folder: handoff/devir reports, one-off agent reports, ad-hoc lists (e.g. `phases/phase-1/devir-*.md`,
`*-rapor.md`, `bloat-avi-liste.md`). Task *specs* under `phases/phase-1/` stay (they are
history of what was asked). Move the parked files with `git mv` into `_parked/` preserving
relative paths, commit that move, THEN add `_parked/` to `.gitignore` and `git rm -r --cached _parked`
in a second commit so the files stay on disk but leave the index. In `README.md` add one line
saying `_parked/` holds untracked handoff/report files. Fix any links that pointed at moved files
(point them at `_parked/...` with a note that it is untracked).

**D4.2 — `robot-code` (branch `dev-phase-1.1`).** Only the top-level `README.md`: if it is the
stock FTC SDK readme, replace it with a short README (what this repo is, the `:core`/`:sim`
modules, how to run tests and the sim e2e, link to the docs repo). `docs/miras/` stays as is.
Do not touch `.github/` or `FtcRobotController/`.

**D4.3 — `re-cock-nize` (branch `dev-phase-1.1`).** `TASIMA.md` and `DECODE_RULES.md`: decide
per file. `TASIMA.md` is a carryover/handoff note → `_parked/` with the same gitignore
pattern as D4.1. `DECODE_RULES.md` is last season's game rules → `_parked/` too unless the
sim still reads it (grep first). `README.md` must describe the current sim (physics backends
`pymunk|pybullet|kinematic`, `--physics`, `--gui`, events, how to run tests and the server);
rewrite only the parts that are stale.

**D4.4 — Report** a table: repo, file, action (kept / parked / rewritten), reason. List any
file you were unsure about and left in place.
