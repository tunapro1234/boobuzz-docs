# B01–B04 v2.2 — smallest device seam, pollen intake and feeder

Status: **B approved but gated; B01 is blocked pending the protected pin of the
ADR record signatures.** Read [00](00-common.md) and
[hardware-profile-v0](../hardware-profile-v0.md). Exact path aliases are in00.
ONE evidence-B.md, no per-task releases. R/S seam changes get a concise cross-review.

## B01 — explicit contract migration and archive-name HAL

Owners R (Java/FTC), S (parser/server), D/protocol owner (ADR before code).
Read J/hal/{RobotConstants,Mechanism,IHal}.java; J/contract/{RobotAction,RobotState}.java;
H/{Hardware,RealHal}.java; SJ/{SimHal,Json}.java; S/sim/{mechanism,server}.py;
S/sim/physics/{motor,pymunk_backend,multi}.py. Do not add a device framework.

### B01.0 — blocked until the paired seam signature pin

The protected amendment is published at `26f915b`; A02 is unblocked at that pin.
This B01 task remains blocked until ftc-main pins the exact record signatures in
`adr-device-seam-v2.md` into the protected protocol. No worker codes proto2 before
that pin. Migration contract:

| Item | Proto2 behavior / exact owner |
|---|---|
| reset | optional `proto`; absent means proto1 (`1`); proto2 requests `2` |
| ready | `proto` advertises the server version; `motors` is the exact DC+CR power-device name list and `servos` the exact positional-servo list; Java validates both before output; initial state `t_ms=0` |
| RobotAction | exactly two value maps: `motors` (DC+CR power) and `servos` (positional); events remain a list, not a third map |
| step.motors | normalized DC and CR power; missing declared key=`0` |
| step.servos | positional `0..1`; ABSENT=HOLD/no new write, explicit `0`=position `0`; never-commanded uses the declared initial position |
| state.enc / vel | unique declared motor-port encoder names; ticks/ticks-sec; shooterRight measures shooter, shooterLeft measures turret despite being a shooter OUTPUT; missing required channel invalid |
| state | existing t_ms/pose/voltage/gamepad behavior; truth remains outside core |
| events | diagnostic only; remove old contradictory prose implying events establish physical ball launch; physical transfer comes from plant/actuation |

Proto1 keeps the full maps and zero-fills omitted entries. For proto2, a mismatch
between `reset.proto` and `ready.proto` fails before output; there is no silent
proto1 fallback. Add the binding fixtures
R/sim/src/test/resources/protocol-v2/{ready,step-hold,step-explicit-zero,state}.json
and S/tests/fixtures/protocol-v2 equivalents, byte-compared in integration check.
Tests: SJT/SimHalTest.java `rejectsProto1ForMechanismProfile` / `omittedServoIsNotZeroFilled`;
JT/contract/RobotActionServoHoldTest.java; S/tests/test_protocol_validation.py
`test_servo_omitted_holds` / `test_servo_explicit_zero_moves`.
Protocol sparse-map tests use a generic servo fixture. In the actual paired-hood
profile, explicit right=0 is valid with left=1 (25°); a left-only zero is NOT a
permitted mechanism command. B01.2 validates the pair before any physical write.

### B01.1 — one-line Java constants and matching parser

RobotConstants.java is the only source of names/compiled profile defaults. Add one-line
`public static final String NAME = literal;` name block from hardware-profile-v0;
keep scalar doubles, String arrays and each `new Motor(...)` on ONE line. Existing
parser only recognizes literal doubles/strings, SERVOS and one-line Motor rows.
Extend S/sim/mechanism.py with explicit CR_SERVOS / ENCODERS array parsing and
resolution of declared String identifiers in arrays/Motor's name argument. Reject
unknown identifiers/arbitrary expressions. Never add YAML or Python-only aliases.
These declarations are PLANNED, not already present: R d5bda62 has fl/fr/bl/br and
SERVOS={}. Static profile/plant defaults stay here; B05's recorded runtime shooter
tuning overrides are controller inputs, not a second Python plant configuration.

Output names/order: leftFront,rightFront,leftBack,rightBack,intake,feeder,shooterRight,shooterLeft.
Servo list=[hood_left,hood_right]; CR list=[turret_servo,turret_servo2].
ENCODERS lists all8 motor-port names exactly once; shooterLeft is NOT a ninth device.
SHOOTER_FEEDBACK_ENCODER_NAME="shooterRight"; TURRET_ENCODER_NAME="shooterLeft".
These input-role declarations override a generic motor-shaft-to-encoder assumption:
S reads shooter speed from the former and turret angle/rate from the latter.
RobotConstants.buildMechanism currently hardcodes four motorNames: replace with ALL
MOTORS; wheelMotorNames still filters exactly four. Pedro name mapping remains by
wheel geometry, no shooter chassis force. Preserve efficiencies by wheel ROLE when
renaming fl/fr/bl/br; update stale literal-name test/tool fixtures deliberately.
Include mass and new machine-readable declarations in constantsHash.

Represent direction as declared strings FORWARD/REVERSE (existing scalar parser does
not read booleans); declare zero-power behavior per motor role too: shooter FLOAT,
intake/feeder BRAKE; existing drive BRAKE unchanged. Store numeric gear/ticks/free-speed separately. Free-speed plant
values without evidence are named fixture values, not hardware specs: intake/feeder
6000 motor RPM, shooter6000 motor RPM with wheel ratio1.6; common tau.1 s initially.
Pollen diameter2.8, nectar3.6, capacity3 and labeled mouth geometry also land here
BEFORE B02 (the early F00 dimension slice). GOAL_X48/RED_GOAL_X96/GOAL_Y96 remain
legacy placeholders, not authoritative BIOBUZZ targets. C owns real target geometry.

Tests: JT/hal/MechanismTest.java and new JT/hal/HardwareProfileTest.java;
S/tests/test_mechanism.py tests name resolution, exact lists, unknown identifier,
wheel-only force contribution, and constantsHash change. Seed1. Hardware profile
keeps ALL active archived actuators/names. No camera/range/digital channels.

### B01.2 — real/sim writes, inputs and safe omission

`RobotAction` retains exactly two value maps (`motors`, `servos`) plus events; CR power
stays in `motors`, with no third map.
J/hal/Mechanism adds typed name lists. Keep IHal methods unchanged. Hardware binds
8 DcMotorEx outputs,2 CRServo and2 Servo devices, each name ONCE. shooterLeft remains
an ACTIVE shooter output (FORWARD); shooterRight is REVERSE. BOTH RUN_WITHOUT_ENCODER,
FLOAT, matching archive; intake/feeder RUN_WITHOUT_ENCODER and BRAKE, not a blanket
motor-mode default. Archive turret ctor resets/reconfigures shooterLeft AFTER shooter
setup (TurretPidPazarSubsystem:67–69); feeder ctor resets its port (FeederPowerSubsystem:34).
NEW deliberate fix: central initialization owns reset/configuration before enable;
reset each required encoder once (shooterRight, turret-input shooterLeft, feeder),
then establish consumer baselines. Do not claim this ownership existed in archive.
turret runtime may read shooterLeft encoder but cannot reset/configure its motor or
write its power. No second HardwareMap lookup/competing owner for the input alias.
Read enc/vel from declared unique inputs; do not substitute missing0 or calculate
shooterLeft encoder ticks from its flywheel shaft in S.
Pinpoint adapter: preserve forwardPodY=161 mm / strafePodX=0 mm,
forward FORWARD / strafe REVERSED, goBILDA_4_BAR_POD. Existing xPodOffsetMm names
the forward-MEASURING pod's lateral offset, not spatial X; yPodOffsetMm names the
strafe-MEASURING pod's forward offset. Keep SDK setOffsets(161,0,MM), no blind swap
and no unused HC.Pinpoint(-84,-168) substitution. Document this in both Pinpoint
records and H/Hardware.java; test exact offsets/directions/pod type through the
production init helper. No record/parser rename solely for terminology in B.
Handshake name mismatch is fatal. Java validates both ready name lists against
RobotConstants before any output. A runtime absent reading from a declared channel
remains absent in RobotState, so the affected subsystem faults safely while drive
can remain usable; it is not replaced with0 or confused with malformed JSON/schema.

Add J/contract/ActionValidator.java: validate whole frame names/finiteness/type/range
before writes and reject every half-pair. On invalid frame, adapters apply DC/CR zero +
hood hold and fail explicitly, not partially write a valid prefix then discover NaN.
RealHal writes a positional servo only if its key is present; SimHal must NOT call
fill() for the servo map. Motor/CR zero-fill stays. Both adapters clear saved servo
holds on reset; a never-commanded servo uses its declared initial position. S/server.py
passes sparse positional-servo maps to plants and retains the last explicit target.
Backend step signatures and multi-robot forwarding update together.

Profile checks stay small: each paired mechanism supplies BOTH outputs or neither;
for hood, left+right=1 within1e-9 and right in[0,215/300]. No half-hood move. For
shooter, left=right*followerScale (1.0); for turret, both logical powers equal.
Omitted pairs use the usual zero/hold policy. Validate BEFORE writes; this is a
software frame guarantee, not a claim of atomic physical bus writes. A device-write
exception triggers best-effort zero on all DC/CR outputs and explicit fault; do not
guess a new hood position after a partially delivered write. Never silently run a
one-actuator fallback on a linked mechanism.

Tests: JT/contract/ActionValidatorTest.java, SJT/SimHalTest.java,
S/tests/test_protocol_validation.py, S/tests/test_multi_robot.py. Add
R/TeamCode/src/test/java/org/firstinspires/ftc/teamcode/hal/RealHalWriteTest.java
using narrow fake device sinks if SDK unit instantiation is unavailable; reuse the
production write helper, do not write another fake HAL algorithm. Verify invalid
frame powers zero, BOTH omitted hood servos hold across engine switch, valid(1,0)
differs from omission, partial/mismatched pairs reject, both shooter outputs are
written, and hardware directions are applied ONCE. Add shared-port tests:
`HardwareProfileTest.shooterLeftHasIndependentOutputAndEncoderRoles`,
`RealHalWriteTest.turretReadDoesNotReconfigureShooterOutput` and
S/tests/test_mechanism.py `test_shooter_left_encoder_follows_turret_not_shooter`.
B01 may use an injected turret-angle fixture; B07 repeats against its real plant.
Add `RealHalWriteTest.initializesZeroPowerBehaviorByMotorRole`,
`RealHalWriteTest.resetsSharedEncoderOnceBeforeEnable`,
`RealHalWriteTest.pinpointPreservesMeasuredAxisMapping` and corresponding
HardwareProfileTest assertions. S's zero-power plant distinguishes FLOAT coast from
BRAKE decay using named fixture damping, not arbitrary equal immediate stops;
Later B05 tests/test_flywheel_plant.py and B02 test_intake_capture.py cover zero-command
decay; B01 tests the declared modes/adapter setup without requiring those later plants.
HAL exceptions must reach OpMode finally/STOP safe-write;
review existing thin OpMode cleanup and add coverage if missing. Android build required.

Exit: A-drive/A-cancel with new names pass; one all-device fixture demonstrates
power and positional semantics on both adapters. No engine/module redesign.

## B02 — one intake and a minimum physical pollen scene

R: new J/subsystem/intake/PowerIntake.java implementing IIntake; factory wiring;
JT/subsystem/intake/PowerIntakeTest.java. Port OLD/hardware/subsystems/intake/
IntakePowerSubsystem.java signed run/stop, default1, hardware reversal in HAL once.
Preserve BRAKE and explicit run(.8) for ShootingController's shoot-intake behavior;
B08 owns selection/precedence. HC.Intake.holdPower=.2 is an unused declaration:
record it, but do not introduce autonomous idle holding; stop remains power0.
Test run1/run.8/run-negative/stop and one-time hardware inversion. No velocity
controller or automatic jam-search. S: new sim/physics/balls.py and
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

## B03 — one feeder,350-ms pulse PLUS100-ms post-pulse delay

R: J/subsystem/feeder/PulseFeeder.java; JT/subsystem/feeder/PulseFeederTest.java.
S: sim/physics/mechanisms.py, tests/test_feeder_transfer.py. Compose feeder beneath
IShooter adapter later; do not split timers across stub and engine.

States IDLE/PULSING/GAP. Pulse350 ms at power1, then100 ms stopped before the next
legacy-match pulse. `requestPulseAndDelay(gapMs)` coalesces held requests; parameter
is the POST-PULSE DELAY, never pulse duration. ShootingController:39 sets100 and
:329,345 passes it. HC.Feeder.postPulseDelayMs=500 is dead (no references), NOT a
default or second preserved preset. Do not silently revive it in the port.
Single pulse and continuous held requests are different. clearRequest stops new
pulses, lets current pulse finish; stop cancels pulse/gap NOW. Time from hal.now only.
At20 ms ticks350 ms completes at360 ms; assert[350,370) ms; gap100±one tick. With
pulse starting t=0, off at360 and next pulse at460 ms in the exact fixture. Test
phase boundaries, release mid-pulse, cancel mid-gap, reverse/manual recovery and reset;
pin no accidental100-ms pulse or500-ms delay. Feeder zero-power behavior is BRAKE.

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
