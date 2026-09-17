# ADR A02/B01 — device and protocol seam v2

Status: **DRAFT, documentation only.** This ADR is a proposal for the A02/B01
seam. It does not amend `protokol.md`, change code, or authorize an implementation.
`ftc-main` owns any binding protocol edit; the seam remains blocked until that edit
is approved. Source pins for this draft are robot-code `d5bda62`, re-cock-nize
`5dd6daa`, and archive `d7711d0`.

## Context and decision

The current wire contract is proto1. Java sends line-delimited JSON `reset`, `step`
and `bye`; Python returns `ready` and `state`. `RobotAction` contains motor and
servo maps plus events, and its accessors return zero for a missing key
(`robot-code/TeamCode/core/src/main/java/boobuzz/core/contract/RobotAction.java:14-18,44-50`).
`SimHal.fill` sends every declared motor and servo name, filling an omitted value with
`0.0` (`robot-code/sim/src/main/java/boobuzz/sim/SimHal.java:171-207`). `RealHal`
also writes every declared name each tick (`robot-code/TeamCode/src/main/java/org/firstinspires/ftc/teamcode/hal/RealHal.java:63-71`).

Adopt a versioned proto2 seam only after the protected protocol amendment and paired
R/S fixture are approved:

1. Omitted **DC motor** and **CR-servo** commands mean zero power, as in proto1.
2. Omitted **positional-servo** commands mean hold the last explicit position. An
   uncommanded positional servo receives no guessed position; stow/neutral is an
   explicit command or profile action.
3. A proto1 peer continues to receive the current full maps and zero-fill behavior.
   A proto2 peer advertises `ready.proto=2`; mixed versions fail before enabling
   outputs. There is no silent proto1 fallback for a proto2 mechanism profile.
4. `ROBOT_MASS_KG` remains a Java-source configuration value consumed by the Python
   parser; it is not smuggled through a new runtime wire field. The binding protocol
   owner must nevertheless add it to the documented scalar/source contract before
   A02 consumes it.

The choice keeps an explicit safety distinction: power devices stop at zero, while a
position servo does not jump to zero merely because an action omitted it.

## Current and planned device seam

The current Java profile has four drive `Motor` records (`fl`, `fr`, `bl`, `br`) and
an empty `SERVOS` array (`robot-code/TeamCode/core/src/main/java/boobuzz/core/hal/RobotConstants.java:66-76`).
The following archive-compatible names are **planned B01 declarations**, not current
capabilities. Each physical name is bound once by the adapter.

| Role | FTC type | Name(s) and input/output ownership |
|---|---|---|
| Mecanum drive | `DcMotorEx` | `leftFront`, `rightFront`, `leftBack`, `rightBack`; four motor outputs |
| Shooter | `DcMotorEx` | `shooterRight`, `shooterLeft`; one controller writes both, follower scale `1.0`; speed source is `shooterRight` |
| Intake | `DcMotorEx` | `intake`; one output, archive direction REVERSE, BRAKE |
| Feeder | `DcMotorEx` | `feeder`; one output, archive direction FORWARD, BRAKE |
| Turret motion | `CRServo` | `turret_servo`, `turret_servo2`; one angle controller writes equal logical power to both |
| Turret feedback | encoder input on `DcMotorEx` | `shooterLeft` encoder is read for turret angle while `shooterLeft` motor power remains shooter-owned |
| Turret startup | `AnalogInput` | `turret_analog`; voltage 0–3.3 V, archive shaft offset 125° |
| Hood | positional `Servo` | `hood_left`, `hood_right`; one hood angle, complementary positions, left inversion |
| Odometry | `GoBildaPinpointDriver` | `pinpoint`; measured pod-axis offsets 161 mm and 0 mm, directions FORWARD/REVERSED, `goBILDA_4_BAR_POD` |
| Declared but unsensed in B | distance sensor | `intake_dist`; inventory remains unsensed |
| Archive vision, later seam | `Limelight3A` | `limelight`; active in the archive but optional there, owned by Vision-A rather than B |

The archive evidence for paired construction and writes is recorded in
`hardware-profile-v0.md`. In particular, `shooterLeft` is both an active shooter
output and the turret encoder input; it is not an encoder-only device.

## Units and representations

| Value | Representation |
|---|---|
| Simulation time | integer `t_ms`, `dt_ms`; `IHal.now()` is milliseconds |
| Pose and chassis geometry | inches; heading/angles at core seams are radians |
| Pinpoint offsets | millimetres (`xPodOffsetMm=161`, `yPodOffsetMm=0` by measured pod axis) |
| Motor encoder | integer ticks; `RobotState.vel` is ticks/second |
| Motor/CR power | finite double in `[-1, 1]`; zero is stop |
| Positional-servo command | finite double in `[0, 1]`; omitted means hold only in proto2 |
| Battery voltage | finite volts |
| Robot mass | finite positive kilograms; `ROBOT_MASS_KG` is parsed from Java source |
| Motor roller angle | degrees in the machine-readable Java line, converted to radians by Python |

No unit conversion or axis renaming is hidden in the adapter. The Pinpoint SDK call
keeps the documented `(161, 0, MM)` argument order; the unused archive `-84/-168`
configuration is not substituted.

## Ownership and validation

- `RobotConstants.java` owns compile-time defaults. Its current machine-readable
  forms are scalar doubles, strings, `Motor(...)` records, `MOTORS`, `SERVOS`, and
  `PINPOINT` (`RobotConstants.java:16-76,133-139`). B01 adds named device/profile
  declarations one per line; it does not introduce YAML or arbitrary Java parsing.
- `sim/mechanism.py` owns the Python source reader and must reject a missing file,
  missing required scalar, non-numeric value, duplicate name, invalid range, or
  unsupported expression before constructing a plant (`sim/mechanism.py:20-31,112-211`).
- `RealHal`/`Hardware` and `SimHal` bind each declared name once. A handshake name or
  protocol mismatch fails before outputs are enabled. `RobotAction` validation runs
  inside both HAL write paths before the final device/network clamp; clamping remains
  defense in depth.
- One owner writes each actuator pair. Shooter owns both shooter motors; turret owns
  both CR outputs and reads, but never configures or powers, the shared `shooterLeft`
  motor; the hood controller emits both complementary positions in one action.
- Central initialization resets/configures each required encoder once before enable.
  This is a **new fix**, not an archive behavior: the archived turret constructor
  resets `shooterLeft` after shooter setup and the feeder also resets its encoder
  (`hardware-profile-v0.md`, archive citations). The ADR does not claim this fix is
  implemented.

## A02 mass-source rule

A02 adds `ROBOT_MASS_KG` to the binding scalar/source list and extends the reader's
`PhysicsConfig`/body construction. The reader must match the machine-readable line

```java
public static final double ROBOT_MASS_KG = 12.0;
```

and interpret the value in **kg**. Missing, malformed, non-finite, or non-positive
values fail with a clear `MechanismError`; the reader must not silently use 12 kg or
the archive's 13.8 kg. The isolated fixture copies `RobotConstants.java` to a
temporary file, changes only the literal to `18.0`, loads it, and asserts the body
mass and derived inertia use 18 kg. A companion missing/invalid fixture asserts a
failure before a body is created. These are planned checks, not completed outcomes.

## Paired seam fixtures

The paired fixtures are small and deterministic; each is run through the same Java
core and Python adapter where applicable.

1. **Proto1 compatibility:** full motor/servo maps, omitted key → zero, `ready.proto=1`;
   preserve the existing golden JSON lines.
2. **Proto2 sparse servo:** omit one hood position and assert it holds its previous
   explicit position; omit both before any setpoint and assert no guessed move; omit
   a DC/CR command and assert zero power.
3. **Paired outputs:** shooter emits right `p` and left `p*followerScale`; hood emits
   complementary `(left,right)` from one angle; turret emits equal CR powers and
   zeros both on STOP/cancel. Partial pair commands reject before a write.
4. **Shared-port isolation:** spin the shooter while aiming the turret; `shooterRight`
   velocity remains the shooter source, `shooterLeft` encoder follows turret angle,
   and neither owner writes the other's output.
5. **Mass source:** use the isolated 18 kg Java fixture plus missing/invalid variants;
   compare parsed body mass/inertia and retain the source-file hash in the evidence.
6. **Pinpoint profile:** assert 161/0 mm, FORWARD/REVERSED, pod type and SDK argument
   order; do not substitute -84/-168.

Fixture names and test paths are proposals for A02/B01 and may be refined by the
approved task file. They are not evidence that any fixture has run.

## Migration boundary and approval gate

1. This draft is reviewed without touching `protokol.md` or
   `phases/phase-1.1/design-spec.md`.
2. `ftc-main` updates the protected protocol with the proto2 version, scalar mass
   provenance, name/type lists, sparse-servo rule, and paired golden frames. The
   amendment records compatibility and rejection behavior.
3. Only after that approval may R and S implement the paired adapter/parser change;
   both retain proto1 regression fixtures until the migration gate is accepted.
4. Proto2 clients reject proto1 peers and vice versa when the required semantics do
   not match. The old proto1 path is not silently reinterpreted.
5. A02's 18 kg parser/body proof and B01's device/handshake proofs are prerequisites
   for later mechanism work. No code, tag, release, or hardware claim follows from
   this documentation draft alone.
