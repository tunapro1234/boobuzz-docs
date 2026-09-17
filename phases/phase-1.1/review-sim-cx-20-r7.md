# sim-cx-20: R7 robot-code cross-review

Reviewed `robot-code` `origin/dev-phase-1.1` at `05d79ff`, the nine-commit
range `dc4da66..05d79ff`.  The required gate was observed: fetch/log count
remained nine for 724 seconds (the ten-minute requirement is 600 seconds).
Review was read-only; the robot-code worktree remained clean.

I read `review-sim-cx-18-r6.md`, inspected every R7 commit and the cumulative
source/tests, then ran the tests and Android build from the fetched checkout:

```text
JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew --rerun-tasks :core:test :sim:test
BUILD SUCCESSFUL; 120 core tests + 10 sim tests, 0 failures/errors/skips
JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew --rerun-tasks :TeamCode:assembleDebug
BUILD SUCCESSFUL (only existing Java-8/deprecation and native-strip warnings)
```

`git diff --check dc4da66..origin/dev-phase-1.1` was clean.  The R7 commits
were all pushed and their subjects match the R6 findings; no commit body
records an author disagreement.

## R7 commit disposition

| Commit | Subject | R6 item | Disposition |
|---|---|---|---|
| `7e80ef5` | Make replay integration proof portable and path-based | M1 | **closed** |
| `a3d2e6b` | Surface asynchronous bag failures | M3 | **partially closed**; residual below |
| `cca03b4` | Reject replay bags without a reset pose | M4 | **closed** |
| `835b815` | Close socket controller on TeleOp startup failure | M5 | **closed** |
| `ebfbba1` | Make unsupported drive resets fail explicitly | M6 | **closed** |
| `ad5e564` | Move shooter calibration to shared logic | M7 | **closed** |
| `4f427ac` | Clarify debug tap writer topology | N1 | **closed** |
| `791af3d` | Add closed-loop socket controller example | new R7 coverage/GOTO fix | **passed; no regression found** |
| `05d79ff` | Document real robot socket agent smoke test | documentation | **passed; no regression found** |

## R6 findings: closed and outstanding

- **M1 — closed.** `sim/src/test/java/boobuzz/sim/ReplayIntegrationTest.java:31-80`
  now runs a 10,000-tick seeded `test-line` record/replay, compares every
  truth pose bit-for-bit, and rejects a truncated logic seam.  The machine path
  is configurable through `FTC_SIM_ROOT`/`PYTHON` or Gradle properties and
  fails loudly with an assertion instead of silently skipping; the default is
  the normal sibling checkout layout (`:89-121`).
- **M2 — not closed (minor).** `4f427ac` corrects only the class comment.
  `TeamCode/core/src/main/java/boobuzz/core/debug/DebugTap.java:312-322` and
  `TeamCode/core/src/main/java/boobuzz/core/controller/socket/SocketController.java:253-261`
  still call `BufferedWriter.flush()` without a write deadline.  Their close
  paths (`DebugTap.java:333-361`, `SocketController.java:272-305`) interrupt
  and join for fixed intervals, so a blocked OS write can outlive the opmode.
  Concrete fix: use a bounded/non-blocking writer or a socket write deadline,
  then assert every writer/reader/accept/dispatch thread is terminated after
  close rather than relying only on a timed join.
- **M3 — partially closed (minor).** `a3d2e6b` exposes
  `RobotLoop.bagError()` (`TeamCode/core/src/main/java/boobuzz/core/RobotLoop.java:162-165`)
  and checks it in `sim/src/main/java/boobuzz/sim/SimMain.java:171-172`.
  The check occurs before the `finally` calls `loop.close()` (`:174-177`),
  while the dispatcher can still be draining frames; late `ensureBag()` or
  `BagWriter.closeWithTapDrops()` failures (`TeamCode/core/src/main/java/boobuzz/core/debug/DebugTap.java:163-226`,
  `BagWriter.java:83-103`) can therefore be missed or swallowed.  Concrete
  fix: make close/flush drain the dispatcher and return/throw its terminal bag
  error, then check that result after the drain; add a test that makes the path
  unwritable after configuration.
- **M4 — closed.** `TeamCode/core/src/main/java/boobuzz/core/controller/replay/ReplayController.java:30-65`
  requires a header `start_pose`, removes the post-action HAL fallback, and
  `ReplayControllerTest.java:70-81` proves legacy rejection.  The explicit
  header still supplies the initial pose before any replay action.
- **M5 — closed.** `TeamCode/src/main/java/org/firstinspires/ftc/teamcode/opmode/TeleopMain.java:41-67`
  creates `RobotLoop` inside the `try/finally`; a factory exception now closes
  an already-started `SocketController`.
- **M6 — closed.** `TeamCode/core/src/main/java/boobuzz/core/subsystem/IDrive.java:23-26`
  now throws explicit `UnsupportedOperationException` instead of silently
  acknowledging reset, with `ResetPoseEngineTest.java:50-64` coverage.  The
  production `PedroDrive` implementation overrides it.
- **M7 — closed.** `TeamCode/core/src/main/java/boobuzz/core/logic/ShooterCalibration.java:1-20`
  is neutral shared logic; `DirectMap.java:4-7,151-156` no longer imports the
  cplx1 implementation package, while cplx1 keeps its compatibility wrapper.
- **N1 — closed.** `TeamCode/core/src/main/java/boobuzz/core/debug/DebugTap.java:25-27`
  now accurately says the dispatcher serializes/bags and client workers only
  transport serialized lines.

## Tap, bag, socket, and lifecycle review

`RobotLoop.publishSeams()` still hands frames to a bounded non-blocking queue.
`DebugFrame` copies the call list and carries immutable contract records;
`DebugTap` serializes and writes the bag on its dispatcher, while each client
has an independent bounded drop-oldest string queue.  A slow tap client cannot
block the control tick or bag writer.  The remaining writer-deadline issue is
M2 above.

`SocketController.decide()` only reads atomics and enqueues feedback.  Accept,
JSON parsing, and socket writes remain on background threads; malformed input
does not refresh `lastReceivedNanos`, and a stale valid connection receives a
one-shot `cancelAll()`.  Feedback has its own bounded queue, so it cannot starve
the loop.  `close()` closes the server/current socket and joins reader/writer
workers; the unbounded-OS-write edge is the same M2 residual.  `TeleopMain` now
closes the controller on factory failure, and the normal opmode `finally` path
still closes both controller and loop.

The R7 `tools/agent_example.py` and `SocketAgentIntegrationTest` exercise a
closed-loop GOTO → SHOOT flow against seeded pymunk; the test passed.  The
`PedroDrive` change in `791af3d` makes a non-zero GOTO build and follow a line
from the current pose, while preserving the hold-only case when x/y already
match.  No JSON request/feedback fields or engine handoff semantics changed.

## Replay pose and bit equality

`ReplayController` now accepts only bags with an explicit reset `start_pose` and
uses that pose verbatim.  The R7 integration test records/replays the registered
`test-line` path for 10,000 ticks against a real pymunk server, compares all
truth samples by `Double.doubleToLongBits`, and checks truncated-bag rejection.
The test passed with no skipped assumptions.  This closes the R6 legacy-pose
and portability/scenario gaps; the only replay-related residual is the general
asynchronous bag-error timing in M3.

## Android, SDK, and threading checks

The production changes use Android-compatible Java APIs; the new
`ShooterCalibration` and `IDrive` changes are plain Java 8-level code.  The
Java 9+ APIs (`Files.writeString`, `readAllBytes`, process helpers) are confined
to simulator tests/tools and are not in the APK path.  `:TeamCode:assembleDebug`
passed.  `SequenceRunner` and its request/status state machine were inspected
unchanged across R7; no new threading or lifecycle regression was found.

## New regressions and disagreements

No blocker or major regression was found in the cumulative R7 source, tests,
tap/bag/socket paths, replay handling, or Android build.  All nine commits
directly implement or document the named R6 item; no author disagreement was
stated in a commit body.  The only outstanding findings are the two minor
items M2 and M3 above, both already identified in R6.

## Ten-line summary

1. R7 is `05d79ff`, nine commits after the R6 snapshot `dc4da66`.
2. The fetched commit count stayed at nine for 724 seconds before review.
3. M1 is closed by a portable, non-skipping 10,000-tick test-line replay proof.
4. M4 is closed by mandatory replay-header `start_pose` validation.
5. M5 is closed by TeleOp factory-failure cleanup of SocketController workers.
6. M6 is closed by an explicit unsupported reset contract and test.
7. M7 and N1 are closed by neutral shooter calibration and corrected topology docs.
8. The new socket agent/GOTO path integration passed; no protocol regression exists.
9. M2 (write deadlines) and M3 (late asynchronous bag errors) remain minor.
10. Core/sim tests (120/10) and `TeamCode:assembleDebug` passed; blockers/majors: zero.

## Severity count

`blocker: 0` · `major: 0` · `minor: 2` · `nit: 0`
