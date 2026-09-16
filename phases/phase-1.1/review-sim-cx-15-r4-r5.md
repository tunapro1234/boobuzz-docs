# sim-cx-15: R4 tap, bag, replay, and socket cross-review

Reviewed read-only on `robot-code` branch `dev-phase-1.1`, commit range
`d4226eb..33ace3f` (review pin: `33ace3f`).  I read
`robot-cx-14-r4-taps-bag-replay.md` and the dispatcher amendment: the loop thread
must enqueue immutable frames, while one dispatcher serializes and writes them.
All source and test references below are pinned to `33ace3f`; later branch
commits and the dirty robot working tree were not used as review evidence.  No
robot-code files were edited.

## Summary

The loop's normal tap path does enqueue a `DebugFrame` and keeps JSON, socket,
and bag work off the control thread.  The contract records currently copy their
mutable maps, lists, arrays, and event data, so the captured frame is safe with
the present value types.  The R4 implementation nevertheless has safety and
deployment blockers: there is no Android network permission, tap clients share a
synchronous writer, bag files can contain non-seam drop records, a socket
watchdog does not cancel an active path, and opmode shutdown is not exception
safe.  Replay has only a one-batch unit test rather than the required bit-equal
simulation test.

## Findings

### [blocker] Android manifest does not grant network access

Location: `FtcRobotController/src/main/AndroidManifest.xml:7-15`;
`TeamCode/core/src/main/java/boobuzz/core/debug/DebugTap.java:57-63`;
`TeamCode/core/src/main/java/boobuzz/core/controller/socket/SocketController.java:70-76`.

The only declared permission is `RECEIVE_BOOT_COMPLETED`.  The R4 tap and socket
controllers open TCP sockets on the Control Hub Wi-Fi, but an Android app without
`android.permission.INTERNET` cannot perform those network operations.  The
feature therefore fails on the real robot even though the pure-Java code builds.

Fix: add `<uses-permission android:name="android.permission.INTERNET" />` to the
merged application manifest and verify the installed APK's merged manifest on a
Control Hub.

### [major] DebugTap has no per-client bounded queue and blocks its dispatcher

Location: `TeamCode/core/src/main/java/boobuzz/core/debug/DebugTap.java:29-35,98-112,242-257,273-287`.

There is one global `ArrayBlockingQueue<DebugFrame>` and each `Client.write()`
performs a synchronous `BufferedWriter.flush()`.  A laptop that stops reading
can block the sole dispatcher indefinitely; every other listener and the bag then
wait behind that client.  When the dispatcher is stuck, the global queue drops
whole frames rather than dropping only the slow client's oldest lines.  This does
not block `RobotLoop.offer`, but it violates R4.1's independent per-client
bounded-queue/drop-oldest contract and can lose bag ticks as a side effect.

Fix: serialize each frame once, enqueue the resulting lines into an independent
bounded queue per client, and let a dedicated writer thread per client flush and
disconnect a permanently blocked peer.  Keep bag writing on its own dispatcher
path so a slow tap listener cannot remove bag frames.  Add a two-client slow-reader
test that asserts the fast reader continues and only the slow client reports drops.

### [major] Drop-report records corrupt the R4 bag stream

Location: `TeamCode/core/src/main/java/boobuzz/core/debug/DebugTap.java:166-184,242-249,261-264`.

`dropLine()` creates `{"tap_dropped":...}` without a `seam` or `t_ms`, but it is
passed to `writeLines()`, which writes to both clients and `BagWriter`.  Therefore
a bag that experiences queue pressure contains extra non-seam records instead of
exactly the header plus three seam lines per tick required by R4.3.  The header's
`tap_dropped` field remains zero, so the extra records are also the only place the
final count appears.  A strict bag reader or a replay tool expecting seam records
can reject the file.

Fix: send drop notifications to tap clients through a client-only method, or
store the final count in a defined header/metadata field at close; never append a
non-seam line to the bag.  Add a bag test after forced queue overflow that checks
the header and every subsequent record's seam/timestamp shape.

### [blocker] Socket timeout can leave an active path driving

Location: `TeamCode/core/src/main/java/boobuzz/core/controller/socket/SocketController.java:104-114`;
`TeamCode/core/src/main/java/boobuzz/core/logic/cplx1/MotionLogic.java:57-60`;
`TeamCode/core/src/main/java/boobuzz/core/logic/direct/DirectEngine.java:85-90`.

After `CONTROL_SOCKET_TIMEOUT_MS`, `decide()` returns `RequestBatch.idle()`.  Both
engines stop only when there is no active drive job; an existing GOTO/PATH/TURN_TO
job remains active when an idle batch has no requests.  Thus a silent socket can
stop manual stream input while Pedro continues following the last edge-triggered
path, contrary to the explicit “robot stops when the client goes silent” safety
requirement.

Fix: make the watchdog transition emit a cancel-all/safe-stop batch (or add an
engine-level timeout hook that cancels every active owner before returning idle),
then return zero stream values.  Add an integration test that starts a path,
waits past the timeout without another line, and asserts zero motor output plus a
terminal cancellation status in both engines.

### [major] Semantically malformed JSON is accepted as a keepalive

Location: `TeamCode/core/src/main/java/boobuzz/core/controller/socket/SocketController.java:166-176`;
`TeamCode/core/src/main/java/boobuzz/core/debug/SeamJson.java:95-117`;
`TeamCode/core/src/main/java/boobuzz/core/debug/JsonCodec.java:29-57`.

Syntax errors are caught, but an object such as `{}` or one with the wrong field
types is converted by `batchFrom()` into an idle batch using defaults.  The reader
then updates `lastReceivedNanos`, so a broken client can send `{}` forever and
prevent the timeout watchdog from firing.  Combined with the active-path issue
above, this can keep stale motion alive while the controller appears connected.

Fix: validate the complete RequestBatch shape and finite numeric fields before
publishing it; reject invalid records without changing `latest` or
`lastReceivedNanos`.  Add tests for malformed syntax, `{}`, wrong `stream`
types, unknown request types, and repeated invalid lines while a path is active.

### [major] Feedback echo can be starved by a non-reading socket client

Location: `TeamCode/core/src/main/java/boobuzz/core/controller/socket/SocketController.java:187-203,230-235`.

The loop-side enqueue is non-blocking, but the single feedback writer calls a
blocking `write()` and `flush()` with no write deadline.  A client that stops
reading can hold that thread forever; the 64-entry queue then drops old feedback,
including terminal statuses, and no later feedback can reach a reconnecting client
until the blocked socket fails.  This violates the closed-loop echo goal even
though the control thread itself remains responsive.

Fix: use a bounded per-connection outbound queue and a writer that disconnects a
peer when writes exceed a deadline (or use a non-blocking channel), preserving the
latest feedback status.  Test a client that never reads while repeatedly calling
`decide()` and assert bounded latency, a recorded drop/disconnect, and successful
feedback delivery after reconnect.

### [major] Tap and socket threads are not reliably closed by opmode shutdown

Location: `TeamCode/src/main/java/org/firstinspires/ftc/teamcode/opmode/AutoMain.java:28-53`;
`TeamCode/src/main/java/org/firstinspires/ftc/teamcode/opmode/TeleopMain.java:41-57`;
`sim/src/main/java/boobuzz/sim/SimMain.java:126-173`;
`TeamCode/core/src/main/java/boobuzz/core/RobotLoop.java:169-179`;
`TeamCode/core/src/main/java/boobuzz/core/debug/DebugTap.java:114-139`;
`TeamCode/core/src/main/java/boobuzz/core/controller/socket/SocketController.java:117-140`.

`AutoMain` never closes its `RobotLoop`; `TeleopMain` closes the
`SocketController` only on the normal fall-through path and never closes the
loop; `SimMain` likewise closes resources only after the run reaches the bottom of
the try block.  Exceptions, an early stop, or an unfinished auto can leave the
DebugTap dispatcher/accept thread and socket reader/writer threads alive.  Even
`DebugTap.close()` does not join the accept thread and waits only two seconds for
the dispatcher before closing clients, so a blocked client may outlive the call.

Fix: put `RobotLoop` and any controller in `try/finally`/try-with-resources in all
entry points, close on every `waitForStart`/opmode-stop/exception path, and join
accept, reader, writer, and dispatcher threads after closing their sockets.  Add a
shutdown test that interrupts a blocked client and asserts no R4 thread remains.

### [major] R4 classes use APIs newer than the Android minSdk without desugaring

Location: `TeamCode/core/src/main/java/boobuzz/core/controller/replay/ReplayController.java:12-31`;
`TeamCode/core/src/main/java/boobuzz/core/debug/BagWriter.java:7-34`;
`TeamCode/core/src/main/java/boobuzz/core/controller/socket/SocketController.java:169-172`;
`TeamCode/core/src/main/java/boobuzz/core/debug/SeamJson.java:42-46,66,81-83`;
`FtcRobotController/build.gradle:10-26` and `build.common.gradle:48-53`.

The app declares `minSdkVersion 24` and no `coreLibraryDesugaring` dependency.
R4 adds `java.nio.file.Path/Files` (Android API 26), `String.isBlank()` (API 33),
and `Stream.toList()` (API 34); these calls are reachable in bag/replay, socket,
and tap code on older Control Hubs.  R4's `List.copyOf`/`Map.copyOf` usage is also
newer than the declared floor (API 31) unless an external desugaring policy is
added.  The Java 17 source/target setting alone does not backport these library
methods.

Fix: use API-24-compatible `java.io.File`/stream readers and `trim().isEmpty()`
plus explicit loops/`Collectors.toList()`, or configure and verify Android core
library desugaring for every API used.  Run the assembled APK on the oldest
supported Control Hub, not only a host-JVM test.

### [major] Replay has no bit-equal simulator integration test

Location: `TeamCode/core/src/test/java/boobuzz/core/controller/replay/ReplayControllerTest.java:23-45`;
`sim/src/test/java/boobuzz/sim/SimMainTest.java:7-15`.

The replay test creates one temporary header and one logic line, then checks a
request ID and start pose.  It never records a real auto, runs the same bag through
`ReplayController`, or compares the complete `truth` sequence/final pose.  The
required deterministic replay guarantee can therefore regress while all current
tests remain green.

Fix: add an end-to-end test that records a seeded test-line or auto run, replays
the bag with the recorded initial pose and engine, and compares every truth sample
(and final pose) bit-for-bit.  Include a deliberately truncated/extra-line bag
case so tick alignment is checked too.

### [minor] Replay fallback pose can shift a bag by one tick

Location: `TeamCode/core/src/main/java/boobuzz/core/controller/replay/ReplayController.java:43-53`;
`TeamCode/core/src/main/java/boobuzz/core/RobotLoop.java:145-165`.

When a caller uses the legacy `openBag(path, controllerName)` overload without a
`startPose`, replay falls back to the first HAL pinpoint.  That HAL seam is
published after the first action/tick, not at reset, so replay can start from a
post-motion pose and diverge.  `SimMain` supplies a start pose, but the public
overload does not require one.

Fix: require/persist the reset pose before the first tick (or reject bags without
an explicit start pose) and test the legacy overload separately.

### [minor] Bag open failures are reported asynchronously and can be ignored

Location: `TeamCode/core/src/main/java/boobuzz/core/RobotLoop.java:145-165`;
`TeamCode/core/src/main/java/boobuzz/core/debug/DebugTap.java:221-239`;
`sim/src/main/java/boobuzz/sim/SimMain.java:120-123`.

`openBag()` returns true after only storing a volatile `BagSpec`; directory/file
creation occurs later on the dispatcher.  If the path is unwritable,
`ensureBag()` records `bagError`, but `SimMain` never checks it and the run can
report success with no usable bag.

Fix: validate/create the path synchronously before starting the run, expose a
failure future/status that the entry point checks, or fail the run when the
dispatcher cannot open the bag.

### [minor] R4 safety and integration tests are incomplete

Location: `TeamCode/core/src/test/java/boobuzz/core/debug/DebugTapTest.java:23-50`;
`TeamCode/core/src/test/java/boobuzz/core/debug/BagWriterTest.java:12-26`;
`TeamCode/core/src/test/java/boobuzz/core/controller/socket/SocketControllerTest.java:26-67`.

The current tests cover one client/one frame, zero-port construction, one happy
socket command plus a 300 ms timeout assertion, basic header writing, seam shape,
and a one-batch replay.  They do not cover slow or multiple tap clients,
per-client drop accounting, bag/drop-line invariants, immutable-frame mutation,
dispatcher/reader shutdown, malformed schema, active-path timeout stopping,
feedback backpressure/reconnect, or real simulator record/replay equality.

Fix: add focused bounded-queue and lifecycle tests plus one seeded simulator
integration test before treating R4 as production-ready.

## Areas with no finding

- **Loop-side non-blocking path:** `RobotLoop.tick()` does not call JSON encoding,
  socket writes, or bag I/O; it only drains subsystem calls and invokes
  `DebugTap.offer()` (`RobotLoop.java:181-190`).
- **Frame contents:** `RobotState`, `RobotAction`, `Feedback`, `RequestBatch`, and
  `Request` defensively copy maps/lists/arrays; `Event`, `PathRequest`, and
  `SubsystemTrace.Call` do likewise for their current nested values.  `Pose` from
  the Pedro core artifact is immutable.  No mutable builder is handed to the
  dispatcher.
- **Background accept/read:** DebugTap accept and SocketController accept/read
  work run on daemon threads, and the socket watchdog uses monotonic
  `System.nanoTime()` (`SocketController.java:104-114`).
- **Replay feedback handling:** `ReplayController.decide()` emits recorded logic
  batches in order and ignores the supplied feedback as the R4.4 contract says;
  the correctness problem is the missing end-to-end proof and fallback edge case,
  not that basic ordering.
- **JSON syntax isolation:** parser/runtime exceptions in a socket line are caught
  on the reader thread rather than propagated into `RobotLoop`; strict semantic
  validation is still required by the finding above.

## Ten-line handoff summary

1. R4 loop publication is asynchronous at the `RobotLoop` call site.
2. Current contract records provide adequate defensive copies for captured frames.
3. Android manifest lacks `INTERNET`, blocking both real-robot TCP features.
4. DebugTap has one global queue and synchronous per-client flushes.
5. Slow tap clients can stall bags and cause global frame loss.
6. Drop notifications are written into bags as non-seam records.
7. Socket timeout returns idle without canceling active path jobs.
8. Semantically malformed batches refresh the socket watchdog.
9. Opmode/exception shutdown does not reliably close or join all threads.
10. Replay coverage is unit-level only; add a seeded bit-equal simulator test.
