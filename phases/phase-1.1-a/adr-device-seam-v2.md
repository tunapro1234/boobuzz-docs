# ADR A02/B01 — device and protocol seam v2

Status: **A02 unblocked at protected protocol pin `26f915b`; B01 blocked pending
the protected pin of this ADR's record signatures. Documentation only.** This ADR
does not itself amend `protokol.md`, change code, or authorize an implementation.
The binding amendment was published by `ftc-main` in commit `26f915b`; B01's
signature pin and all implementation evidence remain separate gates. Source pins
for this record are robot-code `d5bda62`, re-cock-nize `5dd6daa`, and archive
`d7711d0`.

## Context and decision

The current wire contract is proto1. Java sends line-delimited JSON `reset`, `step`
and `bye`; Python returns `ready` and `state`. `RobotAction` has exactly two value
maps—`motors` and `servos`—plus the `events` list; there is no third actuator map
(`robot-code/TeamCode/core/src/main/java/boobuzz/core/contract/RobotAction.java:14-18,44-50`).
`SimHal.fill` currently sends every declared motor and servo name, filling an omitted
value with `0.0` (`robot-code/sim/src/main/java/boobuzz/sim/SimHal.java:171-207`).
`RealHal` also writes every declared name each tick
(`robot-code/TeamCode/src/main/java/org/firstinspires/ftc/teamcode/hal/RealHal.java:63-71`).

Adopt the versioned proto2 seam defined by the protected amendment; implementation
remains blocked for B01 until this ADR's exact record signatures are pinned:

1. `reset.proto` is optional: absent means proto1 (`1`). `ready.proto` advertises
   the peer's version. A requested proto2 session requires matching values; any
   mismatch fails before either side enables or emits output.
2. The command has exactly two maps. `motors` contains all power devices—DC motors
   and CR servos—with finite `[-1,1]` power; omitted entries mean zero. `servos`
   contains positional servos only, with finite `[0,1]` positions; omitted entries
   mean hold in proto2. CR servos never get a third map.
3. A never-commanded positional servo uses its declared initial position from the
   RobotConstants profile, not a guessed position. An explicit stow/neutral command
   is a command, not STOP. `reset` clears the saved positional-servo holds.
4. A proto1 peer continues to receive full motor and servo maps with zero-fill for
   omitted keys. Proto2 `SimHal` omits absent positional-servo keys and retains the
   last explicit target; proto2 `RealHal` does not call `setPosition` for an absent
   key. Both still write DC/CR omission as zero power. No silent proto1 fallback is
   permitted for a proto2 mechanism profile.
5. `ROBOT_MASS_KG` remains a Java-source configuration value consumed by the Python
   parser; it is not smuggled through a new runtime wire field. The binding
   scalar/source rule is now recorded in the protected amendment `26f915b`; this
   ADR does not claim that the A02 parser or fixture has been implemented.

The choice keeps an explicit safety distinction: power devices stop at zero, while a
position servo does not jump to zero merely because an action omitted it. Java
validates both `ready.motors` (DC+CR) and `ready.servos` (positional) against
RobotConstants before output; a mismatch fails pre-output.

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

## Proposed B01 `RobotConstants` records and semantic lists

These are the exact nested record signatures to pin before B01 code. The numeric
fields keep the protocol's machine-readable line format; no new calibration values
are asserted here.

```java
public record Motor(String name, String drives, double xForward, double yLeft,
                    double rollerDeg, double ticksPerRev, double freeRpm) {}
public record Pinpoint(double xPodOffsetMm, double yPodOffsetMm,
                       String xPodDirection, String yPodDirection, String podType) {}
```

The B01 semantic lists are fixed as follows (names are planned archive-compatible
declarations, not a claim that the current four-wheel profile already binds them):

| RobotConstants list | Exact semantic contents |
|---|---|
| `MOTORS` | DC motor records: `leftFront`, `rightFront`, `leftBack`, `rightBack`, `intake`, `feeder`, `shooterRight`, `shooterLeft` |
| `CR_SERVOS` | CR power devices: `turret_servo`, `turret_servo2` |
| `SERVOS` | positional devices: `hood_left`, `hood_right` |
| `ENCODERS` | motor-port inputs, each once: `leftFront`, `rightFront`, `leftBack`, `rightBack`, `intake`, `feeder`, `shooterRight`, `shooterLeft` |
| `PINPOINT` | one `Pinpoint(161.0, 0.0, "FORWARD", "REVERSED", "goBILDA_4_BAR_POD")` record |

The corresponding one-line array declarations are the B01 machine-readable shape:

```java
public static final String[] CR_SERVOS = {"turret_servo", "turret_servo2"};
public static final String[] SERVOS = {"hood_left", "hood_right"};
public static final String[] ENCODERS = {
    "leftFront", "rightFront", "leftBack", "rightBack",
    "intake", "feeder", "shooterRight", "shooterLeft"
};
```

`ready.motors` is the ordered name union of `MOTORS` and `CR_SERVOS`; `ready.servos`
is exactly `SERVOS`. `state.enc` uses `ENCODERS`; it is not a third `RobotAction`
map or a third ready actuator list. FTC runtime types (`DcMotorEx`, `CRServo`,
`Servo`, `AnalogInput`, and `GoBildaPinpointDriver`) are selected from these
RobotConstants declarations and role lists, not inferred from wire-map names.

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

## Binding paired seam fixtures (1–6)

Fixtures 1–6 are binding for A02/B01. They are small and deterministic; each runs
through the same Java core and Python adapter where applicable. This section records
the contract, not completed outcomes.

1. **Proto1 compatibility:** `reset.proto` absent means `1`; full `motors` and
   `servos` maps are sent and omitted keys zero-fill; `ready.proto=1`; preserve the
   existing golden JSON lines.
2. **Proto2 sparse servo:** matching `reset.proto=2`/`ready.proto=2`; omit one hood
   position and assert it holds its previous explicit position; omit before any
   setpoint and assert the declared initial position is used; reset clears holds;
   omit a DC/CR command and assert zero power.
3. **Paired outputs and validation:** shooter emits right `p` and left
   `p*followerScale`; hood emits complementary `(left,right)` from one angle; turret
   emits equal CR powers and zeros both on STOP/cancel. `ActionValidator` rejects any
   half-pair before a device/network write.
4. **Shared-port isolation:** spin the shooter while aiming the turret;
   `shooterRight` velocity remains the shooter source, `shooterLeft` encoder follows
   turret angle, and neither owner writes the other's output.
5. **Mass source:** use the isolated 18 kg Java fixture plus missing/invalid variants;
   compare parsed body mass/inertia and retain the source-file hash in the evidence.
6. **Pinpoint profile:** assert 161/0 mm, FORWARD/REVERSED, pod type and SDK argument
   order; do not substitute -84/-168.

Evidence files must record the exact R/S hashes and outcome for each fixture; until
then no fixture result is implied.

## Migration boundary and approval gate

1. This draft is reviewed without touching `protokol.md` or
   `phases/phase-1.1/design-spec.md`.
2. `ftc-main` has published the protected protocol amendment at `26f915b`, covering
   the proto2 version, scalar mass provenance, sparse-servo rule, and paired-device
   behavior. A02 is unblocked at this pin. This ADR now records the exact B01
   record signatures and semantic lists; B01 remains blocked until ftc-main pins
   this ADR hash in the protected protocol.
3. Any R/S adapter or parser implementation is a separately authorized change. Both
   sides retain proto1 regression fixtures until the migration gate is accepted;
   this ADR records no implementation outcome.
4. Proto2 clients reject proto1 peers and vice versa when the required semantics do
   not match. The old proto1 path is not silently reinterpreted.
5. A02's 18 kg parser/body proof and B01's device/handshake proofs are prerequisites
   for later mechanism work. No code, tag, release, or hardware claim follows from
   this documentation record alone.
