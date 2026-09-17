# sim-cx-21 — simulator work log

Branch: `dev-phase-1.1-a`, baseline `518bf9c`. Reports are intentionally left for ftc-docs-cx to commit.

## R8 review

Pinned review target `4b8ba23c76671182f707d56e9a20af78f26f41f0`; findings and isolated Java evidence are in `review-robot-r8-sim.md`.

## Process/network determinism

The existing suite compared in-process server episodes only. I reproduced the startup race against a fresh `--robots 2` process: robot 0 could receive a state at `t_ms=20` before robot 1 connected; when robot 1 then reset, the first connection was invalidated. This was an in-scope barrier defect, not a physics nondeterminism.

Implemented in simulator commits `78bad126e3f80836b4c8152f2beded851c14623a` and `5dd6daacedbd629deb0827b36240f3064a808f3b`. `sim/server.py` now signals connection/reset barrier waiters and holds an early multi-robot `step` until every configured slot is connected and reset in the current epoch; the existing per-tick eviction deadline remains unchanged. `tests/test_process_network.py` starts fresh headless processes, compares exact serialized `ready` and every `state` line (including seeded noise and headless gamepad), compares two-robot lockstep transcripts against a deliberately staggered reset/start, and asserts that the first client has no reply before the peer reset/step. Transport timing is checked only for the no-early-reply property; it is not part of the byte-identical physics comparison.

Verification for the working change:

- Commit `78bad126e3f80836b4c8152f2beded851c14623a`: from `/home/shared/projects/boobuzz/re-cock-nize`, `PYTHON="$PWD/.venv/bin/python" ./run_tests.sh -k process_network` — 2 passed; `PYTHON="$PWD/.venv/bin/python" ./run_tests.sh -k multi_robot` — 8 passed; pinned-R8 Java smoke on port `5835` completed 1000 ticks (sensor `(119.98,71.97,6.283)`, truth `(119.94,72.01,6.283)`).
- Commit `5dd6daacedbd629deb0827b36240f3064a808f3b`: from `/home/shared/projects/boobuzz/re-cock-nize`, `PYTHON="$PWD/.venv/bin/python" ./run_tests.sh -k process_network` — 2 passed; pinned-R8 Java smoke on port `5838` completed 1000 ticks (sensor `(119.98,71.97,6.283)`, truth `(119.94,72.01,6.283)`).
- From `/home/shared/projects/boobuzz/re-cock-nize`: `PYTHON="$PWD/.venv/bin/python" ./run_tests.sh -k multi_robot` — 8 passed.
- From `/home/shared/projects/boobuzz/re-cock-nize`: `PYTHON="$PWD/.venv/bin/python" ./run_tests.sh` (after `5dd6daa`) — **83 passed, 0 skipped**.
- Focused pinned-R8 Java tests: from `/tmp/sim-cx-21-r8-bWOe4v`, `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew -q :core:test --tests boobuzz.core.controller.socket.SocketControllerTest --tests boobuzz.core.debug.DebugTapTest --tests boobuzz.core.debug.BagWriterTest` — passed.
- Pinned-R8 Java smoke server command (run from `/home/shared/projects/boobuzz/re-cock-nize`): `PYTHONPATH=/home/shared/projects/boobuzz/re-cock-nize /home/shared/projects/boobuzz/re-cock-nize/.venv/bin/python -m sim.server --mechanism /tmp/sim-cx-21-r8-bWOe4v/TeamCode/core/src/main/java/boobuzz/core/hal/RobotConstants.java --physics pymunk --headless --quiet --port 5838`.
- Pinned-R8 Java client command (run from `/tmp/sim-cx-21-r8-bWOe4v`): `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew -q :sim:run --args="--port 5838 --path test-line --steps 1000 --tap-port 0"` — `1000 ticks finished`, sensor `(119.98,71.97,6.283)`, truth `(119.94,72.01,6.283)`; server terminated and port 5838 is free. The isolated checkout is `/tmp/sim-cx-21-r8-bWOe4v`.

The pre-fix staggered reproduction and post-fix test use no external artifact files; test source is `tests/test_process_network.py`. Java smoke logs are retained at `/tmp/sim-cx21-r8-java-final.log` and `/tmp/sim-cx21-r8-server-final.log`.

## Remaining acceptance gaps

The robot-cx-22 simulator cross-review also records two simulator-scope items that this task did not broaden to change: multi-robot worker sockets still need bounded read/write deadlines for partial-line and non-reading peers, and event `t_ms` validation still truncates finite fractional values. They do not affect the fresh-process determinism proof or the single-client Java smoke; they remain explicit follow-up items rather than silently being treated as closed.
