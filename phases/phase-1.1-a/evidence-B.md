# Chapter B evidence ledger

**Status:** B is approved and eligible at the verified Chapter-A checkpoint. This
file is the sole Chapter-B evidence ledger. The entry scaffold and the R/S
completion evidence below are append-only. The latest bounded bidirectional R↔S
seam rerun is **PASS** after one scoped R fix at `18b1d629`; the historical FAIL
record remains below for audit. No physical-hardware or B02+ plant result is
claimed by this ledger.

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

## B01 task slots (entry plan)

This table is the original entry plan. The R/S result sections below supersede its
no-outcome wording; the bounded bidirectional cross-review remains open.

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

## Required tests and commands

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

## B01 R completion evidence (seam-review pin; S pending)

The final R seam-review pin is `bffd71b331a7c1dfc67abe30f16df7df92165cc5`.
It is a clean pushed descendant of the worker's earlier completion pin
`e234a8e5c075832ec6c28dbe56b62b372c235e91`; the increment paths and reported
scope were independently checked:

| Increment | Changed paths | Reported seam contribution |
|---|---|---|
| `aedc96c45e0050330982acad88602932341bb597` | `TeamCode/core/src/main/java/boobuzz/core/hal/{Mechanism,RobotConstants}.java`; `TeamCode/core/src/test/java/boobuzz/core/hal/MechanismTest.java` | Typed profile declarations and mechanism lists |
| `e33b9882226ee8b70099be84276a7be84e422e1a` | `TeamCode/core/src/main/java/boobuzz/core/contract/ActionValidator.java`; its `ActionValidatorTest.java` | Whole-frame and paired-output validation |
| `0936f3980fe7ea10a213e5bdadcb9098308ec102` | `sim/src/main/java/boobuzz/sim/{Json,SimHal}.java`; `AcceptanceMainTest.java`; `FakeSimServer.java`; `SimHalTest.java`; four `sim/src/test/resources/protocol-v2/*.json` fixtures | Proto1/proto2 negotiation, exact lists, sparse positional hold and paired fixtures |
| `6c852c7c1ef0b949533f73b12c797054fce6b16e` | `TeamCode/src/main/java/org/firstinspires/ftc/teamcode/hal/{Hardware,RealHal}.java` | Single-owner binding, directions, zero-power, reset-once and Pinpoint |
| `637f22579d85d30ed10fdce2e10943d1943d7858` | `TeamCode/core/src/test/java/boobuzz/core/contract/RobotActionServoHoldTest.java`; `sim/src/main/java/boobuzz/sim/Json.java`; `sim/src/test/java/boobuzz/sim/JsonValidationTest.java` | Malformed JSON fail-closed and sparse two-map tests |
| `e234a8e5c075832ec6c28dbe56b62b372c235e91` | `sim/src/test/java/boobuzz/sim/SimHalTest.java` | Legacy proto1 full-map zero-fill regression |
| `bffd71b331a7c1dfc67abe30f16df7df92165cc5` | `TeamCode/core/src/test/java/boobuzz/core/hal/HardwareProfileTest.java` | Final typed hardware-role, output-order, shared-port and initial-position assertions |

The final R verification reported this command as successful at `bffd71b`:

```text
JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew :core:test :sim:test :sim:installDist :TeamCode:assembleDebug
```

Reported final totals are **137 core tests + 17 sim tests, all passed with zero
skips/failures/errors**; installDist, Android `assembleDebug`, and the Pymunk
replay (`seededRecordAndReplayAreBitEqual`) are green. The earlier e234 run was
reported as 134 core + 17 sim; the three additional core tests are the
`HardwareProfileTest` commit above. Independently, the exact Gradle command and
`JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew :sim:test --rerun-tasks` both
exited `0`, and current XML totals are 137/17 with no skipped/failure/error cases.
R's current worktree is clean and local/remote refs agree at the final bffd pin.

The worker reports the SDK module cannot provide Android `HardwareMap` fake-device
write tests; production binding compilation plus core/sim seam tests cover the
contract. No physical hardware result is claimed. B01 remains pending bounded,
bidirectional R↔S seam reviews; no B01 acceptance is declared by the R-only entry.

## B01 S completion evidence (bidirectional seam review pending)

The S worker supplied clean pushed pin
`0ca3175b81fa499e8c169bbc005713aa4d63e3b2`; S local and origin refs agree, with
only the preserved untracked `.claude/` directory. Independently verified changed
paths are `sim/mechanism.py`, `sim/physics/{backend,kinematic_backend,motor,multi,pybullet_backend,pymunk_backend}.py`, `sim/server.py`, `tests/common.py`, `tests/fixtures/protocol-v1/RobotConstants.java`, `tests/fixtures/protocol-v2/{ready,state,step-explicit-zero,step-hold}.json`, the B01-related `tests/test_*.py` modules (calibrated physics, determinism, events, gamepad, kinematics, mechanism, multi-robot, process-network, protocol validation, Pymunk, server timeout and signal), and `tools/fake_client.py`. This is simulator state/contract coverage, not a claim of physical-HAL behavior.

Independently verified commands (using S's repository-local absolute paths) were:

```text
PYTHONPATH="/home/shared/projects/boobuzz/re-cock-nize/tests" "/home/shared/projects/boobuzz/re-cock-nize/.venv/bin/python" -m unittest test_mechanism test_protocol_validation test_multi_robot test_process_network test_pymunk_backend
PYTHON="/home/shared/projects/boobuzz/re-cock-nize/.venv/bin/python" ./run_tests.sh
```

The focused command ran **48 tests, OK**. The full command ran **106 tests, OK**;
no skipped/failure/error cases were reported. Coverage reported by the worker and observed
in the run includes typed `DcDevice`/`CrServo`/`PosServo` parsing, identifier and
literal rejection, constants hash and encoder roles, proto negotiation and exact
lists, two maps, sparse positional hold/reset, DC+CR zero-fill, all backends and
multi-robot forwarding, the shared `shooterLeft` turret encoder role, proto1
fixtures/zero-fill, and deterministic process behavior.

S models declared actuator state and metadata only; no B02+ plant or real-HAL
validation is claimed. B01 therefore remains unaccepted until bounded
bidirectional R↔S seam reviews are completed and their pins/results are recorded.

## B01 S→R seam cross-review — FAIL (bounded)

The bounded read-only review pins are S
`0ca3175b81fa499e8c169bbc005713aa4d63e3b2`, R
`bffd71b331a7c1dfc67abe30f16df7df92165cc5`, and protected protocol D
`74475463add0f23afd6d84b801245650712bbb62`. S and R refs matched those pins at
review; S retained only its pre-existing untracked `.claude/` directory and R was
clean. Overall review result: **FAIL**, with all listed wire/forwarding checks
passing except the R-owned `constantsHash` requirement.

### Paired protocol-v2 fixtures

Each `cmp -s` comparison between `S/tests/fixtures/protocol-v2/` and
`R/sim/src/test/resources/protocol-v2/` passed. The independently checked SHA-256
pairs are:

| Fixture | S and R SHA-256 |
|---|---|
| `ready.json` | `27a14aac3b1c1666998fca315db940c00dd95aa9968394788b2a4f36d11e92e1` |
| `state.json` | `308850533f16d16fad014ab1e1409167ad26823ec272c0495e68f281090cd009` |
| `step-hold.json` | `fcc17e3b10760ab0bc880808bb00ff3fbae704abf434d8d9447d46547e80cdab` |
| `step-explicit-zero.json` | `6253f2782c11875d2142adc79c4e2988820258d042bc7f26db8d648ff1ef5fb3` |

### Review findings

| Seam | Review result and source anchors |
|---|---|
| Reset/ready negotiation and exact order | **PASS** — S `sim/server.py:130-141,976-999`; R `sim/src/main/java/boobuzz/sim/SimHal.java:109-136`, `TeamCode/core/src/main/java/boobuzz/core/hal/Mechanism.java:116-129`; real profile returned proto2, `t_ms=0`, motors `[fl,fr,bl,br,intake,feeder,shooterRight,shooterLeft,turret_servo,turret_servo2]`, servos `[hood_left,hood_right]`. |
| Exactly two actuator maps | **PASS** — S `sim/server.py:207-211,1012-1028`; R `SimHal.java:195-208`; extra keys reject and only `motors`/`servos` plus events are forwarded. |
| Proto1 compatibility | **PASS** — S `sim/server.py:130-141,904-913`; R `SimHal.java:132-135`; absent proto selects1 and legacy partial maps zero-fill. |
| DC/CR zero-fill | **PASS** — S `sim/server.py:202-204,1020-1028`, `sim/physics/motor.py:184-198`; R `SimHal.java:195-207,224-232`; all ten power names and missing-power zero behavior matched. |
| Positional hold/reset | **PASS** — S `sim/server.py:900-913,976-999`, backend apply paths; R `RealHal.java:88-99`; sparse hood hold, reset to `{hood_left:1.0,hood_right:0.0}`, and explicit zero matched. |
| Shared `shooterLeft` roles | **PASS** — S `sim/mechanism.py:623-639,668-681`, `sim/physics/motor.py:245-262`; R `RobotConstants.java:74-81,103`, `Hardware.java:58-69`; shooterRight remains speed input and shooterLeft turret input/active output. |
| Backend and multi-robot forwarding | **PASS** — S `kinematic_backend.py:54-112`, `pymunk_backend.py:174-206`, `pybullet_backend.py:346-371`, `multi.py:64-95`; single/two-robot sparse and hold isolation matched. |
| `constantsHash` includes mass | **FAIL — MAJOR, R-owned** — B01 requires mass and typed declarations in spec `02-intake-feeder.md:107`; R `RobotConstants.java:113-145` hashes typed records/encoders/Pinpoint but omits `ROBOT_MASS_KG` at `:18`. A mass-only change therefore leaves the Java hash unchanged, while S `sim/mechanism.py:289-314,720-722` includes mass. |

The review's read-only JShell probes reported Java hash
`ae3d986cc522b6ed848527eda939c8330eaa7cfbcb00a31633065c2a7b9c7064` and S hash
`79eecdb8989b72526988a23851395c194f88e207b8d2d2b369c22ebd6c641745`. These
algorithms are separately canonicalized and `constantsHash` is not on the wire;
cross-language equality is not asserted. The defect is specifically the missing
Java mass contribution, not a required cross-language hash match.

### Review commands and limits

- S focused command: **48 tests, OK**; full `run_tests.sh`: **106 tests, OK**;
  no skipped/failure/error cases were reported (also recorded above).
- R `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew -q :core:test :sim:test`
  exited `0`; XML reports were **137 core + 17 sim**, zero failures/errors/skips.
- No files were edited by the review; no simulator commit/tag, B02 work, or
  protocol change was made. Java tests use `FakeSimServer`, not a live Python
  process. B01 metadata/adapter checks do not prove B02+ physical decay or a real
  HAL/Control Hub. The required remediation is to include `ROBOT_MASS_KG` in the
  R hash and add a mass-change regression, followed by a fresh R/S review; this
  ledger records the recommendation only and dispatches no source change.

## Limitations and publication boundary

- This increment publishes documentation only. The R and S worker results are
  recorded above; the bounded bidirectional R↔S seam rerun is now marked passed,
  including fixture parity, but no physical direction or hardware claim is made.
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

## B01 bounded R↔S seam rerun — PASS after scoped R fix

This final, read-only rerun supersedes the earlier pending/FAIL status for the
current B01 seam gate; that earlier section is retained as historical evidence.
The verified pins were:

| Side | Pin and worktree evidence |
|---|---|
| R (`robot-code`) | `18b1d629fa21869963b9cd678e285c770f37c9d4`, HEAD/origin `dev-phase-1.1-a`, clean; descendant of `b72da4a` and `bffd71b` |
| S (`re-cock-nize`) | `0ca3175b81fa499e8c169bbc005713aa4d63e3b2`, HEAD/origin `dev-phase-1.1-a`; only preserved untracked `.claude/` |
| D protocol | `74475463add0f23afd6d84b801245650712bbb62` |

### Closed R mass-hash finding

R `RobotConstants.constantsHash()` now delegates to
`constantsHashForMass(ROBOT_MASS_KG)` (`RobotConstants.java:113-116`). The mass is
included at `:120-123`, wheel efficiencies at `:124-129`, and typed
`Motor`/`DcDevice`/`CrServo`/`PosServo` arrays, `ENCODERS`, and `PINPOINT` at
`:130-144`. `RobotConstantsHashTest.java:10-15` asserts that changing only mass
from 12.0 kg to 18.0 kg changes the digest. The independently repeated
reflection probe returned:

```text
mass12=b189515a90da49e2e98a63de90daf23912f8d17e80bd937800ced3f4fba1555d
mass18=f5b1af72d2d0cabdf07c3ba5a93f062abde442d52731baeccbde88bfcfb99c51
diff=true
```

This closes the prior R-owned mass omission; the b72da4a wheel-efficiency fix
is also present. No cross-language digest-string equality is required: the
canonical algorithms differ and `constantsHash` is not a wire field.

### Paired protocol-v2 fixtures

All four `cmp -s` checks between `S/tests/fixtures/protocol-v2/` and
`R/sim/src/test/resources/protocol-v2/` passed. The equal SHA-256 pairs are:

| Fixture | S and R SHA-256 |
|---|---|
| `ready.json` | `27a14aac3b1c1666998fca315db940c00dd95aa9968394788b2a4f36d11e92e1` |
| `state.json` | `308850533f16d16fad014ab1e1409167ad26823ec272c0495e68f281090cd009` |
| `step-hold.json` | `fcc17e3b10760ab0bc880808bb00ff3fbae704abf434d8d9447d46547e80cdab` |
| `step-explicit-zero.json` | `6253f2782c11875d2142adc79c4e2988820258d042bc7f26db8d648ff1ef5fb3` |

### Seam results

The following checks were PASS in the bounded rerun; source anchors are included
so the result can be audited against the pinned R/S trees.

| Seam | Result and source anchors |
|---|---|
| Reset/ready negotiation and exact order | **PASS** — S `sim/server.py:130-141,976-999`; R `SimHal.java:109-149`, `Mechanism.java:116-130`, `RobotConstants.java:92-106`; proto2 ready carried the ten power names, two positional names, and `t_ms=0`. |
| Exactly two actuator maps | **PASS** — S `sim/server.py:207-211,1012-1028`; R `SimHal.java:192-200`; extra maps reject and only `motors`/`servos` plus events are forwarded. |
| Proto1 compatibility | **PASS** — S `sim/server.py:130-141,904-913`; R `SimHal.java:132-135`; absent-proto legacy reset/partial step produced proto1 and full motor/servo zero-fill. |
| DC/CR zero-fill | **PASS** — S `sim/server.py:202-204,1020-1028`, `sim/physics/motor.py:184-198`; R `SimHal.java:195-231`; missing DC/CR keys became zero and CR stayed in `motors`. |
| Positional hold/reset | **PASS** — S `sim/server.py:900-913,976-999`, `kinematic_backend.py:54-58`, `pymunk_backend.py:174-180`, `pybullet_backend.py:346-352`; R `RealHal.java:88-99`; sparse `hood_left=.25` held, reset restored `{hood_left:1.0,hood_right:0.0}`, and explicit zero remained a command. |
| Shared shooter/turret port roles | **PASS** — S `sim/mechanism.py:623-639,668-681`, `sim/physics/motor.py:245-262`; R `RobotConstants.java:74-81,103`, `Hardware.java:58-69`; `shooterRight` is feedback input, `shooterLeft` is turret input/active output, with no duplicate source. |
| All backends and multi-robot forwarding | **PASS** — S `kinematic_backend.py:54-112`, `pymunk_backend.py:174-206`, `pybullet_backend.py:346-371`, `multi.py:64-95`; single/two-robot kinematic, Pymunk, and PyBullet checks passed for zero-fill, sparse forwarding, and hold isolation. |

### Commands, outcomes, and limits

- R: `cd ../robot-code && JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew -q :core:test :sim:test` exited 0; independently observed **138 core + 17 sim tests**, zero failures/errors/skips, including `RobotConstantsHashTest`.
- S focused: `PYTHONPATH="/home/shared/projects/boobuzz/re-cock-nize/tests" "/home/shared/projects/boobuzz/re-cock-nize/.venv/bin/python" -m unittest test_mechanism test_protocol_validation test_multi_robot test_process_network test_pymunk_backend` — **48 tests, OK**.
- S full: `PYTHON="/home/shared/projects/boobuzz/re-cock-nize/.venv/bin/python" ./run_tests.sh` — **106 tests, OK**; no skipped/failure/error cases.
- The bounded Python seam script reported PASS for parser/profile, v2/v1 server, two-map rejection, zero-fill, hold/reset, shared-port isolation, all three backends, and all three two-robot worlds.
- Java hash probes returned the mass-sensitive values above. R/S use different canonical hash algorithms and no digest is sent on the wire.
- Java tests use `FakeSimServer`, not a live Python process. FLOAT/BRAKE metadata is validated at this B01 seam only, not later B02+ physical decay. No physical robot, Control Hub, or real-HAL result is claimed; no source/protocol files were edited by the review.

## B01 bounded R→S seam rerun — PASS (read-only)

This reverse-direction rerun confirms the PASS closure above without changing
either implementation repository. R `18b1d629fa21869963b9cd678e285c770f37c9d4`
and S `0ca3175b81fa499e8c169bbc005713aa4d63e3b2` are the verified
HEAD/origin `dev-phase-1.1-a` pins; R is clean and S retains only its preserved
untracked `.claude/` directory. Protected protocol D remains
`74475463add0f23afd6d84b801245650712bbb62`.

The mass-sensitive R implementation is present at
`RobotConstants.java:18,113-154`: production hashing inserts the supplied mass
into the canonical input, followed by efficiencies, typed declarations,
`ENCODERS`, and `PINPOINT`. `RobotConstantsHashTest.java:10-15` checks the
default hash and that 12.0 versus 18.0 kg differ. The Java hash for the default
12.0 kg profile is
`b189515a90da49e2e98a63de90daf23912f8d17e80bd937800ced3f4fba1555d`.

### Reverse-direction seam checks

| Seam | Result and source anchors |
|---|---|
| Protocol contract and negotiation | **PASS** — D `protokol.md:94-136` requires proto2 negotiation, exactly two semantic maps, sparse positional hold/reset, typed lists, and shared `shooterLeft` roles; D `:150-159` defines backend/determinism boundaries. R `SimHal.java:106-149`, `Mechanism.java:89-131`; S `sim/server.py:130-141,202-211,890-913,976-1029`. |
| Two maps, proto1 compatibility, power zero-fill | **PASS** — R `SimHal.java:192-231`; S `sim/server.py:202-211,904-913,1012-1029`; no third map, absent proto1 uses full maps/zero-fill, and DC/CR omission is zero. |
| Positional hold/reset and real binding | **PASS** — R `RealHal.java:68-105`, `Hardware.java:36-123`; S `sim/server.py:900-913`, `kinematic_backend.py:54-58`, `pymunk_backend.py:174-180`, `pybullet_backend.py:346-352`; sparse hood hold/reset and explicit zero match. |
| Shared port and paired validation | **PASS** — R `ActionValidator.java:19-33,54-90`, `Hardware.java:36-123`; S `sim/physics/motor.py:245-262`; shooterRight remains the speed encoder and shooterLeft the turret input/active output. |
| Configured mass and forwarding | **PASS** — S `sim/mechanism.py:289-316,687-722`, `sim/physics/pymunk_backend.py:81-107`, `pybullet_backend.py:185-220`, `multi.py:64-95`; parser requires positive finite mass, both physics backends use it, and sparse frames forward lockstep. |

The four paired protocol-v2 fixtures still compare byte-for-byte with the
previously recorded equal SHA-256 values (`ready`, `state`, `step-hold`, and
`step-explicit-zero`).

### Reverse-direction commands and limits

- R: `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew :core:test :sim:test --rerun-tasks` — **BUILD SUCCESSFUL**, 138 core + 17 sim tests, zero failures/errors/skips.
- S: `PYTHONPATH=/home/shared/projects/boobuzz/re-cock-nize/tests /home/shared/projects/boobuzz/re-cock-nize/.venv/bin/python -m unittest test_mechanism test_protocol_validation test_multi_robot test_process_network test_pymunk_backend test_pybullet_backend` — **49 tests, OK**.
- Independent parser/mass/name probing passed. The bounded review reports all protocol, two-map, hold/reset, shared-port, multi-backend and PyBullet checks PASS.
- No new live Java-to-S socket run was needed for this bounded rerun. Java protocol tests use `FakeSimServer`; no physical hardware, B02+ decay, tag, or source/protocol edit is claimed.

## B02 release/entry scaffold — no outcomes claimed

This is the B02-D entry record. It is documentation only and records the clean
entry state before either worker implementation is accepted. The entry docs pin
is D `3aebcfb52b0e4c4f228f0c4be59c1be6d5b15dc0`; the protected protocol pin is
`74475463add0f23afd6d84b801245650712bbb62`. The latest proven B01 source pins
used as B02 starting references are R `18b1d629fa21869963b9cd678e285c770f37c9d4`
and S `0ca3175b81fa499e8c169bbc005713aa4d63e3b2`, both on `dev-phase-1.1-a` and
origin. The A05 baseline remains D `cec382d6380ceb209700fe3abef19684556fb51a`
with annotated tag `p11a-baseline-v1`. No B02 implementation hash, test result,
trace, or seam-review result exists in this scaffold.

### Owned paths and review boundary

| Owner | B02 paths / responsibility |
|---|---|
| R | `J/subsystem/intake/PowerIntake.java`; factory wiring (exact binding file to be pinned by the R report); `JT/subsystem/intake/PowerIntakeTest.java` |
| S | `sim/physics/balls.py`; `sim/physics/mechanisms.py`; `tests/test_intake_capture.py` |
| D | This ledger and `orchestrator-log.md` only; no source, protocol, state, vision, range, PyBullet-parity, or field-expansion edits |

The future bounded reviews are direction-specific and watchdog-assigned: R
reviews S geometry and power mapping; S reviews R `PowerIntake`, constants, and
factory wiring. Do not start either review until both implementation pins land
and the assignment is explicit.

### Seed fixtures and required gates

The provisional B02 fixture uses an 18-in chassis, mouth forward offset 9 in,
opening 3.2 in, capture depth 2 in, capacity 3, pollen diameter 2.8 in and
nectar diameter 3.6 in. Seed 1 starts the robot at `(36,72,0)`, pollen at
`(48,72)`, `(54,72)`, `(60,72)`, and nectar at `(54,78)`. Intake runs while
normalized forward power is `.15`; the robot stops at public pose `(51,72,0)`
and then goes neutral. The required seed-1 outcome is **not yet run**: three
stored pollen, one external nectar, unique IDs, and conserved total
`inventory + world = 4`.

Seed 42 adds an approach offset of ±0.1 in as fixture noise; the seed-1 result
must be deterministic on rerun. Dedicated geometry checks move nectar to the
mouth and require blocking/obstruction, never class-based deletion. Full
storage blocks or pushes without deleting; reverse releases stored pollen at
the mouth. Capture requires an inward roller, a free object crossing the mouth,
available capacity, and swept contact; off/reverse cannot capture. Pymunk is the
plant and diagnostic event counts are not capture evidence.

The B02 acceptance gates are all required and none is claimed here:

1. R's focused intake suite covers signed `run(1)`, explicit `run(.8)`, negative,
   stop, BRAKE, and one-time HAL inversion.
2. S's `test_intake_capture.py` covers capture/release, reverse/off, capacity,
   obstruction, conservation, unique IDs, seed-1 determinism and seed-42 noise.
3. Both bounded bidirectional seam reviews pass with exact source pins, commands,
   outcomes and limitations recorded here.
4. One seed-1 end-to-end trace shows the Java intake driving the visible Pymunk
   scene without simulator-truth or event-count leakage.

Test counts alone cannot satisfy B02. No physical selectivity, Control Hub,
bench, sensor-truth inventory, or mechanical calibration claim is permitted;
the dimensions are provisional fixtures. B04 remains the later owner of honest
unknown inventory, and B08 owns a planar release body. No B03+ task, tag, reviewer,
ball, training, or protocol/vision/range/field work is part of this entry.

## B02 bounded seam-review checkpoint — acceptance paused (2026-09-18)

This checkpoint records the watchdog-assigned reviews without accepting B02. The
immutable implementation pins are R `63b5939ee69fdbc027436c91e54642caf27e2a1b`
and S `c34ebb8467f51f851a1db0adb30d0c5b55e16592`, both on
`dev-phase-1.1-a` and origin; R is clean and S has only the preserved untracked
`.claude/` directory. The protected protocol is D
`74475463add0f23afd6d84b801245650712bbb62`; the current docs pin used by the
reviews is D `671a28008e4c918bb52c766f06a28d1fab0d4941`.

### Review outcomes

| Watchdog-assigned direction | Result | Verified evidence and limitation |
|---|---|---|
| R → S: S geometry and power mapping | **FAIL overall; B02 intake behavior PASS** | R `PowerIntake.java:19-36` clamps finite logical power to `[-1,1]`, maps non-finite to zero, stops at zero, and writes the `intake` key; `RobotFactory.java:84-85` wires it for direct/cplx1; `RobotConstants.java:16-25,99` supplies geometry and `REVERSE/BRAKE`. S `sim/mechanism.py:139-161`, `pymunk_backend.py:186-188`, and `mechanisms.py:162-252` provide geometry, power forwarding, swept pollen capture, nectar obstruction, capacity, release, and private inventory. Focused S `PYTHONPATH=tests .venv/bin/python -m unittest tests.test_intake_capture tests.test_mechanism` passed 26 tests; S determinism/Pymunk `PYTHONPATH=tests .venv/bin/python -m unittest tests.test_determinism tests.test_pymunk_backend` passed 14; the seed-42 intake episode was exactly equal for 120 ticks with stored IDs `(1,2,3)` and external nectar ID `4`. However, `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew :sim:test --tests boobuzz.sim.ReplayIntegrationTest` failed at truth tick 229 (recorded expected/actual `PoseBits` differ), and `../re-cock-nize/.venv/bin/python tools/acceptance.py --chapter A --physics pymunk --seeds 1` failed repeat determinism at direct tick 201 (cplx1 tick 214 observed in another run); `--seeds 1,42` also failed repeat determinism. `AcceptanceMainTest` passed, and the A-drive reached its target, but these A traces use `intake=0.0` and no B02 scene. |
| S → R: R `PowerIntake`, constants, and factory | **PASS (bounded)** | Pins S `c34ebb8467f51f851a1db0adb30d0c5b55e16592` and R `63b5939ee69fdbc027436c91e54642caf27e2a1b`; both trees are clean except S's preserved `.claude/`. Exact R command `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew -q :core:test --tests boobuzz.core.subsystem.intake.PowerIntakeTest --tests boobuzz.core.RobotFactoryTest --tests boobuzz.core.hal.MechanismTest --tests boobuzz.core.hal.HardwareProfileTest --tests boobuzz.core.hal.RobotConstantsHashTest` passed 22 tests (3+5+10+3+1), zero failures/errors/skips. Exact S command `PYTHONPATH="/home/shared/projects/boobuzz/re-cock-nize/tests" "/home/shared/projects/boobuzz/re-cock-nize/.venv/bin/python" -m unittest test_mechanism test_intake_capture` passed 26 tests. The review verified finite clamp/non-finite handling, stop/false `hasBall`, intake-only output, direct+cplx1 factory wiring, exact geometry/hash inputs, single HAL direction/zero-power setup, and unchanged logical forwarding; no findings. Limitation: Java tests use fake/stub HAL, with no live Java-to-Pymunk B02 intake trace and no physical FTC claim. |

B02 acceptance remains paused. The required stable seed-1 Java-to-visible-Pymunk
end-to-end trace is not proven, and the cross-process replay/A-drive
determinism failure is outside the B02 intake fixture but still fails the required
gate. No source, protocol, tag, B03+, reviewer, ball, training, state, vision,
range, PyBullet-parity, or field-expansion work is authorized.

## A03 determinism diagnostic snapshot — no B02 acceptance (2026-09-18)

The authorized detached four-pin diagnostic used R18
`18b1d629fa21869963b9cd678e285c770f37c9d4`, R63
`63b5939ee69fdbc027436c91e54642caf27e2a1b`, S0
`0ca3175b81fa499e8c169bbc005713aa4d63e3b2`, and S34
`c34ebb8467f51f851a1db0adb30d0c5b55e16592`. For each pair, `installDist`,
`tools/acceptance.py --chapter A --physics pymunk --seeds 1,42`, and
`ReplayIntegrationTest` passed in the detached worktrees; fresh Replay repeats
were 3/3 for every pair. Acceptance repeats were R18/S0 3/3, R18/S34 3/3,
R63/S34 3/3, and R63/S0 2/3; the single unsuccessful R63/S0 run ended in a
transient `ServerClosedException` before a trace. Successful A-drive files had
6,000 lines and A-cancel files 202 lines, with raw-byte-identical repeats and no
first divergent tick/field/bits. R18/R63 traces matched after removing only the
R63 `motors.intake` key; every intake value was `0.0`, with no inventory, ball,
`hasBall`, B02 fields, or B02 scene.

The independent published-S command
`PYTHON="$PWD/.venv/bin/python" ./run_tests.sh` passed **115 tests**, 0 failures,
0 errors, and 0 skips. No S-owned causal defect was proven, so no source commit
or hash changed. The earlier published R→S failure remains a historical,
intermittent gate failure pending an authorized final disposition; this snapshot
does not prove the required Java positive-intake seed-1 end-to-end trace and does
not accept B02. Limitation: one detached matrix run had the transient transport
close above.
