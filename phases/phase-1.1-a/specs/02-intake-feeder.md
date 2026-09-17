# B01–B04 v2 — smallest device seam, pollen intake and feeder

Status: DRAFT, not dispatched. Entry A05. Read [00](00-common.md) and
[hardware-profile-v0](../hardware-profile-v0.md). Exact path aliases are in00.
ONE evidence-B.md, no per-task releases. R/S seam changes get a concise cross-review.

## B01 — explicit contract migration and archive-name HAL

Owners R (Java/FTC), S (parser/server), D/protocol owner (ADR before code).
Read J/hal/{RobotConstants,Mechanism,IHal}.java; J/contract/{RobotAction,RobotState}.java;
H/{Hardware,RealHal}.java; SJ/{SimHal,Json}.java; S/sim/{mechanism,server}.py;
S/sim/physics/{motor,pymunk_backend,multi}.py. Do not add a device framework.

### B01.0 — approve the paired seam before implementing it

Append explicit amendment to chapter ADR from A02; protocol owner updates
D/protokol.md BEFORE either worker codes proto2. No protocol changes during this
planning revision. Migration contract:

| Item | Proto2 behavior / exact owner |
|---|---|
| ready | proto=2; motors, servos, crservos, encoders exact declared name lists; initial state t_ms=0 |
| step.motors | normalized DC power; missing declared key=0 |
| step.crservos | normalized CR power; missing declared key=0 |
| step.servos | positional0..1; ABSENT=HOLD/no new write, explicit0=position0 |
| state.enc / vel | union of output-motor encoder channels and independent shooterLeft input; ticks/ticks-sec, missing required channel invalid |
| state | existing t_ms/pose/voltage/gamepad behavior; truth remains outside core |
| events | diagnostic only; remove old contradictory prose implying events establish physical ball launch; physical transfer comes from plant/actuation |

Proto1 peers fail with clear version mismatch; preserve old source tag for old clients,
not an untested compatibility layer. Add paired fixtures
R/sim/src/test/resources/protocol-v2/{ready,step-hold,step-explicit-zero,state}.json
and S/tests/fixtures/protocol-v2 equivalents, byte-compared in integration check.
Tests: SJT/SimHalTest.java `rejectsProto1ForMechanismProfile` / `omittedServoIsNotZeroFilled`;
JT/contract/RobotActionServoHoldTest.java; S/tests/test_protocol_validation.py
`test_servo_omitted_holds` / `test_servo_explicit_zero_moves`.

### B01.1 — one-line Java constants and matching parser

RobotConstants.java is the only source of names/parameters. Add one-line
`public static final String NAME = literal;` name block from hardware-profile-v0;
keep scalar doubles, String arrays and each `new Motor(...)` on ONE line. Existing
parser only recognizes literal doubles/strings, SERVOS and one-line Motor rows.
Extend S/sim/mechanism.py with explicit CR_SERVOS / ENCODERS array parsing and
resolution of declared String identifiers in arrays/Motor's name argument. Reject
unknown identifiers/arbitrary expressions. Never add YAML or Python-only aliases.

Output names/order: leftFront,rightFront,leftBack,rightBack,intake,feeder,shooterRight.
Servo list=[hood_left]; CR list=[turret_servo]; independent encoder=[shooterLeft].
RobotConstants.buildMechanism currently hardcodes four motorNames: replace with ALL
MOTORS; wheelMotorNames still filters exactly four. Pedro name mapping remains by
wheel geometry, no shooter chassis force. Preserve efficiencies by wheel ROLE when
renaming fl/fr/bl/br; update stale literal-name test/tool fixtures deliberately.
Include mass and new machine-readable declarations in constantsHash.

Represent direction as declared strings FORWARD/REVERSE (existing scalar parser does
not read booleans); store numeric gear/ticks/free-speed separately. Free-speed plant
values without evidence are named fixture values, not hardware specs: intake/feeder
6000 motor RPM, shooter6000 motor RPM with wheel ratio1.6; common tau.1 s initially.
Pollen diameter2.8, nectar3.6, capacity3 and labeled mouth geometry also land here
BEFORE B02 (the early F00 dimension slice). GOAL_X48/RED_GOAL_X96/GOAL_Y96 remain
legacy placeholders, not authoritative BIOBUZZ targets. C owns real target geometry.

Tests: JT/hal/MechanismTest.java and new JT/hal/HardwareProfileTest.java;
S/tests/test_mechanism.py tests name resolution, exact lists, unknown identifier,
wheel-only force contribution, and constantsHash change. Seed1. Hardware profile
keeps old names, not active old secondary devices. No camera/range/digital channels.

### B01.2 — real/sim writes, inputs and safe omission

J/contract/RobotAction adds separate CR map + compatible old constructors;
J/hal/Mechanism adds typed name lists. Keep IHal methods unchanged. Hardware binds
DcMotorEx output motors plus encoder-only shooterLeft, ONE CRServo, ONE Servo.
Set encoder-only motor power0 without changing direction/resetting someone else's
measurement. Read enc/vel from declared input union; do not substitute missing0.
Handshake name mismatch is fatal. A runtime absent reading from a declared channel
remains absent in RobotState, so the affected subsystem faults safely while drive
can remain usable; it is not replaced with0 or confused with malformed JSON/schema.

Add J/contract/ActionValidator.java: validate whole frame names/finiteness/type/range
before writes. On invalid frame, adapters apply DC/CR zero + hood hold and fail
explicitly, not partially write a valid prefix then discover NaN. RealHal writes
position only if key present; SimHal must NOT call fill() for servo map. Motor/CR
zero-fill stays. S/server.py lifts its current unconditional nonempty-servo rejection,
passes sparse servo/CR maps to plants and retains last explicit servo target. Backend
step signatures and multi-robot forwarding update together. Initial no servo command
means no fabricated position readout or automatic startup move.

Tests: JT/contract/ActionValidatorTest.java, SJT/SimHalTest.java,
S/tests/test_protocol_validation.py, S/tests/test_multi_robot.py. Add
R/TeamCode/src/test/java/org/firstinspires/ftc/teamcode/hal/RealHalWriteTest.java
using narrow fake device sinks if SDK unit instantiation is unavailable; reuse the
production write helper, do not write another fake HAL algorithm. Verify invalid
frame powers zero, omitted hood holds across engine switch, explicit0 differs, and
only shooterRight spins. HAL exceptions must reach OpMode finally/STOP safe-write;
review existing thin OpMode cleanup and add coverage if missing. Android build required.

Exit: A-drive/A-cancel with new names pass; one all-device fixture demonstrates
power and positional semantics on both adapters. No engine/module redesign.

## B02 — one intake and a minimum physical pollen scene

R: new J/subsystem/intake/PowerIntake.java implementing IIntake; factory wiring;
JT/subsystem/intake/PowerIntakeTest.java. Port OLD/hardware/subsystems/intake/
IntakePowerSubsystem.java signed run/stop, default1, hardware reversal in HAL once.
No velocity controller or automatic jam-search. S: new sim/physics/balls.py and
sim/physics/mechanisms.py, tests/test_intake_capture.py; use Pymunk, not events.

Fixture constants in RobotConstants: 18-in chassis, mouth at forward9 in, opening
3.2 in, capture depth2 in, capacity3. Sizes2.8/3.6 make pollen passage possible and
nectar excluded in this PROVISIONAL geometry. Capture requires inward spinning roller,
free object crossing mouth, space in storage, and swept contact; off/reverse cannot
capture. Full storage blocks/pushes, never deletes. Reverse releases stored pollen
at mouth; no nectar inventory even among mixed clutter. Do not advertise mechanical
selectivity on the real intake without dimensions/bench evidence.

Fixture seed1: robot(36,72,0); pollen centers(48,72),(54,72),(60,72); nectar(54,78).
Low normalized forward .15 with intake on, stop at pose(51,72,0) using public pose
threshold then neutral; expect3 stored pollen and1 external nectar, no duplicated
IDs and total inventory+world=4. Dedicated geometry tests move nectar
to mouth to verify blocking rather than magical class-based disappearance. Seed42
adds approach offset±.1 in as fixture noise; reference seed1 rerun deterministic.
Exit: same Java intake drives the visible scene; no sensor-truth inventory leakage.

## B03 — one feeder, two documented timing presets

R: J/subsystem/feeder/PulseFeeder.java; JT/subsystem/feeder/PulseFeederTest.java.
S: sim/physics/mechanisms.py, tests/test_feeder_transfer.py. Compose feeder beneath
IShooter adapter later; do not split timers across stub and engine.

States IDLE/PULSING/GAP. Pulse350 ms at power1. `requestPulseAndDelay(gapMs)` coalesces
held requests; default gap500 ms, legacy-match gap100 ms from active ShootingController.
Single pulse and continuous held requests are different. clearRequest stops new
pulses, lets current pulse finish; stop cancels pulse/gap NOW. Time from hal.now only.
At20 ms ticks350 ms completes at360 ms; assert[350,370) ms; gap±one tick. Test100
AND500 ms presets, release mid-pulse, cancel mid-gap, reverse/manual recovery and reset.

S moves ONE existing inventory object to a feed path after enough positive feeder
travel (fixture threshold .35 full-power seconds), never from diagnostic event count.
Before B08, an exit object may be held in a private outlet state for transfer tests;
B08 owns creating its planar world body. Inventory+feed-path+outlet+field is conserved.
Tests include empty pulse/no object, jam, power0, reverse and repeated request. Pulse
completion is not proof of a ball leaving. Exit: timing trace and transfer causality
agree, no ghost ball or residual pulse after switch/STOP.

## B04 — honest unsensed inventory feedback

R: J/logic/cplx1/InventoryEstimate.java with UNKNOWN/estimated count range, confidence
and last-evidence time; JT/logic/cplx1/InventoryEstimateTest.java. Do not add a generic
world model. Intake.ballSensorName=intake_dist and maxBallCapacity3 are known archive
facts; active intake never reads that sensor. Reserve its name but do NOT bind fake
beam-break/distance values to make a perfect counter. No new wire sensor for B04.

Without actual pickup/release evidence, start unknown[0,3]; motor commands alone
cannot confirm capture or empty storage. A bounded operator-requested feed may run
with unknown count, but no infinite dry-feeding scheduler. Keep estimated status
separate from S private truth in trace/evidence. Existing Feedback need not grow a
large world DTO just for this: narrow mechanism diagnostic trace is sufficient now.

Tests: pulse command cannot increase certainty, reset returns unknown, no negative
counts, finite request limit, no access to truth/IDs. Extend B02/B03 scene: reverse
one known fixture ball, recollect, pulse, cancel. Assert physical conservation and
honest Java unknown state side by side. B08 remains owner of actual planar release;
B04 does not silently implement C projectile flight or a score counter.
