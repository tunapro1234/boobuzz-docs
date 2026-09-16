# sim-cx-11 — S3: multiple robots in one physics world

Repo: `re-cock-nize`, branch `dev-phase-1.1` (HEAD 8af8281). English only. Read before edit.
Commit + push per step, report hashes. Tests: `PYTHON=<abs .venv python> ./run_tests.sh`.
Protocol (`docs/protokol.md`) stays backward compatible: a single client with today's messages
must behave exactly as now (existing tests unchanged).

## S3.1 — Server: N robots, one world
`sim.server --robots N` (default 1). Robot i listens on `port + i` (each Java client connects to
its own port, no message changes). One shared physics world per backend; each robot is its own
rigid body with the same `RobotConstants` mechanism. Lockstep across robots: the world steps
only when every connected robot has sent its `step` for the tick (a robot that disconnects
keeps its body, powers 0). Reset pose per robot from its own `reset` message.

## S3.2 — Robot–robot contact
pymunk and PyBullet: bodies collide with each other with the same friction/elasticity as
wall contact. Test (both backends): robot A at (30,72,0) drives +x at full power, robot B
at (90,72,0) sits still; after 3 s A's x < B's x, B moved by > 5 in, no interpenetration
(distance between centers ≥ robot length − 0.5 in). Determinism test with two robots.

## S3.3 — Viewer
Draws every robot (index label), HUD shows the selected robot's last event; `Tab` cycles.

## S3.4 — Convenience runner
`scripts/two_robots.sh`: starts the server with `--robots 2` and two Java clients from
`robot-code` (`./gradlew :sim:run --args="--port 5556 ..."` and `--port 5557`), one on
`--path test-line`, one on `--auto BlueDoggy6Piece`. Document in README (short).

## Report
Hashes, test names/counts per backend, the two-robot scenario numbers, anything that did not
fit (e.g. lockstep design choices), and the `--robots` semantics you implemented.
