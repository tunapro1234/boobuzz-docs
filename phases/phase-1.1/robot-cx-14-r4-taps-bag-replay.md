# robot-cx-14 — R4: debug taps at the layer seams, bagging, ReplayController, SocketController

Repo: `robot-code`, branch `dev-phase-1.1` (after R3, robot-cx-13). English only. Read before
edit. Commit + push per step, report hashes. `:core` stays pure Java (java.net sockets are
fine, no SDK, no third-party JSON: reuse the hand-written JSON code from `:sim`'s client or move
a minimal encoder into `:core`). Nothing in this task may change robot behaviour when taps are
off; the six autos + test-line must still pass on pymunk.

## R4.1 — DebugTap (broadcast socket)
`core/debug/DebugTap`: TCP server on a configurable port (`RobotConstants.DEBUG_TAP_PORT`,
default 5600; 0 = off). Accepts any number of listeners, sends line-delimited JSON, never
blocks the robot loop: a bounded queue per client, drop oldest on overflow and count drops.
Runs in the sim and on the Control Hub identically (started by `RobotLoop` when port ≠ 0).

## R4.2 — Three seams published by RobotLoop, one line each per tick
```
{"seam":"hal","t_ms":..,"state":{enc,vel,yaw,pinpoint,voltage},"action":{motors,servos,events}}
{"seam":"subsystem","t_ms":..,"calls":[{"sub":"drive","op":"manual","args":[..]},...],"events":[..]}
{"seam":"logic","t_ms":..,"feedback":{snapshot,statuses},"batch":{stream,requests,cancels}}
```
`calls` come from a thin recording wrapper around `Subsystems` (decorator, only when taps are
on). Field names for `stream`/`requests` mirror the Java records exactly.

## R4.3 — Bagging
`RobotLoop` option `bagPath`: writes the same three lines per tick to a `.jsonl` file (in sim
via `SimMain --bag <file>`, on the robot into the SDK's log folder via `RealHal`'s opmode
parameter). Bag header line: `{"bag":1,"engine":..,"controller":..,"constants_hash":..}`.

## R4.4 — ReplayController
`controller/replay/ReplayController implements IController`: reads a bag, on each tick emits
the recorded `batch` for that tick index (ignores Feedback). Test: record `--auto BlueDoggy6Piece`
on pymunk (seed 0) to a bag, replay with `--controller replay --bag <file>` → identical final
pose (bit-equal `truth` sequence in the sim log; sim is deterministic).

## R4.5 — SocketController
`controller/socket/SocketController implements IController`: listens on
`RobotConstants.CONTROL_SOCKET_PORT` (default 5601, 0 = off). One client sends line-delimited
JSON `RequestBatch` (same schema as the `logic` seam's `batch`); the controller uses the latest
received batch each tick and an empty batch (stream zeros, no requests) if nothing arrived for
`CONTROL_SOCKET_TIMEOUT_MS` (250) — the robot stops when the client goes silent. Also echoes
Feedback back to the client each tick (so an external agent has a closed loop).
Test: a Java test client drives test-line through the socket in the sim.
`SimMain --controller gamepad|auto|replay|socket`; `TeleopMain`/`AutoMain` on the robot choose
via a `RobotConstants` string for now (`DEFAULT_CONTROLLER`).

## R4.6 — Tools + docs
`tools/tap.py` (in this repo, Python stdlib only): `tap.py <host> <port> [--seam logic] [--grep SHOOT]`
pretty-prints tap lines; `tools/drive.py <host> <port>` sends a batch from stdin/keyboard as a
smoke test for SocketController. `core/README.md` gains a "Debugging on the real robot" section:
connect laptop to the robot WiFi, `python tools/tap.py 192.168.43.1 5600`, what each seam shows.

## Report
Hashes; seam line samples; bag size for one auto; replay equality result; socket test result;
anything that did not fit.
