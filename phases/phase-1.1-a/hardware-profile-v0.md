# Hardware profile v0 — archive mechanism AND actuator counts

Status: DRAFT v2.1 reference, 2026-09-17. No code/hardware changes authorized.
Authority: Tuna's direct clarification supersedes the review's single-actuator
interpretation. ONE mechanism does NOT mean one motor/servo. Preserve both counts.
Every spec uses this page. RobotConstants.java is the compile-time source; Python
sim/mechanism.py reads the SAME file. No mechanism.yaml. OLD = archive DE-Cock
TeamCode/src/main/java/org/firstinspires/ftc/teamcode; HC = OLD/config/HardwareConstants.java.

| Function | HardwareMap name / type | Source/setting |
|---|---|---|
| Four wheels | leftFront, rightFront, leftBack, rightBack / DcMotorEx | OLD/hardware/subsystems/drivetrain/pedroPathing/Constants.java; left reversed/right forward |
| ONE shooter, TWO motors | shooterRight, shooterLeft / DcMotorEx | HC.Shooter; right REVERSE, left FORWARD; RIGHT speed source; followerScale1 |
| ONE intake | intake / DcMotorEx | HC.Intake; reversed, default power1 |
| ONE feeder | feeder / DcMotorEx | HC.Feeder; forward, feed power1 |
| ONE turret, TWO CR servos | turret_servo, turret_servo2 / CRServo | HC.Turret; both FORWARD, same logical power |
| Turret incremental input | shooterLeft / encoder of the SAME active shooter motor port | HC.Turret.encoderName; software sign reversed; not another motor |
| Turret startup analog | turret_analog / AnalogInput | HC.TurretPidPazar; 0–3.3 V, shaft offset125° |
| ONE hood, TWO position servos | hood_left, hood_right / Servo | HC.Hood; complementary commands, LEFT inverted |
| Odometry | pinpoint / GoBildaPinpointDriver | Archive Pedro constants; existing161/0 mm offsets |
| Reserved, unsensed in B | intake_dist; limelight | HC.Intake.ballSensorName / Limelight.name; no fake readings or required optional device |

Totals:8 DC outputs (4 drive+2 shooter+intake+feeder),2 position servos,2 CR servos.
Bind each HardwareMap name ONCE. Shooter owns BOTH motor powers; turret only reads
the shooterLeft encoder, never writes its motor power/direction. Central initialization
owns reset/configuration before enable; no competing runtime reset. In sim, that
port's encoder follows turret angle, NOT shooter motor shaft rotation. Do not invent
a second shooter speed sensor. STOP zeroes both shooter motors and both turret CR
servos; both hood servos hold. Preserved names/counts do not replace a bench check.

Active-source evidence (OLD-relative, not unused alternative implementations):
Archive robot-code commit `d7711d043280034ab5c75ae26a253629fd2d4a7b` (tracked files unchanged).
`contingency/lvbelc5/teleop/{BlueTeleop,RedTeleop}.java:54` constructs `Robot.java:77`
(shooter),`:80`(hood),`:81`(feeder),`:82`(intake),`:84`(turret).
`hardware/subsystems/shooter/ShooterPidfPowerSubsystem.java:44` binds both motors;
`:268` writes right=p,left=p*followerScale. `hood/HoodSubsystem.java:21` binds both;
`:40` computes both positions. `turret/TurretPidPazarSubsystem.java:56` binds both CR
servos;`:66` reads the shared motor port;`:308` writes the same power to both.
Hood/turret paths above are under the same `hardware/subsystems/` directory.

## Inherited constants (retune/verify physically; not new measurements)

- Shooter HC.Shooter:28 ticks/motor rev, motor-to-wheel factor1.6, wheel4 in. Nearby
  8192-CPR/1:1 comments contradict these actual values. Fixture uses28/1.6; physical
  RPM verification remains required. HC.ShooterPIDF: kS=.18766200, kV=.00013514,
  kP=.00030984, kI=.00189683, kD=.0000126816; integral zone250 RPM, clamp3000 RPM·s;
  ready±100 RPM for150 ms; slew disabled. TWO motor outputs, one shooter controller;
  followerScale1.0. Preserve output polarity without double-negating in logic.
- Feeder HC.FeederPower pulse350 ms; HC.Feeder.postPulseDelayMs=500 default. Active
  OLD/contingency/lvbelc5/controllers/ShootingController.java requests100 ms instead:
  keep both named presets; legacy-match uses100 ms. Intake capacity3; intake_dist is
  declared but unused by the active intake, so inventory is unsensed.
- Hood HC.Hood:25–50° -> travel0–215° out of300°; rightInverse=false:
  right=((clamp(angle,25,50)-25)/25)*215/300; left=1-right. Stow25°, default44°,
  recovery45°. At25/44/45/50°, (left,right)=(1,0)/(.4553333333,.5446666667)/
  (.4266666667,.5733333333)/(.2833333333,.7166666667). ONE hood angle, no angle sensor.
- Turret HC.Turret:±90°,8192 ticks/rev; degrees/tick=360/(.715*8192), before sign.
  HC.TurretPidPazar PID=.0171/.0401/.002,kS0; analog LPF.1, Kalman Q.1/R50,
  startup.75+1.25 s. Use behavior/constants, not an auto-tuning project.
- Baseline chassis18×18 in/12 kg stays unchanged; archive13.8 kg is not substituted
  incidentally. Braking36.17/85.98 in/s², source speeds73.63/54.09 in/s retained.
  Only wheel-role motors generate chassis forces.
- Early objects: pollen diameter2.8 in, nectar3.6 in, pinned BIOBUZZ manual§9.8
  (source in retained chapter F). B02 mouth geometry is a labeled fixture, not a
  measured robot. Collect pollen ONLY; nectar remains external game geometry.

B01 owns one-line RobotConstants name declarations: four drive names plus
SHOOTER_RIGHT_MOTOR_NAME, SHOOTER_LEFT_MOTOR_NAME, SHOOTER_FEEDBACK_ENCODER_NAME,
INTAKE_MOTOR_NAME, FEEDER_MOTOR_NAME, TURRET_PRIMARY_SERVO_NAME,
TURRET_SECONDARY_SERVO_NAME, TURRET_ENCODER_NAME, TURRET_ANALOG_NAME,
HOOD_LEFT_SERVO_NAME, HOOD_RIGHT_SERVO_NAME, INTAKE_DISTANCE_NAME, LIMELIGHT_NAME.
Feedback name literals are shooterRight / shooterLeft respectively: two input roles,
not duplicate device bindings. Parser supports these references, never arbitrary Java.
No unused digital channels or nectar mechanism. B07 introduces analog when consumed.
