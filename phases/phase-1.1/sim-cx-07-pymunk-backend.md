# sim-cx-07 — Physics backend interface + pymunk backend + events (Phase 1.1 / S1)

Repo: `re-cock-nize`. Create branch `dev-phase-1.1` from `dev-phase-1` (HEAD 5cc95cf), push it.
Design source: `docs/phases/phase-1.1/design-spec.md` §5, §8 (binding). Protocol:
`docs/protokol.md` (`step.events`, `--physics`). Each step = separate commit + push; report
hashes. English only. Tests via `PYTHON=<abs .venv python> ./run_tests.sh`. Read before edit.
No bloat: the backend does rigid bodies, walls, friction, contacts; nothing else moves there.

## Steps

**S1.1 — Backend interface.** `sim/physics/` package: `backend.py` with
`class PhysicsBackend: reset(seed, pose) / step(dt_ms, powers, events) / state(dt)` and the
shared motor model extracted from today's `physics.py` (`MotorSim`, battery, tau, efficiency,
mecanum roller geometry, encoder/Pinpoint noise) into `sim/physics/motor.py` so every backend
uses the same motor → wheel force/velocity code. Today's hand-written integrator becomes
`sim/physics/kinematic_backend.py` (kept, selectable as `--physics kinematic`, so we can
compare against it). Server: `--physics pymunk|pybullet|kinematic`, default `pymunk`;
`pybullet` may raise "not implemented yet" until sim-cx-08.

**S1.2 — pymunk backend.** Add `pymunk` to requirements. Field: four static wall segments
at 0/144 in; robot: one box body `ROBOT_LENGTH × ROBOT_WIDTH` from `RobotConstants`, mass
from a new constant `ROBOT_MASS_KG` (add it to `RobotConstants.java`? NO — do not edit
robot-code; use a Python default 12.0 and report that the constant is missing so robot-cx
adds it). Wheel forces: for each motor, the motor model gives wheel rim speed; convert to a
force at the wheel position along the roller direction using a simple traction model
(force = k·(target_rim_velocity − actual_velocity_along_roller), clamp to a max traction
per wheel) so the body accelerates, decelerates and drifts like a mecanum. Friction and
damping so that zero power stops the robot within the existing zero-power decel constants
(tune once, document the numbers). Pinpoint/encoders/IMU computed from the body pose and
velocity exactly as before. Units stay inches/radians at the protocol boundary.

**S1.3 — Events.** Server accepts `step.events` (missing = empty). Store them in the state
log with `t_ms`; viewer prints the last event name in its HUD. Physics ignores them.

**S1.4 — Tests (pymunk).**
- e2e test-line still ends at (120,72) within the existing tolerance (Java client from
  `robot-code` `dev-phase-1`, `./gradlew :sim:run --args="--port 5556 --path test-line --steps 1000"`).
- **Wall slide:** reset at (20, 72, 30°), drive full forward for 3 s. Assert the robot ends
  touching the x=0..? no — pick the wall it hits, heading changed by more than 10°, and its
  position moved along the wall by more than 10 in after first contact. Same scenario under
  `kinematic` must NOT show this (documents the improvement).
- Determinism: 500 steps twice, identical `truth` sequence.
- Speed: 1000 headless steps at dt 20 ms in under 1 s wall time on this machine.

**S1.5 — Viewer** works with the new backend (draw body from backend pose).

## Report
Hashes; backend file list; the traction/friction numbers chosen and why; wall-slide test
output for pymunk vs kinematic; e2e pose; missing constants you need from robot-code;
anything in the spec that did not fit reality.
