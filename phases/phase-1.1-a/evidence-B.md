# Chapter B evidence ledger

**Status:** B is approved and eligible at the verified Chapter-A checkpoint. This
file is the sole Chapter-B evidence ledger. It is an entry scaffold for B01: no
B01 implementation, test, acceptance, or hardware outcome is claimed below.

## Authoritative entry pins and gates

| Entry | Immutable pin | What it establishes |
|---|---|---|
| D / A05 | `cec382d6380ceb209700fe3abef19684556fb51a` | Chapter-A baseline manifest; annotated `p11a-baseline-v1` resolves to this commit locally and remotely |
| Protected protocol | `74475463add0f23afd6d84b801245650712bbb62` | B01 `DcDevice`, `CrServo`, and `PosServo` declaration-record gate |
| R (`robot-code`) | `72d3ac9fa81209f5bf31fd88eb1b99927bfdcaee` | B01 Java/FTC entry source (`dev-phase-1.1-a` and origin agree) |
| S (`re-cock-nize`) | `4cc1201f6ba4861815f37625cc03ea973a84755f` | B01 Python/simulator entry source (`dev-phase-1.1-a` and origin agree) |
| A01 S lineage | `5ba0a9671eeedc84f2a628ff970133c1e86f656f` | Prior transport/event barrier accepted in the A05 manifest |
| A02 R/S lineage | R `97995cafe65db9114dd1bdde9a251cdb9aa1bd47`; S `5849e58fc74e7e294bf61a48d1ca7a2cdcf98b03` | Mass seam and cancellation/deadband review lineage; final S entry is the pin above |
| A04 archive | `d7711d043280034ab5c75ae26a253629fd2d4a7b` | Archive-derived preserve/correct/defer provenance only |

At entry, R's worktree is clean and S has only the preserved untracked `.claude/`
directory; each remote ref resolves to the pin shown. The protocol gate is the
protected amendment above. A05's accepted gates were: R
`JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew :core:test :sim:test :sim:installDist`
(`BUILD SUCCESSFUL`, 127 core + 11 sim, zero failures/errors/skips); S focused
acceptance (`2 passed, 0 skipped`) and full suite (`93 passed, 0 skipped`); and the
R runner exit `0` with six 1000-tick A-drive plus two 101-tick A-cancel traces,
including schema/status/switch/zero-output, seed-repeat determinism, cleanup and
30-second timeout-bound gates. The non-binding Android assemble OOM is retained as
an environment limitation in the A05 ledger. These A05 results are entry gates,
not B01 results.

The protected B01 record signatures are exactly:

```java
record DcDevice(String name, String direction, String zeroPower,
                double ticksPerRev, double freeRpm)
record CrServo(String name, String direction)
record PosServo(String name, String direction, double initialPos)
```

`ready.motors` is the ordered DC+CR power list; `ready.servos` is the positional
list. `RobotAction` has exactly `motors`, `servos`, and diagnostic `events`. Proto2
requires matching `reset.proto`/`ready.proto` and fails before output on mismatch;
proto1 retains full-map zero-fill. In proto2, omitted DC/CR is zero while omitted
positional servo is hold (declared initial position before its first command), and
reset clears saved holds.

### B01 source slots

The planned R reads/binds `TeamCode/core/src/main/java/boobuzz/core/hal/{RobotConstants,Mechanism,IHal}.java`, `TeamCode/core/src/main/java/boobuzz/core/contract/{RobotAction,RobotState}.java`, `TeamCode/src/main/java/org/firstinspires/ftc/teamcode/hal/{Hardware,RealHal}.java`, and `sim/src/main/java/boobuzz/sim/{SimHal,Json}.java`. The planned S counterparts are `sim/{mechanism,server}.py` and `sim/physics/{motor,pymunk_backend,multi}.py`; paired protocol fixtures are under `R/sim/src/test/resources/protocol-v2/` and `S/tests/fixtures/protocol-v2/`. These are task slots, not evidence that the planned declarations or files have already changed.

## B01 task slots (planned; no outcomes)

| Slot | R owner / S owner | Required seam evidence | State at this scaffold |
|---|---|---|---|
| B01.0 protocol migration | `RobotAction`, `ActionValidator`, `SimHal`/`RealHal` and protocol fixtures / `sim/server.py`, validation and fixture parity | Matching proto2 reset/ready; exact two maps; DC/CR zero versus positional-servo hold; proto1 full-map compatibility; pre-output name/type validation | Protocol pin satisfied; implementation and tests not run or accepted here |
| B01.1 constants and parser | `RobotConstants`, `Mechanism`, hardware-profile tests / `sim/mechanism.py` parser and mechanism tests | Archive names/order, FTC-role lists, directions, zero-power modes, encoder roles, Pinpoint profile, constants hash, unknown-identifier and malformed-source failures | Planned seam; no implementation or outcome recorded |
| B01.2 adapter writes and shared ports | `Hardware`, `RealHal`, `ActionValidator`, focused Java/TeamCode tests / `SimHal`, server and protocol/multi-robot tests | Eight DC outputs, two CR outputs, two positional outputs; pair validation; sparse servo hold; central reset once; shooter/turret shared-port isolation; Pinpoint and zero-power setup | Planned seam; no implementation or outcome recorded |

R and S must keep the same declared names and wire semantics. D records only
source-grounded evidence and routes any protocol change to the protected owner;
this scaffold does not authorize code or protocol edits.

## Required protocol fixtures (1–6)

These are the binding fixtures named by the ADR. Each row is a required assertion,
not a completed result.

| # | Required assertion | Fixture locations |
|---|---|---|
| 1 | Proto1: absent `reset.proto` means `1`; full motor/servo maps and zero-fill; `ready.proto=1` | `R/sim/src/test/resources/protocol-v2/{ready,step-hold,step-explicit-zero,state}.json`; paired S fixture directory |
| 2 | Proto2 matching reset/ready; omitted positional servo holds (including declared initial position before first command); reset clears holds; omitted DC/CR is zero | Same paired fixture sets |
| 3 | Shooter paired output, complementary hood pair, equal turret CR pair; `ActionValidator` rejects every half-pair before a write | Same paired fixture sets plus validator tests |
| 4 | `shooterRight` remains the shooter speed input while `shooterLeft` is the turret input and active shooter output; no cross-owner reconfiguration | Shared-port Java/Python fixtures and tests |
| 5 | `ROBOT_MASS_KG` Java-source parser uses kg; isolated `18.0` fixture changes mass/inertia; missing/invalid source fails before body creation | A02 mass fixture and parser tests |
| 6 | Pinpoint `161.0/0.0` mm, `FORWARD/REVERSED`, `goBILDA_4_BAR_POD`, and SDK argument order | Hardware/profile fixture and adapter tests |

Proto2 `ready.motors` is the exact DC+CR power-device list and `ready.servos` is
the positional list. `RobotAction` has only `motors`, `servos`, and diagnostic
events; a reset/ready mismatch fails before output. Positional omission holds (or
uses the declared initial position when never commanded); DC/CR omission is zero.

## Required tests and commands (not run for this scaffold)

| Side | Required checks from the approved B01 spec |
|---|---|
| R core/sim | `SimHalTest.rejectsProto1ForMechanismProfile`; `SimHalTest.omittedServoIsNotZeroFilled`; `RobotActionServoHoldTest`; `ActionValidatorTest`; `MechanismTest`; `HardwareProfileTest` including shared-port, zero-power, reset-once and Pinpoint assertions |
| R FTC | `RealHalWriteTest` for pair writes, sparse hold, directions, zero-power behavior, shared-port isolation and central encoder reset; `:TeamCode:assembleDebug` when HAL/profile code changes |
| S parser/protocol | `test_protocol_validation.py::test_servo_omitted_holds`; `::test_servo_explicit_zero_moves`; mechanism name/list/unknown-identifier/constants-hash tests |
| S adapter/plant | `test_multi_robot.py` plus shared-port encoder-role and zero-power semantics; the paired protocol-v2 fixtures must remain byte-comparable |
| Commands | R: `./gradlew :core:test :sim:test :sim:installDist` (and the HAL/profile Android build); S: `python -m unittest discover -s tests` in its project venv; then the B01 all-device fixture and A-drive/A-cancel trace |

Every B01 seam increment requires an R↔S seam-only cross-review after the worker
reports. The review artifact, exact source pins, commands, and results are a
later evidence slot; no reviewer has been launched and no review outcome is
implied by this file.

## Limitations and publication boundary

- This commit publishes documentation only. No B01 worker has supplied a result,
  so no fixture, test, acceptance trace, physical direction, or hardware claim is
  marked passed.
- A05 host tests and runner traces establish the entry baseline; they do not prove
  B01 device declarations, sparse-servo behavior, paired writes, or shared-port
  ownership.
- No physical Control Hub, Pinpoint, motor/servo bus, mechanism, or cadence
  validation is available. A03 was host-Pymunk evidence only; the A05 Android
  assemble OOM remains an environment limitation, not a B01 product result.
- No protocol/spec/source file, tag, reviewer, ftc-ball activity, training, or
  phase transition is included. Later append-only updates must independently
  verify each R/S commit, remote ref, worktree exception, command exit and exact
  outcome before recording it.
