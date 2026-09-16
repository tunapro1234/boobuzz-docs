# sim-cx-08 — PyBullet backend + --gui (Phase 1.1 / S2)

Repo: `re-cock-nize`, branch `dev-phase-1.1` (HEAD d753cd8). Design: `design-spec.md` §8.
Same rules as sim-cx-07: separate commit + push per step, English only, read before edit,
no bloat. The backend does rigid bodies/walls/contacts only; motor model stays shared.

## Steps
**S2.1 — PyBullet backend.** `sim/physics/pybullet_backend.py` implements `PhysicsBackend`
with the same semantics as the pymunk one: `p.connect(p.DIRECT)` by default; planar robot
box (mass 12.0 kg fallback until `ROBOT_MASS_KG` lands in RobotConstants), four static walls,
gravity so the box rests on a ground plane (constrain to plane: lock z/roll/pitch via
`changeDynamics`/constraint, not by resetting pose every step), fixed timestep matched to
`dt_ms` with substeps, deterministic (`setPhysicsEngineParameter(deterministicOverlappingPairs=1)`,
fixed seed, no real-time). Wheel forces applied with the same traction model and constants
as pymunk (share the helper; do not copy the formula). Zero-power decel same numbers.
`pybullet` added to requirements (optional extra is fine if install is heavy; then
`--physics pybullet` prints a clear install hint).

**S2.2 — `--gui`.** `sim.server --physics pybullet --gui` opens PyBullet's native window
(`p.GUI`) and locks to real time; ignored for other backends with a warning. Headless
remains the default.

**S2.3 — Tests.** Parametrize the existing pymunk tests over `["pymunk", "pybullet"]`:
wall-slide (heading delta > 10°, along-wall > 10 in), determinism (500 steps twice,
bit-identical), speed (1000 steps < 2 s for pybullet). Add a cross-backend test: test-line
style full-forward run for 2 s ends within 3 in and 3° between pymunk and pybullet
(document the actual difference). Skip cleanly if pybullet is not installed.

**S2.4 — E2E.** If `robot-code` `dev-phase-1.1` compiles by then (robot-cx-10 in progress),
run the Java test-line e2e against both backends and report both final poses. If it still
does not compile, say so and stop; do not touch robot-code.

## Report
Hashes; the pybullet parameters chosen (timestep, substeps, solver iterations, friction);
cross-backend difference numbers; test output; e2e status.
