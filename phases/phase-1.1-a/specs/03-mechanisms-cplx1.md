# B05–B09 v2 — one flywheel, one hood, one turret; useful cplx1

Status: DRAFT, not dispatched. Read [00](00-common.md) and
[hardware-profile-v0](../hardware-profile-v0.md). B05–B07 follow B01 and consume
B03 as needed; B08 waits for B02–B07. One evidence-B.md, three B09 e2e scenarios.
Paths below use00 aliases. Unit-test classes are proposed unless already present.

## B05 — single flywheel feedback/readiness

R: `J/subsystem/shooter/SingleFlywheelShooter.java`, `J/subsystem/IShooter.java`,
J/RobotFactory.java; tests `JT/subsystem/shooter/SingleFlywheelShooterTest.java`.
S: `sim/physics/mechanisms.py`, `tests/test_flywheel_plant.py`. Archive source:
OLD/hardware/subsystems/shooter/ShooterPidfPowerSubsystem.java and
OLD/config/HardwareConstants.java::Shooter/ShooterPIDF; inspect storage overrides
without importing Android timing or FTCLib's scheduler.

ONE DcMotorEx output shooterRight, ONE velocity source shooterRight, ONE plant.
RIGHT encoder selection resolves the old ambiguity; shooterLeft is turret input.
Inherited conversion: wheelRPM=velTicksPerSecond*60/28*1.6, encoderReversed=false;
output reversal belongs in Hardware, not another software negation. At1166.6666667
raw ticks/s expect4000 wheelRPM. Actual28/1.6 contradict nearby archive comments;
require physical verification before trusting real speed, not a made-up8192 replacement.

Port power PIDF with kS=.18766200,kV=.00013514,kP=.00030984,kI=.00189683,
kD=.0000126816; integral zone250 RPM/clamp3000 RPM·s; FF disabled absTarget<1500;
ready±100 RPM continuously150 ms; slew0(disabled). Verify exact archive calculation
with no-error4000 RPM feedforward=.728222. New topology requires retuning; these are
reference candidates, not proven single-wheel gains. Use HAL ms converted to seconds,
clear controller/dwell on target change/disable/invalid sensor, protect abnormal dt.
Saturation/anti-windup correction must be explicit compared with source trace.

Facade implements existing IShooter and owns composed PulseFeeder (B03), then
SingleHood (B06). Facade observes/updates its parts ONCE; do not also register them
as top-level Subsystems entries. feed/isFeeding delegate to PulseFeeder; no old
StubShooter pulse timer remains in the real profile. No follower scale/second motor.

S first-order motor plant uses B01 fixture free RPM/tau, actual voltage and a named
15% wheel-speed loss per physical ball passage. Java owns PID/readiness. Tests:
4000 conversion, FF threshold1499/1500, step up/down, saturation/recovery, stale/missing
velocity, shot dip, cancel/restart. Seed1 plant test, seed42 disturbed replay. Gate:
nominal fixture reaches ready within3 s, loses ready on a>100 RPM dip, does not feed
before re-ready. If inherited gains fail the fixture, report/tune with evidence;
do not claim physics accuracy from fitting the plant to the controller inverse.

## B06 — ONE hood servo, inherited LEFT-channel mapping

R: `J/subsystem/hood/SingleHood.java`, facade wiring, explicit IShooter methods
`setHoodAngleDeg(double)` / `hoodSettled()`; update StubShooter and SubsystemTrace
wrappers compatibly without claiming their synthetic feedback is physical.
Tests: `JT/subsystem/hood/SingleHoodTest.java`, `SJT/SimHalTest.java`.
S: sim/physics/mechanisms.py, tests/test_hood_plant.py. Read OLD/hardware/subsystems/
hood/HoodSubsystem.java and HardwareConstants.Hood.

Bind ONLY hood_left. Clamp mechanism angle25..50°; interpolate servo travel0..215°
of300° and invert LEFT: position=1-((angle-25)/25)*215/300. rightInverse=false in
archive makes LEFT inverted, not right. Test25/44/45/50° ->1/.4553333333/.4266666667/
.2833333333 with1e-9 numeric tolerance. Trim default0; explicit inversion flag belongs
to profile mapping, not a second HAL reversal. No hood_right required or commanded.

On init do not move or falsely report measured44°. First explicit setpoint starts
settling estimate. Default44°, stow25°, recovery45°. No angle sensor: status is
commanded/estimated only. Fixture mechanism rate90°/s and settling margin100 ms;
unknown initial position budgets worst-case25° travel. Same constants consumed by
S; actual hardware may be slower. Interrupted command recomputes travel; STOP/switch
holds last commanded position per B01. Jam cannot be magically detected without a
sensor; call out limitation. Tests include bounds, initial absence, sparse writes,
explicit0, settle deadline and switch tick. B01 already lifts server's nonempty-servo
rejection; prove real-core -> SimHal -> plant motion. No engine tag yet.

## B07 — ONE CR turret, owned analog seam and reachable aim API

R: `J/subsystem/turret/SingleCrTurret.java`, `J/subsystem/ITurret.java`,
`J/logic/cplx1/TurretLogic.java`, H/{Hardware,RealHal}.java, J/contract/RobotState.java,
SJ/SimHal.java; tests `JT/subsystem/turret/SingleCrTurretTest.java`,
`JT/logic/cplx1/TurretLogicTest.java`, SJT/SimHalTest.java.
S: sim/mechanism.py, sim/server.py, sim/physics/mechanisms.py, tests/test_turret_plant.py.

B07.0 extends chapter ADR/binding protocol before code: proto3 introduces
state.analog (name->volts sampled at state's t_ms) and ready.analogs name list.
Missing required value is invalid, never0. Add one-line ANALOG_INPUTS declaration
containing TURRET_ANALOG_NAME and explicit parser support. IHal is unchanged;
RobotState gains immutable analogVolts map with compatibility constructor for tests.
Paired protocol-v3 fixtures test units, missing/out-of-range and ready mismatch.
No digital, camera or range fields are introduced here.

Bind turret_servo CR output, shooterLeft encoder-only input, turret_analog AnalogInput.
One CR output; zero it during init/STOP. HC.Turret degrees/tick=360*1/(.715*8192),
encoderReversed=true. Hard range[-90,+90]°. HC.TurretPidPazar PID.0171/.0401/.002,
kS0, maxPower1. Read encoder without changing its motor direction. Startup analog
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
no hard-stop penetration. Simulator angle/rate, analog and encoder come from one
plant; Java controls it. Cross-review analog/name seam, Android build and B-takeover.

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

Extend request catalog in a phase-1.1-a addendum (historical catalog unchanged):
SET_SHOT_PRESET[rpm,hoodDeg,turretRad], STOP_SHOOTING[](finish current pulse, no new
ones), MECHANISM_RECOVERY[mode] (0 exit,1 reverse intake/feeder,2 operator-held jam
clear). Add RequestType entries/parsing/trace tests explicitly. SHOOT retains existing
count,optionalRPM contract; bounded max count3. CANCEL_ALL remains immediate stop.
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
recheck before next pulse. Prepare timeout3 s AFTER turret startup ends; stop before
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

R factory's real-mechanism profile selects PowerIntake + SingleFlywheelShooter
(composed PulseFeeder/SingleHood) + SingleCrTurret; no required stubs. Direct and
cplx1 share these objects safely. Stub profile remains explicit for historical tests.
Extend A03 runner with R/tools/fixtures/phase11a-B.json and
SJT/MechanismAcceptanceTest.java; S/tests/test_acceptance_scenarios.py.
Use SAME Java RobotLoop/core on Pymunk,20 ms, seeds1 and42, repeat1 fresh-process.

- **B-collect-feed**: robot(36,72,0), pollen(48,72),(54,72), nectar(54,78); scripted
  LT+drive collects two, then drives to(72,72,0) and stops; fixed preset4000/45°/0°,
  request2 feeds. Lab tray bounds x94..106,y68..76 captures planar releases physically.
  By24 s expect2 pollen in tray,0 stored/outlet, nectar untouched, no extra objects;
  record powers/RPM/hood/turret and readiness at each pulse. This is a transfer
  acceptance demo, NOT proof of an elevated competition shot. C owns that proof.
- **B-takeover**: same profile, seeded preload of2 pollen as TEST setup; prepare,
  cancel during pulse, switch to direct then cplx1, manual turret/reverse recovery.
  Assert immediate feeder/CR stop on hard cancel/switch, hood hold, no old pulse
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
