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

## R5 addendum

I reviewed every commit in `33ace3f..4151143` on robot-code
`dev-phase-1.1`, including the in-range R4.4 follow-up `aca0f19`.  The review is
read-only: no robot-code files were edited.  I inspected each patch, its added or
updated tests, the cumulative source at `4151143`, and the R3 review findings.
The robot worktree was clean at the review pin and `git diff --check 33ace3f..HEAD`
reported no whitespace errors.  I did not run Gradle because this was a source-only
cross-review.

### Per-commit disposition

#### `aca0f19` — R4.4 replay initial pose

**[major regression]** `TeamCode/core/src/main/java/boobuzz/core/controller/replay/ReplayController.java:29-58`
stores the header pose in `headerPose`, then lets the first `hal` seam populate
`loadedPose`, and finally always chooses `loadedPose` when it exists.  A normal bag
has both values, so the explicit reset pose in the header is silently ignored and
replay starts at the first-tick HAL sample (`RobotLoop.java:76-110`) rather than
the recorded reset metadata.  This undoes the header-based deterministic start and
can shift every replayed tick.
`ReplayControllerTest.java:23-45` has no HAL seam and therefore misses the regression.
Fix: prefer `headerPose` when present and use the first HAL pose only when the
header has no pose (or record a true pre-action reset seam); add tests for both
precedence cases and a seeded equality run.

#### `20f3812` — FTC loop yield

**[resolved]** `TeamCode/src/main/java/org/firstinspires/ftc/teamcode/opmode/AutoMain.java:43`
and `TeleopMain.java:54` now call `idle()` after each tick, addressing the named
watchdog/scheduler starvation finding without changing the control order.  No
regression was introduced.  The separate R4 shutdown/lifecycle finding remains:
these entry points still do not close `RobotLoop` in a `finally` block on early stop
or exception.

#### `4f0b38f` — RESET_POSE consumer

**[resolved for PedroDrive]** `CplxEngine1.java:154-165` and
`DirectMap.java:199-211` validate the pose, cancel active drive work, call the new
`IDrive.resetPose`, and return `DONE`; `PedroDrive.java:110-117` applies the pose
offset to `HalLocalizer`.  `ResetPoseEngineTest.java:25-46` covers both engines.
The compatibility default `IDrive.java:24-26` is a **[minor residual]**: a future
non-Pedro implementation can silently ignore reset while the engine still reports
`DONE`.  Make reset mandatory (or return an explicit unsupported result) and test
every production drive implementation.  The default is a reasonable source-
compatibility choice only while PedroDrive is the sole production implementation.

#### `3775131` — SHOOT RPM semantics

**[resolved]** `SequenceRunner.java:116-123`, `CplxEngine1.java:138-151`, and
`DirectMap.java:143-162` now use the same count-only calibrated RPM and validate
explicit RPM/count values identically.  `ShooterRpmConsistencyTest.java:25-78`
covers count-only, explicit, and invalid requests.  The interpretation is
consistent with the R3 contract.  A **[minor architectural regression]** is the
new `DirectMap.java:6` dependency on `logic.cplx1.ShooterLogic` for a shared
calculation, which couples the supposedly independent direct and cplx variants.
Move `calibratedRpm` to a neutral shared utility/contract location and keep both
engines on that dependency.  No functional RPM mismatch remains.

#### `5ef4a18` — stale action on engine handoff

**[resolved]** `RobotLoop.java:80-107` writes `RobotAction.zero()` on every actual
handoff tick, so an A→B→A switch cannot emit a retained action.  The regression test
`RobotLoopSwitchTest.java:94-129` exercises both handoffs.  No new behavior issue
was found; status forwarding for the cancellation itself was completed by the
later `2fa9655` commit.

#### `8c11fb7` — cancel-all turret safety

**[resolved]** both engine cancel-all paths call `ITurret.hold()`
(`CplxEngine1.java:61-67`, `DirectEngine.java:154-168`), and
`EngineCancelAllTurretTest.java:25-49` covers automatic aim and direct handoff.
No regression was found.  The test verifies the subsystem call rather than the
real turret's final actuator output; retain a HAL-level assertion when the real
turret implementation lands.

#### `658c3d4` — cplx1 per-request shooter cancellation

**[resolved]** `CplxEngine1.java:69-75` routes non-sentinel IDs to
`ShooterLogic.cancel`, which spins down, releases shot hold, clears state, and
emits a terminal cancellation status (`ShooterLogic.java:137-149`).  The direct
logic tests in `ShooterCancellationTest.java:29-56` and cplx routing test at
`:58-74` cover the path.  Coverage is still **[minor]** for an active `SHOOT`
through `CplxEngine1` itself (the engine-level case exercises `SPIN_UP`); add that
case and assert the feed mechanism is stopped.

#### `ef039a5` — manual sequence override

The safety intent is **[resolved]**: `TeleopController.java:59-65` exports all
sequence-owned IDs, and both engines stop drive, shooter, and intake owners.
However, the implementation introduces a **[major request-lifecycle regression]**.
`CplxEngine1.java:125-136` and `DirectEngine.java:86-97` immediately report
`INTAKE_ON`/positive `INTAKE` as `DONE` and also retain that same request ID in
`activeIntakeRequestIds`.  A later manual takeover cancels the retained ID and
emits `REJECTED("cancelled")` (`CplxEngine1.java:69-75`,
`DirectEngine.java:65-73`), so one request can be observed as `DONE` and then
`REJECTED`.  Track actuator ownership separately from the terminal request, or
stop the intake without a second status for an already-DONE ID; add a test that
asserts one terminal status per ID while still proving the intake motor stops.

#### `164619d` — attached sequence completion barriers

**[resolved]** `SequenceRunner.java:65-85,205-225` remembers terminal statuses and
holds advancement until every attached request is `DONE`; the new
`AutoControllerTest.java:55-77` proves a warmup cannot be bypassed by a completed
path.  No regression was found.  Rejection and cancellation are handled on the
tick where they are observed; add a retained-status failure test if status streams
can be sparse in a future controller.

#### `1620e33` — axis-aligned interpolation

**[resolved]** `HalDrivetrain.java:94-125` skips zero trigonometric terms and keeps
the forward/strafe limiting value for axis moves.  `HalDrivetrainTest.java:85-107`
covers forward-only, strafe-only, diagonal, and zero-speed cases.  No regression
was found for the non-negative velocity-limit contract.

#### `2fa9655` — switch statuses and validation

**[resolved]** `RobotLoop.java:78-108,211-240` queues invalid-switch rejections,
completes a valid same-engine switch, forwards old-engine cancellation statuses,
and preserves the zero-action handoff.  `RobotLoopSwitchTest.java:143-222`
covers malformed, out-of-range, repeated, and old-status cases.  No regression was
found; multiple valid switches are deterministically resolved by accepting the
first and rejecting the rest.

#### `3e7ab31` — unreachable ACCEPTED state

**[resolved]** `RequestStatus.State` is now `ACTIVE, DONE, FAILED, REJECTED`
(`RequestStatus.java:9-23`), matching all observed producers; the contract test
covers the active/terminal split.  The removal is justified by the producer search
and does not alter the JSON field names.  If old binary clients or hand-written
bags can contain `ACCEPTED`, retain a deprecated parser alias during migration;
no such producer exists in this tree.

#### `4e8f5fe` — path constraint validation

**[resolved]** `PathRequest.Constraints` and `Braking` reject non-finite and out-of-
range values at construction (`PathRequest.java:120-132,170-177`), before Pedro
modifiers are built.  `PathRequestValidationTest.java:7-35` covers representative
invalid powers, velocity, and braking.  The remaining **[minor test gap]** is the
absence of explicit negative/zero velocity and non-finite-power cases; add boundary
tests even though the constructor guards already reject them.

#### `4151143` — R3 safety coverage

This is **[partial]**, not a complete resolution of the named coverage finding.
`RobotLoopSafetyIntegrationTest.java:34-76` adds a useful cplx sequence → manual
takeover → engine-switch integration assertion, and the preceding commits add
focused unit tests.  There is still no real-HAL/SDK cadence test, no direct-engine
equivalent integration path, and no seeded end-to-end reset/RPM/replay assertion.
Add those cases (including a shutdown test) before marking R3 safety coverage
complete.

### Author choices, disagreements, and regressions

No commit body records an explicit disagreement with the R3 review; each describes
itself as a direct fix.  The compatibility no-op in `IDrive`, the shared-RPM helper
placement, and removal of `ACCEPTED` are implementation choices rather than
documented objections.  The only material behavior regression found in the range
is `aca0f19`'s header-pose precedence; the `ef039a5` duplicate terminal status is
the other material protocol defect.  All other named fixes are effective at the
behavior level, subject to the test gaps called out above.

### R5 addendum ten-line summary

1. Review pin is `4151143`; every commit in `33ace3f..HEAD` was inspected read-only.
2. `aca0f19` regresses replay by preferring a first-tick HAL pose over header reset pose.
3. `20f3812` adds FTC `idle()` and fixes the named loop starvation issue.
4. `4f0b38f` routes RESET_POSE through both engines and Pedro's software localizer.
5. `3775131` aligns count-only and explicit SHOOT RPM semantics across engines.
6. `5ef4a18` safely zeros outputs on A→B→A handoffs; `2fa9655` forwards statuses.
7. `8c11fb7` and `658c3d4` quiesce turret and cplx shooter cancellation paths.
8. `ef039a5` stops manual-sequence owners but can emit DONE then REJECTED for intake IDs.
9. `164619d`, `1620e33`, `3e7ab31`, and `4e8f5fe` resolve their named logic/validation findings.
10. `4151143` improves coverage but leaves direct, SDK, shutdown, and seeded replay tests.
