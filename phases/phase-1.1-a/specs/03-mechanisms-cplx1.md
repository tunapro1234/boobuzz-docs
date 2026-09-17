# B05–B09 — complete mechanisms and the first useful cplx1

Status: DRAFT, not dispatched. B01 is required for B05–B07; B02–B04 and all
mechanisms are required for B08/B09. Apply [common gates](00-common.md).

## B05 — dual flywheel feedback and readiness

R ports the active archive power-domain PID + feedforward into a deterministic
SDK-free subsystem. Preserve kS/kV conventions, low-target handling, integral zone
and clamp, derivative/dt guards, optional output slew, motor polarity and follower
scale. Do not replace power control with FTC `setVelocity` while claiming parity.
Archive example kS=0.18766200 and kV=0.00013514 are provenance fixtures, not newly
tuned pollen constants. Confirm active source/config before using them.

Each tick: validate speed measurement; calculate target error; update bounded
controller state; calculate/clamp power; publish actual measurement and readiness.
Readiness requires error within tolerance continuously for dwell, no invalid speed,
and no fault. Archive starting values are 100 RPM and 150 ms, subject to A04.
Target change, speed dip, stale sensor, STOP and reset clear readiness immediately.
Disabled target zeros power and resets integral. Avoid integral accumulation while
saturated unless the update moves output back toward its valid range.

Resolve encoder ownership before closed-loop use: the turret's `shooterLeft` encoder
name may mean that port does NOT measure flywheel speed. If no independent flywheel
feedback is established, expose open-loop/unverified mode, never false RPM-ready.
The production profile remains gated until this is resolved; provisional simulated
devices must be labeled rather than silently treated as real wiring.

S models each flywheel's inertia, bounded motor torque/damping, voltage dependence
and a shot-induced speed loss. A first-order approximation is acceptable initially
with named fitted/unmeasured parameters. No Python readiness/PID controller.

Tests: golden archive power calculations; both motor directions; step up/down,
below-FF threshold, saturation/recovery, missing ticks, negative/large dt, speed
dip after a feed and restart. Nominal simulated target reaches readiness within a
declared fixture timeout (initial target 3 s) and cannot feed while not ready.
Use independently derived plant cases; a controller and plant sharing one fitted
inverse formula is not validation. Exit: measured-speed traces, source provenance,
fault tests and Android device binding proof.

## B06 — mirrored hood with honest feedback

R implements angle-to-two-servo mapping from the active archive, including trim,
inversion, range and mechanical clamp. Specify whether startup holds or commands
a named safe angle; the old default variable without a servo write is not proof
the mechanism moved. Unit: mechanism degrees at API, normalized positions at HAL.

Without a physical position sensor, status is commanded angle + estimated settling,
not measured angle. Estimate based on configured maximum speed, travel and margin;
changing target restarts settling. No generic PID is needed for a positional servo.
S models bounded travel and mirrored linkage without adding nonexistent real feedback.

Tests: endpoint/midpoint conversions, mirror relation, trim, clamping, invalid angle,
startup command policy, interrupted move, STOP hold/stow, jam/fault approximation
and settling deadline. Golden mapping must match archive except documented fixes.
Exit: visible hood travel and trace, no feed until estimated settling condition,
hardware uncertainty clearly shown. Do not assert an undetectable jam is detectable.

## B07 — bounded turret and startup angle

R replaces stub with dual-CR-servo angular controller, independent incremental
encoder input and analog startup estimate. Preserve useful archive polarity/PID/kS
behavior. Start with a documented bounded startup calibration/filter, not wholesale
copy of every archived filter. Historical ±90° and 8192 tick/rev with gear factor
1/0.715 are inputs to verify, not assumed final geometry.

States: UNINITIALIZED, HOLD, AIM, MANUAL, FAULT. Commands outside mechanical limits
are rejected/clamped with explicit status according to API; choose nearest feasible
angle within limits, never use angle wrapping to cross a hard stop. Sensor invalid
at startup prevents automatic motion. Incremental reset/reconnect cannot cause a
full-speed jump. Apply deceleration/soft-limit margin before the physical hard limit.

Field aim uses robot heading + turret relative heading and a calibrated camera/barrel
offset, not robot heading alone. Hold captures a valid current/commanded angle by
documented semantics; it cancels any pending aim/scan ownership. Manual release
returns to hold when feedback is valid. STOP immediately zeros both CR outputs.

S models angle, rate, inertia/friction approximation, two servo contributions, hard
stops, encoder ticks and analog voltage/noise. Hard-stop collision must not wrap.
Tests: source mapping/sign, startup analog ambiguity/out-of-range, CW/CCW targets,
both boundaries, encoder reset/loss, hold after aim, hold after pending scan, manual
override and STOP. Initial fixture acceptance: settled error <=2°, rate <=5°/s for
100 ms; no hard-stop penetration; tune/revise only with a documented reason.
Exit: driver controls/holds turret and autonomous aim remains bounded under faults.

## B08 — minimal shot coordinator and safe ownership

R composes completed subsystems. Suggested states: IDLE, PREPARE, READY, FEED,
RECOVER, COMPLETE, FAULT. Use the existing request/status mechanism; no new scheduler.

Fixed preset supplies flywheel RPM, hood angle and turret target (or manual-hold
aim). PREPARE starts them together. Feed permission is the conjunction of valid
shooter-ready dwell, hood settled estimate, turret settled/valid, no fault and a
stationary chassis condition for automatic shots. Default stationary gate proposed:
<=2 in/s and <=5°/s for 150 ms; missing speed invalidates auto readiness.
Direct/manual diagnostics remain separate from automatic shot permission.

Snapshot the shot solution for each pulse. If aim/speed readiness is lost before
feed starts, wait/reject by deadline; during a started pulse use the explicit
physical-safe interrupt policy, never pretend the already-released ball can be
cancelled. Release stops requesting new pulses; explicit abort stops feeder now.
After each pulse require measured flywheel recovery and all gates again. Maximum
shot count and prepare timeout are finite/configured. Provide operator reason codes.

A single resource table suffices: shot owns flywheel/hood/turret/feeder; intake
compatibility is explicit; manual turret/engine switch cancels incompatible shot
ownership before the next actuator frame. Drivetrain remains driver-controllable;
movement prevents starting the next automatic pulse rather than silently steering.

Tests: every readiness false alone, simultaneous requests, release vs abort,
partial multi-shot, voltage dip, jam, readiness flicker, moving chassis, lost pose,
STOP, engine switch and timeout. One terminal result/request; no feed on stale READY.
Exit: a full mechanism cycle on Pymunk with actuator-causal pollen release. At this
stage a simple safe target fixture is sufficient; no claim of calibrated range.

## B09 — cplx1 release and competition-oriented profile

Entry: B01–B08 plus A baseline all accepted. R selects real mechanisms in factory
for the provisional match profile. Keep stubs only in explicit test profiles;
production profile validation fails if a required mechanism is still a stub.
Direct diagnostic mode uses the same mechanisms with guardrails. Do not delete
previous tagged working software or rename layers.

Acceptance run: drive/turn; pollen pickup among nectar; intake reverse/jam recovery;
manual aim; fixed preset single and multi-shot; drive while preparing then stop to
shoot; release mid-sequence; voltage/sensor fault; hard abort; fallback/engine
switch; neutral recovery; full reset. Run 10 fixed scenario seeds and repeated
deterministic reference seed. Publish durations, readiness/abort reasons, object
conservation, actuator limits and baseline drive regression. All faults must be
recoverable or explicitly latched; no silent automatic restart after STOP.

Deliver operator control sheet, device/provenance table, startup/calibration checklist,
short demo, compatible commits and physical-validation TODOs. User can choose cplx1
without camera, range, world model or RL dependencies. Tag `p11a-engine-cplx1-v1`
after review, labeled software candidate until physical acceptance. If unknown wiring
prevents a truthful closed-loop profile, report that blocker rather than fake it.
