# E — chassis distance sensors and conservative fusion

Status: DRAFT, not dispatched. Entry: D05; [common gates](00-common.md) apply.
Do not decide unknown sensor count/model/placement by inventing final robot hardware.

## E01 — configurable range observation and physical sensor model

R defines a minimal `RangeObservation`: sensor ID, capture/receive time, range or
invalid reason, declared accuracy/uncertainty and mount calibration version. Profile
defines translation/yaw, min/max distance, field of view and update period. Hardware
driver stays inside RealHal; no SDK type leaks into core. An absent optional sensor
does not generate a zero-distance obstacle. Required missing sensor degrades the
selected range-assisted mode explicitly.

S uses ray/cone intersections against visible physical surfaces, finite range,
occlusion, seeded noise, dropout and latency. A wide beam must not always return
the center ray; document the approximation to nearest/weighted return. Test fixture
may use four chassis-side sensors without claiming this is the final layout.
Nectar, robots and field geometry are obstacles; a range does not identify a class.

Tests: walls at known poses, angled wall, two objects in cone, blind zone, max-range,
no return, missing device, stale sample, timestamp reset and mount sign/units.
Exit: shared Java/Python fixtures, actual hardware model TBD if unknown, no truth ID.

## E02 — conservative braking independent of object tracking

R adds an optional directional limiter after controller intent but before drive
output. It can reduce motion toward a measured hazard; it cannot autonomously steer
toward a guessed safe direction or accelerate. Use physical closing-speed estimate
and conservative stopping distance `v*latency + v²/(2*a_brake) + geometry_margin`.
Calibrate `a_brake` from chassis stop fixtures and later hardware, not motor free RPM.
Existing normalized drive demand stays unchanged; limiter converts to conservative
speed limits using the existing characterization and reports applied scaling.

Test front/rear/side/diagonal and rotational corner sweep. If the simple model cannot
certify corner clearance during rotation, limit rotation conservatively rather than
claiming a guarantee from one forward range. Opponent closing speed adds uncertainty;
this is a local assist, not collision-proof planning. Invalid/stale range does not
mean clear space: automatic mode stops or applies a declared crawl policy; driver
can explicitly select non-assisted manual recovery, with hard safety limits intact.

No generic "all contact is illegal" behavior. Avoid soft pollen detections causing
unintended blocking of the approved collection maneuver: configure known intake
zone handling only when geometry and fresh vision justify it, otherwise retain an
anonymous obstacle. Never ignore unknown low obstacles solely to improve throughput.

Tests: speed/braking-distance grid, latency/noise brackets, diagonal approach,
reverse-away escape, stale transition, unexpected obstacle, moving robot and rotated
chassis. Assert no commanded increase toward hazard; no penetration in static
in-envelope fixtures; disclose failures beyond braking/coverage envelope. Exit:
range-only safe behavior demonstrated before any vision fusion work.

## E03 — association and fusion only when justified

R transforms observations at capture time. Compare return interval/cone against
predicted visible track surfaces and known field geometry. Association requires
compatible capture time, geometry, uncertainty and absence of a nearer occluder.
Reject ambiguous multiple candidates. Unassociated return remains an anonymous
short-lived obstacle; do not assign it to the nearest pollen merely because one exists.

Initial fusion updates the associated object's radial distance conservatively,
retaining visual bearing. Do not assume camera and range world positions have
independent pose errors; both share odometry. Use a conservative bounded update or
covariance intersection if covariance is genuinely maintained, not naive repeated
Kalman updates with fabricated independent variances. Record contributing sources.
No range-based robot-pose correction in this task; that would need a separate ADR
and localization tests, not an incidental Pedro pose overwrite.

Tests: agreement, biased camera, biased range, same timestamp repeated, time skew,
two candidates, wall behind ball, ball below beam, occluding robot and no vision.
Compare vision-only, range-only and fused results on the same private-truth evaluator.
Gate: zero wrong updates in explicit ambiguous/occluded fixtures; fused median radial
error improves >=20% in a declared range-informative scenario without inflating
confidence on disagreement. If benefit is not demonstrated, keep anonymous range
obstacles and document deferral; do not add complexity for an engine label.

## E04 — cplx4 release

Compose cplx3 with E02 assist and accepted E03 updates. Operator sees range freshness,
limiter reason, fused/visual/anonymous track provenance and degraded mode. cplx3
remains selectable; switching clears obsolete assist state/ownership safely.

Run pollen pickup and shooting loops through clutter, opponent crossing, camera
loss, range loss and both lost. Test immediate takeover and all cplx1–3 regressions.
Bound CPU/memory, publish stopping-envelope plots and fusion ablation evidence.
Tag `p11a-engine-cplx4-v1` only with accepted complete workflow. Explicitly describe
whether fusion was accepted or deferred; do not advertise absent capabilities.
