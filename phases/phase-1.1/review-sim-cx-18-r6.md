# sim-cx-18: R6 robot-code cross-review

Reviewed `robot-code` branch `dev-phase-1.1` at `dc4da66`, the stable result of
`4151143..origin/dev-phase-1.1` (16 commits).  The gate was observed as required:
the branch contained `7a7cbfb Replay has no bit-equal simulator integration test`,
the robot-cx pane reported R6 complete, and the fetched commit count remained
unchanged for ten minutes after the last observed commit.  Review was read-only;
no robot-code files were edited.

I read `review-sim-cx-15-r4-r5.md` including its R5 addendum, inspected every
commit in the range, the cumulative source and tests, and checked the R4 seam
amendment (immutable frames; one dispatcher serializes records).  I ran
`JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew -q :core:test :sim:test`
(117 core tests and 9 sim tests, all green) and
`JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew -q :TeamCode:assembleDebug`
(green; only the existing Java-8/deprecation warnings were emitted).  The robot
worktree was clean and `git diff --check 4151143..origin/dev-phase-1.1` was clean.

## Disposition of the R4/R5 findings

- `5fbc7c1` **closed** the Android `INTERNET` blocker; the permission is present in
  `FtcRobotController/src/main/AndroidManifest.xml:5-8` and the debug APK assembles.
- `46bf2ba` **closed** the shared tap-writer finding.  `DebugTap.java:30-38,278-328`
  has a global bounded frame queue, an independent bounded queue per client, and
  a writer per client; the dispatcher does not perform client socket writes.
- `826b83e` **closed** the bag drop-record finding.  Drop lines are client-only and
  `BagWriter.java:84-103` writes a timestamped `seam:meta` footer; the Python bag
  reader accepts that metadata without breaking three-seam tick groups.
- `8bf55f7` **closed** the active-path timeout finding.  `SocketController.java:107-118`
  emits one `RequestBatch.cancelAll()` after a valid command goes stale; both
  engines consume it and stop their owners.  The added test covers DirectEngine
  and CplxEngine1.
- `68aeace` **closed** the semantic-malformed-input finding.  `SeamJson.java:124-318`
  validates the complete batch, finite numbers, request types, paths, and cancels
  before `lastReceivedNanos` changes; malformed lines are ignored as keepalives.
- `99d1551` **closed the normal-entry-point lifecycle finding**: AutoMain,
  TeleopMain, SimMain, and the socket/tap accept/read/dispatch workers now have
  `finally`/join paths.  Residual shutdown edge cases are recorded below.
- `2094bc0` and `907c31a` **closed** the minSdk API finding.  Production robot-path
  code no longer uses `java.nio.file`, `isBlank`, `Stream.toList`, `List.of`,
  `Map.of`, or `copyOf`; the Android debug assembly passed.
- `3c52351` **closed** feedback starvation: `SocketController.java:200-270` has a
  dispatcher plus an independent bounded outbound queue/writer per connection.
  The slow-client/reconnect test passed.
- `8329676` **closed the header-precedence regression**.  `ReplayController.java:66-68`
  now chooses the recorded `start_pose` over the first HAL seam, and
  `ReplayControllerTest.java:47-68` proves that precedence.
- `7a7cbfb` **partially closes** the missing bit-equal proof: a real seeded Pymunk
  record/replay test exists and compares every truth pose bit-for-bit.  Its
  portability and scenario limitations are finding M1 below.
- `ed28303` **closed** the duplicate intake terminal-status regression by separating
  actuator ownership from terminal IDs; `IntakeRequestLifecycleTest` covers both
  engines.
- `8e3fa97` **partially closes** the R3/R4 coverage finding with direct-engine,
  cadence, shutdown, and integration tests.  The remaining coverage/portability
  gap is M1; lifecycle residuals are M2/M3 below.
- `2a649b4` **closed the ordinary bag-path preflight failure**: `RobotLoop.java:177-201`
  rejects directories, cannot-create, and unwritable targets before configuration.
  A late dispatcher I/O race remains M3 below.
- `3f06e94` **closed** the simulator-stall ambiguity: `SimHal.java:67-97,263-274`
  bounds connect/read waits and reports a clear `SimProtocolException`.
- `dc4da66` **closed** the zero-dt Pedro NaN trigger: `PedroDrive.java:136-144`
  skips follower updates when the HAL timestamp has not advanced and emits zero
  powers; the regression test passed.

No commit body records an author disagreement with the prior review.  The commit
subjects directly name the finding they address; the only follow-up changes are
the timeout and zero-dt hardening above.  No JSON seam field, request field, or
physics command was changed in this range.

## Tap, bag, and socket safety

`RobotLoop.publishSeams()` hands a `DebugFrame` to a non-blocking queue.  The
contract records copy maps/lists/arrays, `PathRequest` and `Event` recursively
protect their current values, and `SubsystemTrace.drainCalls()` returns a copied
list, so the dispatcher receives immutable snapshots.  `DebugTap` serializes
each frame once, writes the bag before enqueueing client lines, and drops only the
oldest item in a full client queue.  A slow tap reader therefore cannot stall the
loop, a fast reader, or bag writes.  Drop metadata is no longer inserted as a
fourth per-tick seam.

`SocketController` keeps accept/read work off the loop, rejects malformed batches
without refreshing the watchdog, sends a one-shot cancel-all on timeout, and
keeps feedback publication independent from a client's bounded outbound queue.
The reconnect and malformed-input tests exercise these properties.  The two
remaining bounded-cleanup concerns are M2 and M3 below; neither blocks
`RobotLoop.decide()` or the control tick.

## Replay header and equality

Header `start_pose` precedence is correct at `ReplayController.java:66-68`: a
normal bag starts from its reset metadata, not its first post-action HAL sample.
The regression test supplies deliberately different poses, and the seeded
integration test compares all 80 recorded/replayed truth samples bit-for-bit.
However, a legacy bag without `start_pose` still falls back to its first HAL seam,
which can be post-reset (`ReplayController.java:54-60,66-68`); see M4.  The
integration test itself is not an auto/test-line run and can silently skip on
another checkout; see M1.

## Findings requiring follow-up

### [major] M1 — replay integration test is machine-path-gated and not an auto/test-line scenario

Location: `sim/src/test/java/boobuzz/sim/ReplayIntegrationTest.java:30-52`.

The new test hard-codes `/home/shared/projects/boobuzz/re-cock-nize` and uses
`Assume.assumeTrue` when that path's venv is absent.  On CI or another developer
machine it is therefore reported as skipped rather than proving replay.  Even on
this machine it records a fixed `RequestStream.manual(...)` for 80 ticks, not the
R4.4 acceptance run (`BlueDoggy6Piece` or `test-line`), so auto sequencing/path
requests can regress while the test remains green.

Concrete fix: derive the simulator root from a required Gradle property or
`FTC_SIM_ROOT`/`PYTHON` environment variable (fail loudly when the integration
test is explicitly enabled), and record/replay a seeded `AutoController` run or
the registered `test-line` path for the required duration.  Keep the per-tick
bit-equal truth comparison and add a deliberately truncated-bag assertion.

### [minor] M2 — tap and socket writer shutdown has no bounded write deadline

Locations: `TeamCode/core/src/main/java/boobuzz/core/debug/DebugTap.java:311-359`;
`TeamCode/core/src/main/java/boobuzz/core/controller/socket/SocketController.java:253-305`.

Both writer loops call `BufferedWriter.flush()` directly.  `close()` closes the
socket and joins for 500 ms (tap) or 1 s (socket), but if the OS send blocks,
there is no write deadline and the daemon writer can outlive the opmode after the
join returns.  Queue isolation means this no longer stalls the control loop, but
it does not strictly prove the R4 shutdown requirement.

Concrete fix: use a non-blocking `SocketChannel`/bounded writer executor or an
explicit write deadline that closes a peer on expiry; after close, assert every
accept/read/write/dispatch thread has terminated rather than only waiting a
fixed interval.

### [minor] M3 — bag preflight cannot report a late dispatcher open/write failure

Locations: `TeamCode/core/src/main/java/boobuzz/core/RobotLoop.java:166-203`;
`TeamCode/core/src/main/java/boobuzz/core/debug/DebugTap.java:228-245`.

`openBag()` now catches ordinary path errors synchronously, but `BagWriter` is
still opened and written by the dispatcher.  A permission/filesystem race after
the preflight sets `DebugTap.bagError` and stops bag output; `SimMain` checks only
the boolean returned by `openBag()`, not that asynchronous error, so a run can
still report success without a complete bag.

Concrete fix: expose a synchronous/open future or an atomic terminal error that
the entry point checks before declaring success; fail the run (and surface the
path/error) when the dispatcher cannot open or write the bag.

### [minor] M4 — legacy replay without a header pose can still start one tick late

Location: `TeamCode/core/src/main/java/boobuzz/core/controller/replay/ReplayController.java:54-68`.

The explicit header pose now wins, but when it is absent the fallback remains the
first HAL pinpoint.  A HAL seam is emitted after the first action, so this is a
post-motion pose rather than a reset pose.  That legacy path can still shift a
replay even though all new bags include `start_pose`.

Concrete fix: require `start_pose` for replay (or persist a true pre-action reset
seam) and reject a bag lacking it; retain a test for explicit rejection and one
for header precedence.

### [minor] M5 — Teleop can leak a socket controller if loop construction fails

Location: `TeamCode/src/main/java/org/firstinspires/ftc/teamcode/opmode/TeleopMain.java:27-42`.

When `DEFAULT_CONTROLLER` is `socket`, `SocketController` starts its accept and
feedback threads before `RobotFactory.createWithController()` is called.  An
exception during mechanism/loop construction occurs before the `try/finally`
starting at line 46, so those threads are not closed on this startup-error path.

Concrete fix: put controller creation and loop construction in one guarded
try/finally, or close `socketController` in a catch around the factory call.

### [minor] M6 — reset-pose compatibility default can silently ignore a reset

Location: `TeamCode/core/src/main/java/boobuzz/core/subsystem/IDrive.java:15-26`.

The R5 reset fix reaches `PedroDrive`, but the interface's default `resetPose`
remains a no-op.  A future production drive implementation can therefore return
`DONE` from both engines without applying the requested pose.

Concrete fix: make `resetPose` mandatory for production implementations or return
an explicit unsupported result; add a test for every production drive.

### [minor] M7 — direct logic still depends on the cplx1 implementation package

Location: `TeamCode/core/src/main/java/boobuzz/core/logic/direct/DirectMap.java:7,151-156`.

The R5 RPM semantics are now functionally consistent, but `DirectMap` imports
`cplx1.ShooterLogic` solely for `calibratedRpm`.  This couples the supposedly
independent direct engine to the complex-engine package and makes future package
changes or selective builds brittle.

Concrete fix: move the shared calibration function to a neutral contract/utility
class and have both engines depend on that class.

### [nit] N1 — DebugTap class comment no longer describes the writer topology

Location: `TeamCode/core/src/main/java/boobuzz/core/debug/DebugTap.java:25-26`.

The comment says the dispatcher is the sole thread performing socket I/O, while
per-client writer threads at lines 290-321 perform the actual writes.  This is a
documentation-only inconsistency; update the comment to say the dispatcher is
the sole serializer and bag writer, while client workers only transport already
serialized lines.

## Ten-line summary

1. R6 snapshot is `dc4da66`, with 16 commits after `4151143`.
2. The Android network permission and minSdk production API issues are closed.
3. Tap publication is immutable, queued, per-client, and loop-side non-blocking.
4. Bag drop records are client-only; the bag footer carries timestamped metadata.
5. Socket malformed input is ignored and stale paths receive a one-shot cancel-all.
6. Feedback echoes use a bounded per-connection queue and survive reconnects.
7. Replay header `start_pose` correctly overrides the first HAL seam.
8. The bit-equal test exists, but M1 gates it by a machine path and fixed manual stream.
9. M2-M7 are minor lifecycle, bag-error, legacy-pose, contract, and architecture residuals.
10. No new JSON/physics behavior regression was found; blocker count is zero.

## Severity count

`blocker: 0` · `major: 1` · `minor: 6` · `nit: 1`
