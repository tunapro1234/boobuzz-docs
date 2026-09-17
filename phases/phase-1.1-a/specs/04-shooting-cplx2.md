# C — practical pollen shooting and cplx2

Status: DRAFT, not dispatched. Entry: B09 software candidate. Apply [common gates](00-common.md).
Stationary shots first; no RK4, aerodynamic research program or shoot-on-the-move.

## C01 — evidence audit and minimum real target geometry

R audits active archived `RonaldoShEngine` and calibration coefficients; S supplies
the minimum authoritative target opening/rim/height geometry. D pins source hashes.
Inspect existing `ball-auto-istic/calibration/step3_analysis/fits.json` read-only;
do not activate that agent. Separate real video-derived fits from `synthetic_fits`
and establish units, ball type, camera calibration, RPM definition and hood mapping.
Do not infer projectile launch angle directly from the hood servo angle.

Publish one row per usable sample: RPM, hood command, launch speed/elevation if
measured, horizontal range, target height, ball type, voltage, method, uncertainty,
source path/hash. Reject or quarantine ambiguous units and synthetic observations.
Last year's different ball data informs methods, not a claim of pollen calibration.

S sources target dimensions from season field drawings/manual, not viewer pixels.
Build one static target fixture with opening, rim and exit/retention geometry. Full
scoring, tipping and match phases remain F. Unknown dimensions are explicit named
parameters with a sensitivity bracket; no invented exact acceptance geometry.
Exit: evidence table, provenance/confidence, trusted unit conversions and a static
shot fixture. If no usable pollen data exists, proceed with a labeled synthetic
software-test profile and leave physical calibration pending, not silently "done."

## C02 — bounded empirical shot solution

R introduces a small pure `ShotSolver` in logic, returning either a complete solution
or a reasoned invalid result. Input: horizontal barrel-to-target range, target height,
robot/turret geometry, selected target/profile and valid calibration metadata.
Output: RPM, hood angle, turret aim, predicted flight time if supported, valid range,
confidence/provenance and failure reason. No actuator writes or global state.

Primary method: vetted distance-to-RPM/hood lookup with piecewise-linear interpolation
inside the measured domain. Preserve an archived polynomial only if held-out data
shows it behaves better within the same domain. Avoid high-order fitting and
extrapolation. Clamp actuator limits only after checking reachability; clamping an
unreachable solution must not turn it into a valid shot. Changes in target height
outside the table's calibration domain are invalid or require a separately vetted
table, not an invented correction.

Use constant-gravity equations as independent plausibility checks/initial synthetic
fixtures: `z = z0 + v*sin(theta)*t - g*t*t/2`, `r = v*cos(theta)*t`. For a fixed
elevation, require positive denominator in `v² = g*r²/[2*cos²(theta)*(r*tan(theta)-dz)]`.
Apply these in SI with tested conversions; handle r≈0, nonfinite inputs and near-
vertical angles explicitly. Empirical wheel-speed-to-launch-speed mapping is not
unity, and g is not tuned to make the controller look accurate.

Tests: table endpoints/interior, continuity, gaps, invalid height/range, zero/negative
distance, NaN, mechanical limits, both alliances and barrel offset. Golden archive
comparison documents intentional corrections (especially old always-valid results).
Hold out samples by source recording/session, not adjacent frames. Report residuals
and intervals; no numerical physical accuracy claim without data. Exit: predictable
solver, explicit unsupported domain and fixed-preset fallback.

## C03 — pollen launch and height-aware physical motion

S adds compact flight state `(x,y,z,vx,vy,vz,spin optional)` alongside Pymunk planar
bodies. Start with exact constant-gravity propagation between collisions; no spin
or drag term until evidence warrants it. Launch consumes an existing fed pollen;
derive velocity from actual flywheel state, hood/linkage, barrel pose and profile.
Motor command/request count cannot directly create a successful hit.

Use swept segment/contact tests against floor, walls and target boundaries so a
fast ball cannot tunnel between 20 ms samples. At impact use declared restitution,
friction and bounded energy loss; move to Pymunk rolling when height/vertical motion
is sufficiently small. Match radius/mass by object class; nectar can collide as an
external object but is never launched by our mechanism. Preserve identity privately
across stored, feeding, airborne, rolling and contained states.

One small collision/flight API, not a general 3D engine. Test analytic no-contact
range/flight time (relative error <=0.5% fixture target), apex, floor bounce, rim hit,
wall hit, target miss, out-of-bounds, empty feed and repeated shot. Halve dt and
require <=1% change in no-edge-case landing range; explain contact discontinuities
with contact-time tests instead of masking them with broad tolerances. No energy
gain without actuator work. Run 1,000 spawned fixture trajectories for conservation
and finiteness; fixture spawning is test setup, never production shot behavior.
Exit: independent projectile oracle passes and actuator-to-flight trace is causal.

## C04 — integrated aiming, readiness and uncertainty

R computes barrel origin from estimated robot pose and turret geometry. Solve field
azimuth and feasible turret angle; reject unreachable turret headings, suggesting
manual chassis repositioning rather than silently rotating the robot. Use consistent
target height/range with C02. Keep chassis stationary gate from B08.

Latch a solution per pulse; recompute before the next pulse if pose/target changes.
Stale/uncertain pose, target change or excessive range residual invalidates automatic
feed. Show RPM/hood/aim/validity to operator. Manual fixed-preset fallback remains
available without accepting an invalid automatic result.

S parameter sweeps vary voltage, launch conversion, hood offset and sensor/pose error
independently of solver fitting data. Test nominal distance grid and near validity
boundaries; report hit/miss distribution and failure reasons rather than only means.
Acceptance: zero feeds for every invalid/stale/unreachable case; all accepted nominal
synthetic cases hit the fixture opening in zero-noise conditions; at least 90/100
hits in each explicitly declared mild-noise test profile, otherwise narrow the
advertised domain or correct the model. This is a software robustness target, not
a claim of 90% physical accuracy. Never tune against held-out evidence secretly.

## C05 — cplx2 release

Compose cplx1 mechanism coordinator with selectable shot-solution provider, not a
copied engine. Keep legacy fixed presets and cplx1 selection. Test complete pollen
pickup-drive-stop-aim-shoot cycles, empty/jammed feed, multiple distances, invalid
solution recovery, sensor loss and engine switch during prepare/feed/recover.

Deliver table/profile provenance, solver residual report, ball-flight validation,
distance/noise matrix, operator fallback instructions and calibration procedure for
the future physical robot. Physical calibration procedure records many independent
shots per range/voltage, reserves hold-out sessions, and refuses extrapolation.
Tag `p11a-engine-cplx2-v1` only after cross-review and all B09 regressions.
No Limelight/world-model dependency; no physical-success claim from synthetic data.
