# B05–B09 v2.2 — paired actuators, one controller per mechanism; useful cplx1

Status: DRAFT, not dispatched. Read [00](00-common.md) and
[hardware-profile-v0](../hardware-profile-v0.md). B05–B07 follow B01 and consume
B03 as needed; B08 waits for B02–B07. One evidence-B.md, three B09 e2e scenarios.
Paths below use00 aliases. Unit-test classes are proposed unless already present.

## B05 — ONE shooter, TWO flywheel motors; feedback/readiness

R: `J/subsystem/shooter/FlywheelShooter.java`, `J/subsystem/IShooter.java`,
J/RobotFactory.java; tests `JT/subsystem/shooter/FlywheelShooterTest.java`.
S: `sim/physics/mechanisms.py`, `tests/test_flywheel_plant.py`. Archive source:
OLD/hardware/subsystems/shooter/ShooterPidfPowerSubsystem.java and
OLD/config/HardwareConstants.java::Shooter/ShooterPIDF and
OLD/settings/storage/shooter/ShooterPidfPowerStorage.java. Archive periodic PID,
feedforward, integral limits and readiness read that dashboard-tunable storage at
RUNTIME; HC values below are boot defaults, not necessarily match-used values.
Do not import Android timing or FTCLib's scheduler into core.

TWO DcMotorEx outputs shooterRight/shooterLeft, ONE shooter controller and ONE
measured velocity source shooterRight (RIGHT). Preserve archive setMotorPower:
right=p; left=p*followerScale with followerScale1.0. HAL applies right REVERSE,
left FORWARD once; BOTH zero-power FLOAT. Disable/cancel zeroes BOTH commands,
not instantaneous physical RPM. shooterLeft is simultaneously an
active shooter output and turret encoder INPUT, never a second shooter speed source.
Inherited conversion: wheelRPM=velTicksPerSecond*60/28*1.6, encoderReversed=false;
output reversal belongs in Hardware, not another software negation. At1166.6666667
raw ticks/s expect4000 wheelRPM. Actual28/1.6 contradict nearby archive comments;
require physical verification before trusting real speed, not a made-up8192 replacement.

Port power PIDF with kS=.18766200,kV=.00013514,kP=.00030984,kI=.00189683,
kD=.0000126816; integral zone250 RPM/clamp3000 RPM·s; FF disabled absTarget<1500;
ready±100 RPM continuously150 ms; slew0(disabled). Verify exact archive calculation
with no-error4000 RPM feedforward=.728222 on BOTH logical outputs. Topology is
unchanged; inherited tuning remains a starting point, not new physical validation.
Use HAL ms converted to seconds,
protect abnormal dt. Resets follow the archive (ShooterPidfPowerSubsystem:64-68, :79-86):
a >50 RPM target change clears only readiness (stable flag and stability timer); integral
and previous error are cleared only on disable. Deliberate non-archive addition (safety):
an accepted tuning change and an invalid velocity sensor also clear controller and
readiness; the archive has static tuning and no sensor-loss concept.
Saturation/anti-windup correction must be explicit compared with source trace.

Preserve live tuning with proposed SDK-free `J/subsystem/shooter/ShooterTuning.java`
snapshot and one injected supplier into FlywheelShooter (one read per tick). New
FTC-only `R/TeamCode/src/main/java/org/firstinspires/ftc/teamcode/tuning/ShooterTuningConfig.java`
uses already-declared Dashboard0.5.1 @Config; initializes from RobotConstants defaults.
No tuning framework/new dependency. Sim uses the same core with a fixed default
supplier or explicit scripted snapshot changes. Record initial values and changes
in trace; don't claim constantsHash alone identifies a live-tuned run. Invalid
nonfinite/negative limits reject safely; accepted changes clear integral/readiness
before recomputing (documented safety policy). `FlywheelShooterTest` must verify
live gain/tolerance/dwell change, no mixed snapshot within a tick, invalid tuning
and deterministic replay; no constructor-only freezing of archive-tunable gains.

Facade implements existing IShooter and owns composed PulseFeeder (B03), then
PairedHood (B06). Facade observes/updates its parts ONCE; do not also register them
as top-level Subsystems entries. feed/isFeeding delegate to PulseFeeder; no old
StubShooter pulse timer remains in the real profile. No duplicate shooter subsystem,
per-motor PID or fabricated follower-velocity readiness requirement.

S starts with ONE effective shooter-speed state driven by BOTH motor outputs:
effective effort=(rightApplied+leftApplied)/2 after mounting polarity mapping. Use
B01 fixture free RPM/tau and voltage; zero-command FLOAT coasts, not BRAKE.
This aggregate first-order plant is a labeled
fixture, not proof of a shared shaft or independent wheels; source code proves motor
commands, not mechanical gearing. Disabling one motor halves effective drive effort;
opposed efforts cancel. Do not silently ignore the follower or double nominal RPM.
Apply15% speed loss on ONE physical passage, never spawn a ball per motor.
Expose speed through archived shooterRight; shooterLeft enc/vel follows the turret.
This does NOT prove hardware mechanical coupling or guarantee detection of a left-motor
failure: no hidden-truth readiness/fault injection into Java. Java owns PID/readiness.
Tests:
4000 conversion, FF threshold1499/1500, step up/down, saturation/recovery, stale/missing
velocity, shot dip, cancel/restart; both output powers and configured polarities,
followerScale, same-tick pair stop; stationary turret encoder during shooter spin;
one disabled motor reduces plant effort without inventing a Java sensor.
Seed1 plant test, seed42 disturbed replay. Gate:
nominal fixture reaches ready within3 s, loses ready on a>100 RPM dip, does not feed
before re-ready. If inherited gains fail the fixture, report/tune with evidence;
do not claim physics accuracy from fitting the plant to the controller inverse.

## B06 — ONE hood, TWO complementary position servos

R: `J/subsystem/hood/PairedHood.java`, facade wiring, explicit IShooter methods
`setHoodAngleDeg(double)` / `hoodSettled()`; update StubShooter and SubsystemTrace
wrappers compatibly without claiming their synthetic feedback is physical.
Tests: `JT/subsystem/hood/PairedHoodTest.java`, `SJT/SimHalTest.java`.
S: sim/physics/mechanisms.py, tests/test_hood_plant.py. Read OLD/hardware/subsystems/
hood/HoodSubsystem.java and HardwareConstants.Hood.

Bind BOTH hood_left and hood_right. Clamp ONE mechanism angle25..50°;
u=((angle-25)/25)*215/300. With archive rightInverse=false: left=1-u, right=u.
Commands are mirrored because both servos move the SAME hood, not independent axes.
Test25/44/45/50° ->(1,0)/(.4553333333,.5446666667)/
(.4266666667,.5733333333)/(.2833333333,.7166666667), tolerance1e-9.
Trim default0; inversion belongs to profile mapping, not another HAL reversal.
Generate both commands from one clipped angle in the same action; no partial pair.
S models ONE hood degree of freedom; both targets must imply the same angle.
Reject incompatible target pairs; a physically stuck servo may jam the fixture,
but without position feedback Java cannot magically detect it.

On init do not move or falsely report measured44°. First explicit setpoint starts
settling estimate. Default44°/stow25° come from HC.Hood; recovery45° comes from
OLD/contingency/lvbelc5/controllers/RecoveryController.java:29 DEFAULT_HOOD_ANGLE,
not HC.Hood. No angle sensor: status is
commanded/estimated only. Fixture mechanism rate90°/s and settling margin100 ms;
unknown initial position budgets worst-case25° travel. Same constants consumed by
S; actual hardware may be slower. Interrupted command recomputes travel; STOP/switch
holds BOTH last commanded positions per B01. Tests include bounds, initial absence,
both-omitted hold, half-pair rejection, complementary endpoints, right explicit0
with left1, settle deadline and switch tick. B01 already lifts server's nonempty-servo
rejection; prove real-core -> SimHal -> plant motion. No engine tag yet.

## B07 — ONE turret, TWO CR servos; analog seam and reachable aim API

R: `J/subsystem/turret/PairedCrTurret.java`, `J/subsystem/ITurret.java`,
`J/logic/cplx1/TurretLogic.java`, H/{Hardware,RealHal}.java, J/contract/RobotState.java,
SJ/SimHal.java; tests `JT/subsystem/turret/PairedCrTurretTest.java`,
`JT/logic/cplx1/TurretLogicTest.java`, SJT/SimHalTest.java.
S: sim/mechanism.py, sim/server.py, sim/physics/mechanisms.py, tests/test_turret_plant.py.

B07.0 extends chapter ADR/binding protocol before code: proto3 introduces
state.analog (name->volts sampled at state's t_ms) and ready.analogs name list.
Missing required value is invalid, never0. Add one-line ANALOG_INPUTS declaration
containing TURRET_ANALOG_NAME and explicit parser support. IHal is unchanged;
RobotState gains immutable analogVolts map with compatibility constructor for tests.
Paired protocol-v3 fixtures test units, missing/out-of-range and ready mismatch.
No digital, camera or range fields are introduced here.

Bind turret_servo AND turret_servo2 CR outputs, the existing shooterLeft encoder
INPUT and turret_analog AnalogInput. BOTH CR directions FORWARD; archive writes
the same logical power to both. Do NOT copy hood inversion onto the turret.
One feedback loop/angle, two outputs; zero BOTH during init/STOP.
shooterLeft motor power remains owned by shooter, never zeroed by turret init/stop.
HC.Turret degrees/tick=360*1/(.715*8192),
encoderReversed=true. Hard range[-90,+90]°. HC.TurretPidPazar PID.0171/.0401/.002,
kS0, HC.Turret.maxPower1. Keep HC:305–307 aimAssistLimitMarginDeg10,
aimAssistTurnGain.3, aimAssistTurnMax.8 as provenance, not an automatically enabled
chassis controller; B's5° fixture soft-margin below is a distinct proposed safety
parameter, not the archive10° aim-assist margin. Read encoder without changing its
motor direction or FLOAT mode. Archive ctor resets/configures this shared port;
B01 centralization deliberately fixes that competing ownership. Startup analog
volts0..3.3 -> shaft degrees; subtract125°, divide by.715 then normalize sensor
angle; never wrap an actuator command through a hard stop. Retain source LPF.1,
Kalman Q.1/R50, .75 s trust+1.25 s fade as small private calculation, no filter framework.
During2 s calibration outputs0; invalid/unreachable initial angle prevents auto aim.
Document source snap-to-zero behavior explicitly; disable it in v0 to avoid concealing
real offset (intentional correction, tested), not silently assume zero on startup.

API additions owned HERE: `void disable()` for zero-power/no-auto-restart versus
`hold()` for closed-loop position hold; and `ITurret.AimResult aimRelative(double angleRad)` with
ACCEPTED / OUT_OF_RANGE / INVALID_INPUT / NOT_INITIALIZED. Keep existing void
`aimAt(fieldX,fieldY)` for compatibility; implement it via shared geometry and expose
latest reachability, not clamping then reporting success. Update StubTurret and
SubsystemTrace wrapper implementations/tests. `hold()` cancels stale aim/scan ownership
but keeps valid current angle; stop disables power. Stub scan remains test-only.

TurretLogic gains explicit target selection (fixed-relative preset vs field target),
not an unconditional overwrite from GOAL_X every sense. B08 replaces CplxEngine1's
blanket TURRET_AIM rejection with validated target/owner handling and cancels an
incompatible shot. Future ShotSolutionModule uses this SAME target setter, not a
second turret controller. Bound target jumps and reduce power near stop; fixture
initial soft-margin5°, no outside-limit command. Manual release returns to hold.

Tests: seed1 analog1.1458333333 V represents0°, encoder sign/gear, ±45° targets,
±90° bounds and91° rejection, NaN, encoder reset/loss, hold during pending scan,
startup invalid analog and STOP. Settled fixture criterion<=2° and<=5°/s for100 ms;
no hard-stop penetration. Assert both CR powers match and stop together. Simulator
angle/rate, analog and shooterLeft encoder come from ONE turret plant driven by
both CR outputs; shooter motor power does not drive that encoder. Use mean of the
two applied CR efforts for initial fixture torque scale; this is a labeled plant
approximation, not measured gearing/torque. A disabled CR reduces available effort;
no invented per-servo sensor. Repeat shared-port test while simultaneously spinning
shooter and aiming turret: right feedback follows shooter, left encoder follows
turret, and neither subsystem writes the other's outputs. Java controls the plant.
Cross-review analog/name seam, Android build and B-takeover.

## B08 — shared shot coordinator, real preset and PLANAR release

R keeps J/logic/cplx1/{CplxEngine1,ShooterLogic,TurretLogic,MotionLogic}.java;
new `J/logic/shot/ShotPreset.java`, `J/logic/cplx1/PoseMotionEstimator.java`;
facade includes feeder/hood. Tests `JT/logic/cplx1/FixedShotCoordinatorTest.java`,
`PoseMotionEstimatorTest.java`, existing ShooterCancellationTest and EngineCancelAllTurretTest.
S owns sim/physics/mechanisms.py + balls.py, tests/test_planar_release.py.

B08.0 explicitly replaces real-profile count-only shot defaults: RPM4000,hood45°,
turret0°, from RecoveryController defaults. Both direct/cplx1 real profiles use the
same ShotPreset; current ShooterCalibration300+distance/hood0 remains ONLY legacy
stub-profile behavior. Extend ShooterRpmConsistencyTest with real-profile preset
cases; preserve legacy fixtures under explicit stub profile. Never feed a real
flywheel using the unprovenanced300-RPM placeholder or call it calibrated.

Preserve ShootingController SHOOT_INTAKE_POWER=.8 (:38): while the shot coordinator
owns warmup/shooting, command IIntake.run(.8); intake-only uses default1. Recovery/
cancel/fault precedence wins; releasing shot ownership restores the current manual
intake demand or0, never stale. No automatic.2 idle hold from an unused HC field.
`FixedShotCoordinatorTest` pins this ownership trace, feeder350-ms pulse +100-ms
post-pulse delay, and same-tick cancel. Use one intake output owner, not a second
ShooterLogic HAL write. B09 nominal trace includes actual intake power and pulse/gap.

Extend request catalog in a phase-1.1-a addendum (historical catalog unchanged):
SET_SHOT_PRESET[rpm,hoodDeg,turretRad], STOP_SHOOTING[](finish current pulse, no new
ones, then spin the flywheel down), MECHANISM_RECOVERY[mode] (0 exit,1 reverse intake/feeder,2 operator-held jam
clear). Add RequestType entries/parsing/trace tests explicitly. SHOOT retains existing
count,optionalRPM contract; bounded max count3. CANCEL_ALL remains immediate stop.
(Spec correction 2026-09-25, archive lvbelc5 ShootingController:111-121,188-190.)
A completed SHOOT keeps the flywheel at its rpm; only STOP_SHOOTING, CANCEL_ALL or a
jam clear spin it down. This matches RT held = AUTO_SHOOT: shots within one RT hold
have no spin-down between them. The RT falling edge MUST send STOP_SHOOTING. If a
pulse is running, it finishes (archive FINISHING_PULSE) and then the flywheel is
disabled. Autonomous routines send STOP_SHOOTING at their end. Tests: no spin-down
between shots while RT is held; an RT release mid-pulse finishes that pulse and then
disables the flywheel; every auto ends with STOP_SHOOTING.
No new wire packet is needed for these Java controller->logic requests, but debug/
bag enum round-trip tests must be updated. Do not overload TURRET_AIM field coordinates
with relative-angle units; SET_SHOT_PRESET supplies relative turret angle.

Controller owner R: `J/controller/teleop/LegacyMatchMap.java`, TeleopController profile
selection; `JT/controller/teleop/LegacyMatchMapTest.java`. Keep current diagnostic map.
Port A04 RT/RB hold, LT intake, LB reverse, D-pad offsets, BACK2 s recovery, B held
park/release and START+Y2 s reset with explicit precedence. RT/RB request one shot at
a time after previous terminal feedback; release sends STOP_SHOOTING, not hard cancel.
Y jam-clear remains deliberate held recovery, never an autonomous retry: power-sign
changes require spin-down before reverse in v0 (documented safety correction to old
instant±1 toggle). Exclude GP2 tuning menus, camera/zone dependence until later.
START+Y consumes Y and blocks conflicting engine-switch chord. START alone uses
existing explicit engine selector only after chord disambiguation/release.

States IDLE/PREPARE/FEED/RECOVER/COMPLETE/FAULT, implemented in existing ShooterLogic,
not another scheduler. CANCEL_ALL disables turret and stops feeder/flywheel until a
fresh request; idle sense must not re-arm a cancelled target. Feed requires measured shooter-ready, estimated hood-settled,
valid reachable/settled turret, no fault and stationary gate. Latch preset per pulse;
recheck before next pulse. Prepare timeout3 s AFTER turret startup ends. If startup
has not ended within one turret calibration window, the prepare timeout starts anyway.
That bound is SHOT_TURRET_STARTUP_BOUND_MS = (TURRET_FULL_TRUST_S + TURRET_FADE_OUT_S)
x 1000. It is a derived bound, not an archive value, and is computed from those two
constants, never written as a literal (spec correction 2026-09-25). Stop before
startup is always accepted. No readiness from elapsed spinup alone.

PoseMotionEstimator derives speed from Pinpoint samples already in RobotState: fixed
200 ms window difference, unwrap heading once; speed=distance/dt, yawRate=wrapped
heading difference/dt. Window unavailable, nonmonotonic/reset time, sample gap>100 ms
or explicit localization reset invalidates gate. Require<=2 in/s and<=5°/s for150 ms.
Tests include noise at existing .05 in/.002 rad, constant velocity, reset/jump and
missing history. This is estimated motion, not a new truth or wheel-speed sensor.

S release definition in B: existing outlet pollen becomes ONE planar Pymunk body at
fixture muzzle forward9 in. Seeded plant uses measured flywheel RPM to set planar
exit speed (`RPM*pi*4/60*.05` fixture slip factor); add chassis muzzle velocity.
No vertical flight, ballistic accuracy or BIOBUZZ scoring claim. C03 upgrades this
same transition later. Empty/jammed feed never spawns a ball; diagnostic events alone
cannot release. Apply15% flywheel dip on actual passage, require recovery for next
pulse. A simple lab catch tray verifies delivery; it is not a real elevated goal.

## B09 — three e2e scenarios and cplx1 checkpoint

R factory's real-mechanism profile selects PowerIntake + FlywheelShooter
(composed PulseFeeder/PairedHood) + PairedCrTurret; no required stubs. Direct and
cplx1 share these objects safely. Stub profile remains explicit for historical tests.
Extend A03 runner with R/tools/fixtures/phase11a-B.json and
SJT/MechanismAcceptanceTest.java; S/tests/test_acceptance_scenarios.py.
Use SAME Java RobotLoop/core on Pymunk,20 ms, seeds1 and42, repeat1 fresh-process.

- **B-collect-feed**: robot(36,72,0), pollen(48,72),(54,72), nectar(54,84) (spec
  correction 2026-09-25: at (54,78) the 18 in robot body sweeping y63..81 must hit it;
  82.8 = 72+9+1.8 is the exact contact limit, 84 leaves margin for seed42 ±.1); scripted
  LT+drive collects two, then drives to(72,72,0) and stops; fixed preset4000/45°/0°,
  request2 feeds. Lab tray bounds x94..106,y68..76 captures planar releases physically.
  By24 s expect2 pollen in tray,0 stored/outlet, nectar untouched, no extra objects;
  record BOTH shooter powers, BOTH hood positions, BOTH CR powers, measured RPM,
  turret encoder and readiness at each pulse; assert archive pair relationships.
  This is a transfer
  acceptance demo, NOT proof of an elevated competition shot. C owns that proof.
- **B-takeover**: same profile, seeded preload of2 pollen as TEST setup; prepare,
  cancel during pulse, switch to direct then cplx1, manual turret/reverse recovery.
  Assert immediate feeder/BOTH shooter/BOTH CR stop on hard cancel/switch, BOTH
  hood positions held, no old pulse
  restart, exactly one terminal result; objects already released remain physical.
- **B-fault**: same setup; remove shooter velocity at t=3000 ms, restore at4000;
  invalidate turret analog at reset, then explicitly reset with valid sensor;
  inject one empty feed. No feed on invalid readiness, no fake inventory/score,
  explicit fault/recovery and usable manual drive. End by24 s, no automatic restart
  without a fresh request. Dedicated omitted-servo fixture exercises switch safety.

Harness phases use scripted gamepad/requests and available pose/status, not hidden
truth to drive; private truth only checks results. New scenario wall timeout60 s;
failed predicate fails runner regardless of unit test count. Publish ONE visible
nominal demo plus fault trace, focused tests, Android build, seam review notes in
evidence-B. Tag p11a-engine-cplx1-v1 only here with compatible manifest. No hardware-
proven claim, no per-subsystem tags, no C/Vision dispatch until separate approval.
