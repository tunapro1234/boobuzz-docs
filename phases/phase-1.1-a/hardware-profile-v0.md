# Hardware profile v0 — single actuators, archive-compatible names

Status: DRAFT v2 reference, 2026-09-17. No code/hardware changes authorized.
Every spec uses this page. RobotConstants.java is the compile-time source; Python
sim/mechanism.py reads the SAME file. No mechanism.yaml. OLD = archive DE-Cock
TeamCode/src/main/java/org/firstinspires/ftc/teamcode; HC = OLD/config/HardwareConstants.java.

| Function | HardwareMap name / type | Source/setting |
|---|---|---|
| Four wheels | leftFront, rightFront, leftBack, rightBack / DcMotorEx | OLD/hardware/subsystems/drivetrain/pedroPathing/Constants.java; left reversed/right forward |
| ONE flywheel output + velocity | shooterRight / DcMotorEx | HC.Shooter; reversed output, RIGHT speed source |
| ONE intake | intake / DcMotorEx | HC.Intake; reversed, default power1 |
| ONE feeder | feeder / DcMotorEx | HC.Feeder; forward, feed power1 |
| ONE turret actuator | turret_servo / CRServo | HC.Turret; not reversed |
| Turret incremental input ONLY | shooterLeft / DcMotorEx encoder port | HC.Turret.encoderName; software sign reversed, NOT second flywheel output |
| Turret startup analog | turret_analog / AnalogInput | HC.TurretPidPazar; 0–3.3 V, shaft offset125° |
| ONE hood | hood_left / Servo | HC.Hood; retain LEFT inverted mapping |
| Odometry | pinpoint / GoBildaPinpointDriver | Archive Pedro constants; existing161/0 mm offsets |
| Reserved, unsensed in B | intake_dist; limelight | HC.Intake.ballSensorName / Limelight.name; no fake readings or required optional device |

Do not activate hood_right/turret_servo2. Extra old devices may remain in the old
configuration, unused. shooterLeft gets no flywheel command or direction mutation;
initialize its output to zero for encoder-only use. Matching names permits unchanged
configuration, NOT proof an old linked mechanism works safely on one actuator.
Bench-check before power; never silently add a second actuator to make it move.

## Inherited constants (retune/verify physically; not new measurements)

- Shooter HC.Shooter:28 ticks/motor rev, motor-to-wheel factor1.6, wheel4 in. Nearby
  8192-CPR/1:1 comments contradict these actual values. Fixture uses28/1.6; physical
  RPM verification remains required. HC.ShooterPIDF: kS=.18766200, kV=.00013514,
  kP=.00030984, kI=.00189683, kD=.0000126816; integral zone250 RPM, clamp3000 RPM·s;
  ready±100 RPM for150 ms; slew disabled. ONE flywheel, no follower scale/second plant.
- Feeder HC.FeederPower pulse350 ms; HC.Feeder.postPulseDelayMs=500 default. Active
  OLD/contingency/lvbelc5/controllers/ShootingController.java requests100 ms instead:
  keep both named presets; legacy-match uses100 ms. Intake capacity3; intake_dist is
  declared but unused by the active intake, so inventory is unsensed.
- Hood HC.Hood:25–50° -> servo travel0–215° out of300°; LEFT is inverted:
  position=1-((clamp(angle,25,50)-25)/25)*215/300. Stow25°, default44°, recovery45°;
  commands25/44/50° =1/.4553333333/.2833333333. No measured hood angle.
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
SHOOTER_MOTOR_NAME, INTAKE_MOTOR_NAME, FEEDER_MOTOR_NAME, TURRET_SERVO_NAME,
TURRET_ENCODER_NAME, TURRET_ANALOG_NAME, HOOD_SERVO_NAME, INTAKE_DISTANCE_NAME,
LIMELIGHT_NAME; parser supports these references explicitly, never arbitrary Java.
No unused digital channels or nectar mechanism. B07 introduces analog when consumed.
