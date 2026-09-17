# R8 simulator cross-review

Review target: immutable robot-code commit `4b8ba23c76671182f707d56e9a20af78f26f41f0` (`05d79ff..4b8ba23`). Review is read-only; no robot-code files were edited.

## Findings

No blocker, major, minor, or nit findings were reproduced in R8. The two R7 residuals (M2 writer shutdown and M3 terminal asynchronous bag errors) are addressed by the pinned changes below.

## Evidence

- `0b77bee`: `SocketController.Connection` and `DebugTap.Client` each use a bounded 1 s write watchdog around `BufferedWriter.write/newLine/flush`; expiry closes the socket and joins the transport workers (`SocketController.java:227-343`, `DebugTap.java:302-419`). The close paths avoid self-joins and close the socket before joining a potentially blocked writer.
- `0b77bee`: close tests assert accept, reader, writer, watchdog, feedback, client, and dispatch workers terminate (`SocketControllerTest.java:132-151`, `DebugTapTest.java:100-118`).
- `4b8ba23`: `DebugTap.close()` interrupts and drains the dispatcher before removing clients, and reports a dispatcher that remains alive (`DebugTap.java:119-152,168-236`). `closeBag()` retains terminal `BagWriter` errors (`DebugTap.java:259-271`, `BagWriter.java:83-116`). `RobotLoop.closeDebugTap()` captures the terminal error, and `SimMain` checks it after `finally` teardown (`RobotLoop.java:163-169,219-227`, `SimMain.java:172-181`).
- The R8-focused isolated checkout was pinned detached at `4b8ba23`. `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew -q :core:test --tests boobuzz.core.controller.socket.SocketControllerTest --tests boobuzz.core.debug.DebugTapTest --tests boobuzz.core.debug.BagWriterTest` passed.
- Pinned Java smoke used the simulator on port `5833`, tap port `0`: `.../.venv/bin/python -m sim.server --mechanism /tmp/sim-cx-21-r8-bWOe4v/TeamCode/core/src/main/java/boobuzz/core/hal/RobotConstants.java --physics pymunk --headless --quiet --port 5833`; isolated Java `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew -q :sim:run --args="--port 5833 --path test-line --steps 1000 --tap-port 0"`. It completed 1000 ticks, sensor `(119.98,71.97,6.283)`, truth `(119.94,72.01,6.283)`; the server was terminated and port 5833 is free.

## Scope checked

I inspected the R8 diff and cumulative `DebugTap`, `BagWriter`, `RobotLoop`, `SimMain`, `SocketController`, immutable contract records, Android-facing imports, tests, and replay/bag shutdown flow. JSON seam/request fields and physics behavior are unchanged. The simulator process-boundary determinism gap is addressed by simulator commit `78bad12` and documented in `sim-cx-21-report.md`.

Severity count: `blocker: 0` · `major: 0` · `minor: 0` · `nit: 0`.
