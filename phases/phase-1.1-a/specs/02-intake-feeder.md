# B01–B04 — device seam, pollen intake and feeder

Status: DRAFT, not dispatched. Requires A gate and [common gates](00-common.md).
These are incremental mechanism steps, not new public engines.

## B01 — typed actuator/sensor seam, minimum necessary extension

Owners: R contract/RealHal/SimHal; S decoder/plant registration. Start with a shared
golden wire fixture and capability table before parallel implementation.

Current `RobotAction` distinguishes motor/position-servo maps, but archived turret
requires CR servos and independent encoder/analog channels. Extend records without
collapsing these devices into indistinguishable floats. Proposed channel semantics:

| Channel | Command/readout | Validity and safe behavior |
|---|---|---|
| DC output | finite normalized power [-1,1] | zero power on STOP; configured brake/coast |
| CR servo output | finite normalized power [-1,1] | zero power on STOP; separate from angle |
| Position servo | finite normalized position [0,1] | configured hold/stow; no implicit zero |
| Incremental encoder | ticks + ticks/sec + sample time | separately named input; no assumed motor owner |
| Analog | volts + sample time | configured valid range, invalid/stale flag |
| Digital | boolean + sample time | optional; missing is not false |

Preserve existing device-name maps where sufficient; introduce small typed additions,
not a generic device graph. Configuration stores role, polarity, ratio, ticks/rev,
safe state and provenance. Only `wheel` devices participate in chassis forces.
Motor hardware direction and encoder software sign are separate transformations,
each applied once. Servo mechanical angle conversion stays in its subsystem.

R extends `Hardware`/`RealHal`, immutable input/output records and serialization.
S parses exactly the same capability/version and units. Named profile validation
rejects duplicate output ownership, unknown required devices and missing feedback.
No fake healthy encoder for absent devices. Old chassis profile still runs.

Tests: each valid endpoint and out-of-range/NaN; encoder sign/ratio round trip;
wrong actuator type; missing optional/required sensor; no partial hardware write
after frame validation fails; STOP; disconnect; paired JSON fixtures; a shooter
command cannot move the chassis. Android assembly required. Exit: a synthetic
all-device rig runs the shared core with equivalent RealHal contract fakes and SimHal.

## B02 — intake power and pollen-only physical capture

Owners: R `subsystem` intake implementation, S intake plant and floor fixture.
Port archive signed power/brake semantics; state vocabulary OFF, INTAKE, REVERSE,
FAULT is sufficient. Controller requests intent; only subsystem sets output. Reverse
is explicit recovery, not a hidden oscillating jam algorithm. No automatic vision
selection yet.

S models motor spin-up and a capture mouth attached to the robot. A free pollen
ball can enter only when it intersects the mouth, relative motion/contact permits
entry, roller direction is inward, and storage has space. Use a conservative swept
mouth/contact test to avoid teleport capture at high speed. Internal inventory
owns the object after capture; remove its free-world body exactly once. Reverse
releases at the mouth with bounded outward velocity. A full intake pushes/jams
according to the fixture, never deletes the object.

Nectar never becomes our inventory. Its collision body can block the mouth; model
physical exclusion from provisional mouth/ball geometry, not only a perfect
semantic classifier. If final dimensions cannot reject it, report a mechanical
dependency; software cannot guarantee a physically selective intake by naming it.
Fixture capacity is explicit (e.g. three for a test), not an asserted robot capacity.

Tests: forward/hold/off/reverse/STOP actuator traces; capture one pollen once;
stationary-off and reverse cannot capture; full inventory; two simultaneous balls;
nectar-only and mixed clutter; side/rear contact; high-speed pass; disconnect during
capture; conservation before/after release/reset. At fixed seed identical events.
Exit: driver can collect and reverse pollen in Pymunk with real Java intake code.
No global ball identity or true internal count is exposed as a nonexistent sensor.

## B03 — feeder timing with one owner

Owner R: small `PulseFeeder` within subsystem layer; introduce `IFeeder` only if
needed for engine/test consumers. S: feeder motor and transfer timing/geometry.
Do not leave pulse state split between shooter stub and engine timers.

States: IDLE -> PULSING -> GAP -> IDLE (or next permitted pulse); FAULT separately.
Archive-derived initial pulse 350 ms; verify active gap/delay configuration in A04.
Use injected monotonic time. A normal request release/clear finishes the current
pulse but starts no new one. Explicit STOP/cancel/fault zeros output this tick and
clears pending requests. Coalesce held requests; do not enqueue a pulse every tick.
Bound requested shot counts and report started/completed/interrupted pulses distinctly.

S transfers an existing stored pollen through a finite feed path when motor travel
and direction permit. A feeder event alone does not spawn a projectile. Track
physical ball transfer separately from software pulse completion; an empty pulse
is possible. Reverse/jam behavior is explicit, not magical replenishment.

Tests: single pulse, held request, release mid-pulse, explicit cancel mid-pulse,
gap boundaries ±1 tick, irregular dt, time reset, empty storage, jam, reverse,
engine switch and no delayed restart. Command timing equals golden archive trace
within one tick, with exact direction and terminal-result count.
Exit: motor trace and physical transfer agree causally; last pulse cannot leak into
a new engine epoch. No flywheel-ready assumption is embedded in feeder mechanics.

## B04 — inventory belief and full intake/feed integration

Owners: R belief/feedback; S independent truth/physical transfers. This is not yet
the field world model. Separate `inventoryTruth` inside S from Java's estimate.

If the archived robot lacks a beam break, expose an estimate with unknown/range
and confidence, not a perfect counter. Commanded feeder pulses can lower an estimate
but do not prove release. Later real sensor evidence can confirm transitions.
Use minimal fields: count estimate or interval, confidence, last evidence time,
reason. Do not invent virtual hardware inputs to make tests pass. Fixture sensors
may exist only under an explicitly labeled test hardware profile.

Shot coordinator may stop on confirmed empty; unknown inventory follows a bounded
operator-request policy and timeout. Never schedule infinite dry feeds. Intake and
feeder ownership must agree on internal transfer; one ball cannot occupy two places.

Acceptance scenario: collect two pollen among nectar clutter, reverse one, recollect,
feed one, interrupt next feed, reset. Assert physical conservation, expected motor
traces, honest belief uncertainty and no stale ownership. Inject sensor faults and
empty pulses; confidence must not increase from a command alone. Exit: B01–B04
cross-reviewed with baseline drive suite still green; fixed-shot work can begin.
