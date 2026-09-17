# Hardware profile v0 — archive mechanism AND actuator counts

Status: **Tuna-approved v2.2 reference, 2026-09-17. Chapter A is released now; A02 is
unblocked at protected pin `26f915b`; B is approved but gated, with B01 blocked
pending the ADR signature pin, until A05/evidence/tag. C and the far roadmap remain
unreleased. Training, ftc-reviewer, and ftc-ball remain forbidden.** No code/hardware
changes are authorized by this profile before the B gate.
Authority: Tuna's direct clarification supersedes the review's single-actuator
interpretation. ONE mechanism does NOT mean one motor/servo. Preserve both counts.
Every spec uses this page. RobotConstants.java is the source of PLANNED compiled
profile defaults; Python sim/mechanism.py reads that same file. Runtime shooter
tuning is a separate, recorded controller override, not Python plant configuration.
No mechanism.yaml. OLD = archive DE-Cock
TeamCode/src/main/java/org/firstinspires/ftc/teamcode; HC = OLD/config/HardwareConstants.java.
Protected protocol gate: ftc-main published amendment `26f915b`; docs reconciled it at
`0973e86`. Preserve this approved gate state.

| Function | HardwareMap name / type | Source/setting |
|---|---|---|
| Four wheels | leftFront, rightFront, leftBack, rightBack / DcMotorEx | OLD/hardware/subsystems/drivetrain/pedroPathing/Constants.java; left reversed/right forward |
| ONE shooter, TWO motors | shooterRight, shooterLeft / DcMotorEx | HC.Shooter; right REVERSE, left FORWARD; both FLOAT; RIGHT speed source; followerScale1 |
| ONE intake | intake / DcMotorEx | REVERSE, BRAKE; default1, shooting.8; HC holdPower.2 declared but not used by active intake |
| ONE feeder | feeder / DcMotorEx | FORWARD, BRAKE, feed power1; pulse350 ms then100 ms post-pulse delay |
| ONE turret, TWO CR servos | turret_servo, turret_servo2 / CRServo | HC.Turret; both FORWARD, same logical power |
| Turret incremental input | shooterLeft / encoder of the SAME active shooter motor port | HC.Turret.encoderName; software sign reversed; FLOAT; not another motor |
| Turret startup analog | turret_analog / AnalogInput | HC.TurretPidPazar; 0–3.3 V, shaft offset125° |
| ONE hood, TWO position servos | hood_left, hood_right / Servo | HC.Hood; complementary commands, LEFT inverted |
| Odometry | pinpoint / GoBildaPinpointDriver | forwardPodY=161 mm, strafePodX=0 mm; forward FORWARD/strafe REVERSED; goBILDA_4_BAR_POD |
| Intake sensor declaration | intake_dist | HC.Intake.ballSensorName; unsensed by active archive intake and in B |
| Active archive vision | limelight / Limelight3A | Robot.java:87,90 constructs camera + LocalizerController; graceful absence via Limelight.java:44–50; port deferred to Vision-A, NOT historically unused |

Totals:8 DC outputs (4 drive+2 shooter+intake+feeder),2 position servos,2 CR servos.
Bind each HardwareMap name ONCE. Shooter owns BOTH motor powers; turret only reads
the shooterLeft encoder, never writes its motor power/direction. NEW correction:
central initialization owns reset/configuration before enable. Archive turret ctor
DOES issue a competing STOP_AND_RESET_ENCODER on shooterLeft after shooter setup
(TurretPidPazarSubsystem.java:67–69); feeder resets its encoder too
(FeederPowerSubsystem.java:34–36). Consolidate these resets once before enable,
then rebase consumers; do not describe centralized ownership as old behavior. In sim, that
port's encoder follows turret angle, NOT shooter motor shaft rotation. Do not invent
a second shooter speed sensor. STOP zeroes both shooter motors and both turret CR
servos; both hood servos hold. Preserved names/counts do not replace a bench check.

Active-source evidence (OLD-relative, not unused alternative implementations):
Archive robot-code commit `d7711d043280034ab5c75ae26a253629fd2d4a7b` (tracked files unchanged).
OpMode annotations in TeamCode occur only under contingency/lvbelc5 at this commit.
`contingency/lvbelc5/teleop/{BlueTeleop,RedTeleop}.java:54` constructs `Robot.java:77`
(shooter),`:80`(hood),`:81`(feeder),`:82`(intake),`:84`(turret).
`hardware/subsystems/shooter/ShooterPidfPowerSubsystem.java:44` binds left,`:45` right;
`:270–271` write right=p,left=p*followerScale;`:283` sets both FLOAT.
`hood/HoodSubsystem.java:21` binds left,`:22` right;`:44–49` compute both positions.
`turret/TurretPidPazarSubsystem.java:56` binds primary CR,`:61` secondary;
`:66` binds the shared motor port;`:309–310` write equal power;`:69` sets FLOAT.
`intake/IntakePowerSubsystem.java:22` sets BRAKE;`feeder/FeederPowerSubsystem.java:36`
sets BRAKE. Existing new-HAL drive BRAKE remains unchanged in B.
Short subsystem paths above are under the same `hardware/subsystems/` directory.

## Inherited constants (retune/verify physically; not new measurements)

- Shooter HC.Shooter:28 ticks/motor rev, motor-to-wheel factor1.6, wheel4 in. Nearby
  8192-CPR/1:1 comments contradict these actual values. Fixture uses28/1.6; physical
  RPM verification remains required. HC.ShooterPIDF BOOT defaults: kS=.18766200, kV=.00013514,
  kP=.00030984, kI=.00189683, kD=.0000126816; integral zone250 RPM, clamp3000 RPM·s;
  ready±100 RPM for150 ms; slew disabled. TWO motor outputs, one shooter controller;
  followerScale1.0. Runtime gains/tolerance/dwell come from dashboard-tunable
  `settings/storage/shooter/ShooterPidfPowerStorage.java`, NOT frozen HC values:
  shooter`:43` apply(),`:187–189` PID,`:204` tolerance,`:239` FF,`:247` dwell.
  Preserve runtime tuning through an SDK-free snapshot boundary; record active values.
- Feeder active match sequence: HC.FeederPower pulse350 ms PLUS post-pulse delay100 ms.
  `contingency/lvbelc5/controllers/ShootingController.java:39` defines FEEDER_DELAY_MS;
  `:329,345` pass it to requestPulseAndDelay. HC.Feeder.postPulseDelayMs=500 (`HC:612`)
  has ZERO call-site references; dead configuration, not an active default/preset.
  Intake shooting power.8 is ShootingController`:38` (calls`:312,326,341`);
  default1 is HC.IntakePower. HC.Intake.holdPower=.2 (`HC:107`) is declared but unused
  by the active path; do not invent automatic idle holding. Capacity3; inventory unsensed.
- Hood HC.Hood:25–50° -> travel0–215° out of300°; rightInverse=false:
  right=((clamp(angle,25,50)-25)/25)*215/300; left=1-right. Stow25°, default44°,
  recovery45° comes from `contingency/lvbelc5/controllers/RecoveryController.java:29`
  DEFAULT_HOOD_ANGLE, NOT HC.Hood. At25/44/45/50°, (left,right)=(1,0)/(.4553333333,.5446666667)/
  (.4266666667,.5733333333)/(.2833333333,.7166666667). ONE hood angle, no angle sensor.
- Turret HC.Turret:±90°,8192 ticks/rev; degrees/tick=360/(.715*8192), before sign.
  HC.TurretPidPazar PID=.0171/.0401/.002,kS0; analog LPF.1, Kalman Q.1/R50,
  startup.75+1.25 s. HC.Turret.maxPower=1 (`HC:302`); aimAssistLimitMarginDeg10,
  aimAssistTurnGain.3, aimAssistTurnMax.8 (`HC:305–307`). Preserve provenance;
  these declared aim-assist settings do not authorize a new chassis assist in B.
- Pinpoint axis meaning: archived Pedro `drivetrain/pedroPathing/Constants.java:42–48`
  specifies FORWARD pod's lateral Y offset161 mm and STRAFE pod's forward X offset0 mm.
  New RobotConstants PINPOINT stores these as xPodOffsetMm=161 / yPodOffsetMm=0:
  x/y name the measured pod axes, NOT the spatial offset axes. Hardware.java:57
  passes them to SDK setOffsets(161,0,MM); do NOT swap them to "fix" the naming.
  The SDK sample SensorGoBildaPinpoint.java:80–87 documents the same distinction.
  HC.Pinpoint -84/-168 (`HC:728–729`) is unused contradictory configuration, NOT
  the active robot geometry. B01 pins mapping/directions/pod type in adapter tests.
- Baseline chassis18×18 in/12 kg stays unchanged; archive13.8 kg is not substituted
  incidentally. Braking36.17/85.98 in/s², source speeds73.63/54.09 in/s retained.
  Only wheel-role motors generate chassis forces.
- Early objects: pollen diameter2.8 in, nectar3.6 in, pinned BIOBUZZ manual§9.8
  (source in retained chapter F). B02 mouth geometry is a labeled fixture, not a
  measured robot. Collect pollen ONLY; nectar remains external game geometry.

B01 PLANS these one-line RobotConstants name declarations; they DO NOT exist today.
At R d5bda62, drive names are fl/fr/bl/br (RobotConstants.java:67–70), SERVOS={} (:73).
Planned four archive-compatible drive names plus:
SHOOTER_RIGHT_MOTOR_NAME, SHOOTER_LEFT_MOTOR_NAME, SHOOTER_FEEDBACK_ENCODER_NAME,
INTAKE_MOTOR_NAME, FEEDER_MOTOR_NAME, TURRET_PRIMARY_SERVO_NAME,
TURRET_SECONDARY_SERVO_NAME, TURRET_ENCODER_NAME, TURRET_ANALOG_NAME,
HOOD_LEFT_SERVO_NAME, HOOD_RIGHT_SERVO_NAME, INTAKE_DISTANCE_NAME, LIMELIGHT_NAME.
Feedback name literals are shooterRight / shooterLeft respectively: two input roles,
not duplicate device bindings. B01 must ADD parser support; no arbitrary Java parsing.
No unused digital channels or nectar mechanism. B07 introduces analog when consumed.
