# robot-cx-11 — AutoController + fluent AutoBuilder + last season's autos (Phase 1.1 / R2)

Repo: `robot-code`, branch `dev-phase-1.1` (HEAD 9795f38). Design: `design-spec.md` §7
(binding). Same rules as robot-cx-10: separate commit + push per step, English only, read
before edit, no bloat, controllers never import `subsystem` or `hal`.
Reference (read-only, do not copy code blindly, port the API and the data):
`/home/shared/projects/archive/ftc/de-cock/robot-code/TeamCode/src/main/java/org/firstinspires/ftc/teamcode/contingency/lvbelc5/auto/`
(`AutoBuilder.java`, `AutoLocations.java`, the six auto opmodes; `experimental/` is out of scope).

## Steps
**R2.1 — Housekeeping.** Move `GamepadState`/`GamepadSource` to `contract` so the dependency
test allows `controller → contract` only (remove the special-case edge). Add
`RobotConstants.ROBOT_MASS_KG = 12.0` (scalar line format; the Python reader must not break).

**R2.2 — Contract requests.** Extend `Request`/`RequestType` so every AutoBuilder method
can be expressed: `PATH` carrying an ordered list of segments (`line` to a point or `curve`
with control points), a heading mode (`TANGENT`, `TANGENT_REVERSE`, `CONSTANT(h)`,
`LINEAR(h0,h1)`), `holdEnd`, optional velocity constraint and braking (strength, startMultiplier);
`TURN_TO(headingRad)`; `SHOOT(count)`, `SPIN_UP(rpm)`, `INTAKE_ON(power)`, `INTAKE_OFF` already
exist from R1. `WAIT` is controller-local (a timer), remove it from `RequestType` if R1 added it.
Keep records small and immutable; no builder classes in `contract`.

**R2.3 — Engines execute the new requests.** `PedroDrive.follow(PathRequest)` builds the
Pedro path from the segments/heading mode/constraints (this is where last season's
`AutoBuilder` Pedro code goes, translated to Pedro 3.0), `turnTo` via Pedro. Both
`DirectEngine` and `CplxEngine1` route `PATH`/`TURN_TO` to `drive` and report DONE when
`pathDone()`. Parallel modifiers (`withIntake`, `withShooterWarmup`) are separate requests
issued alongside the path by the controller, not engine features.

**R2.4 — `controller/auto/`.** `AutoStep` (sealed: path, turn, wait, shoot, intake, spinUp,
plus "attach" modifiers), `AutoSequence` (list + cursor + progress/name for telemetry),
`AutoBuilder` with the method names from spec §7 verbatim (`start(Pose)` static,
returns builder; modifiers apply to the most recent path step, as last season),
`AutoController implements Controller`: each tick emits at most the Intent needed for the
current step, waits for the step's request status DONE (or its timer), then advances;
on REJECTED it stops the sequence and exposes the failure. Unit tests with a fake
snapshot/status feed: sequencing, modifier attachment, wait timing, rejection stop.

**R2.5 — Data port.** `controller/autos/AutoLocations` (Blue/Red poses verbatim, converted to
our frame if the archive used a different one; state which) and six classes
`BlueDoggy6Piece`, `RedDoggy6Piece`, `BlueMissionary9Piece`, `RedMissionary9Piece`,
`BlueMissionary9PieceLever`, `RedMissionary9PieceLever`, each a static
`AutoSequence build()` using the fluent API exactly like the archive files read. Commented-out
segments in the archive stay commented. `AutoRegistry` maps name → sequence.

**R2.6 — Entry points.** `SimMain --auto <name>` (with `--engine`, `--steps` cap, prints
final pose, exit code 1 if the sequence did not finish). `TeamCode/src` `AutoMain` opmode
(one `@Autonomous` per registry entry via a tiny loop or six trivial subclasses, whichever
is shorter) using `RealHal` + `RobotFactory`.

**R2.7 — E2E.** Python server from `re-cock-nize` `dev-phase-1.1` (`--physics pymunk`,
headless, port 5556). Run all six autos with `cplx_engine_1`; each must finish (all steps
DONE) within the step cap, and the final pose must be within 3 in / 5° of the sequence's
last target pose. Also run one with `--engine direct`. Report a table: auto, steps, ticks,
final pose, target pose, delta. If Pedro cannot reach a pose in the sim (tuning), report it
rather than loosening the tolerance.

## Report
Hashes per step; the RequestType list; which archive semantics could not be ported 1:1 and
what you did instead; the e2e table; anything in the spec that did not fit reality.
