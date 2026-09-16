# robot-cx-16 — simulator cross-review

Reviewed read-only on `re-cock-nize` branch `dev-phase-1.1`, range
`8af8281..05a367b` (HEAD `05a367b`). I compared the Python server, all three
physics backends, multi-robot mode, `TapReader`, viewer tap path, bag CLI, and
tests with `phase-1.1/design-spec.md` and `docs/protokol.md`, and checked the
Java `SimHal`/`SimMain` client. No files in `re-cock-nize` were edited.

The simulator test suite passes (`.venv/bin/python -m unittest discover -s tests
-p 'test_*.py' -v`: 71 tests), but the following contract and safety gaps remain.

## Findings

### [blocker] Malformed step values can crash the server or advance a wrong clock

Location: `sim/server.py:536-548`; event validation at `sim/server.py:568-593`.

`dt_ms` is only checked with `> 0` and is then truncated with `int()`. A JSON
`0.5` becomes a zero-duration backend call, `NaN`/`Infinity` can raise an
uncaught `ValueError`/`OverflowError`, and `true` is accepted as one millisecond.
Motor values are not checked for finite numeric values, range `[-1, 1]`, or
declared motor names. The outer server catches `ProtocolError` but not these
conversion/backend `ValueError`s, so one malformed client line can terminate the
process; otherwise the Java clock and Python clock can silently diverge.

Fix: require a non-boolean, finite integer `dt_ms > 0`; validate every motor
name/value against the ready contract and `[-1,1]`; validate reset seed/pose the
same way; convert all failures to `ProtocolError` and add malformed-frame tests.

### [major] Multi-robot lockstep waits forever for a stalled client

Location: `sim/server.py:347-376` (`_multi_submit`).

Once two slots are ready, a robot that submits `step` waits on the condition
variable until every ready slot submits the same tick. There is no deadline,
heartbeat, or stalled-slot eviction. A connected client that stops sending
leaves every other Java `SimHal.write()` blocked indefinitely, contrary to the
blocking/timeout safety expected of a lockstep bridge.

Fix: add a configurable per-tick deadline (and a monotonic heartbeat if needed),
return a clear protocol error, close/evict the stalled slot, and make remaining
robots receive a deterministic zero-power/coasting transition. Test a client
that submits one tick and then goes silent.

### [major] Single-client socket reads and writes have no I/O deadline

Location: `sim/server.py:469-496` (`serve_connection`); the client-side blocking
exchange is `sim/src/main/java/boobuzz/sim/SimHal.java:230-241`.

The server's `makefile().readline()` and `conn.sendall()` are unbounded. A peer
that sends a partial line, stops reading replies, or disappears behind a broken
TCP path can hold the only server connection forever. Java `SimHal.receive()` has
the same unbounded read, so a real Control Hub run can hang rather than fail a
tick and stop safely.

Fix: apply bounded read/write timeouts (or a non-blocking transport with a
deadline), treat expiry as a connection/protocol failure, and add partial-line,
non-reading-peer, and reconnect tests. The timeout must not advance physics
without a complete `step`/`state` pair.

### [major] Multi-robot reset is not an epoch/barrier operation

Location: `sim/server.py:317-345`; `sim/physics/multi.py:46-48`.

Each robot can issue `reset` independently while another ready slot has a pending
step. The implementation resets only one backend's pose, clock, encoder, and RNG
without invalidating other pending messages or establishing a shared reset
epoch. The next lockstep reply can therefore contain different `t_ms` origins
and a mixed deterministic history.

Fix: require a reset barrier for all connected clients (or attach an epoch and
reject steps from the previous epoch), atomically clear pending/results, and test
reset-vs-pending-step races and a client joining late.

### [major] The bag reader does not enforce the three-seam-per-tick contract

Location: `sim/bag.py:53-81` and `sim/bag.py:143-249`.

`parse_bag()` accepts any non-empty seam name and any number of records per
timestamp; `summarize()` merely counts unique timestamps and silently tolerates
missing or duplicate `hal`, `subsystem`, or `logic` lines. A truncated or
misordered bag can therefore look valid and feed a shifted request timeline to
replay tooling.

Fix: require one header followed by exactly one `hal`, `subsystem`, and `logic`
record for each tick (with a consistent `t_ms`), reject duplicates/gaps, and
test truncated, duplicate, and out-of-order bags before summarizing.

### [major] Tap drop metadata is incompatible with the bag parser

Location: `sim/bag.py:72-78`; producer shape in
`robot-code/TeamCode/core/src/main/java/boobuzz/core/debug/DebugTap.java:261-264`.

The robot's drop notification is `{"tap_dropped": ...}` without `seam` or
`t_ms`. `parse_bag()` rejects that record after an otherwise valid header, while
`ReplayController` silently skips it. Thus queue pressure produces a bag that
the simulator CLI cannot inspect and two tools disagree about its validity.

Fix: reserve a documented metadata record (for example `seam: "meta"` with a
timestamp) or put the cumulative counter in the header/footer; make the parser
accept only that defined metadata form and keep the three seam records intact.

### [minor] Event data is not constrained to the protocol's numeric map

Location: `sim/server.py:568-593`, especially `data` handling at lines 587-592.

The protocol defines event `data` as a string-to-double map, but the server only
checks that `data` is a dictionary and accepts strings, nested objects, arrays,
and non-finite values. Such events can be recorded by the viewer/bag tool but
cannot be treated consistently by Java's numeric event model.

Fix: require string keys and finite numeric values (and reject booleans), with a
focused invalid-event test; preserve the validated object unchanged in logs.

### [minor] `TapReader` makes one connection attempt and never reconnects

Location: `sim/tap.py:151-173`; startup path `sim/server.py:638-647`.

The viewer starts `TapReader` before or alongside the robot. A transient
connection refusal or a robot restart ends the daemon thread permanently, so
`--tap` remains stuck at “waiting for logic seam” until the viewer is restarted.

Fix: retry with bounded exponential backoff while the reader is open, reset the
socket on EOF, and add a test where the tap publisher starts after the reader and
where it reconnects after a drop. Keep queue/drop accounting monotonic.

### [minor] Determinism tests do not cover process/network replay boundaries

Location: `tests/test_determinism.py:80-101` and
`tests/test_multi_robot.py:137-173`.

The tests compare episodes in one Python process and, for multi-robot mode,
compare backend pose tuples directly. They do not restart the server, compare
serialized JSON byte-for-byte, exercise a stalled/reconnected client, or verify
that full multi-robot sensor state (noise, encoders, gamepad schema) remains
identical after a process boundary.

Fix: run the same seeded message transcript against fresh server processes and
compare every emitted state line byte-for-byte for each backend and for two
robots; include reconnect and ready/reset records in the transcript.

### [minor] The `servos` channel is accepted by Java but dropped by the server

Location: Java sends `servos` in `sim/src/main/java/boobuzz/sim/SimHal.java:148-150`;
`sim/server.py:542-548` reads only `motors` before stepping.

The current constants declare no servos, so this is not an active mechanism bug,
but adding a servo later will silently have no simulator effect and unknown servo
names are never checked. That is contract drift from the step schema.

Fix: validate the `servos` object against the ready list and either model/store
its values explicitly or reject non-empty servo commands until a servo backend is
specified; add a schema test.

## Review conclusion

Physics backend selection, seeded noise, event forwarding, gamepad `back`/`start`,
and the normal one-client `ready`/`step` shape match the referenced documents on
the tested paths. The findings above should be resolved before treating the
multi-robot, tap, and bag tools as a production-safe protocol implementation.

## sim-cx-16 response

- Blocker input validation: `37d45b7`; multi-robot deadline/eviction: `0a348c6`; single-client server I/O deadline: `e3eee77`.
- Reset epochs/barrier: `d9b3320`; strict three-seam bag groups: `c16b676`; tap-drop compatibility/reporting: `d81c138`.
- Cheap minors: numeric event data `f501507`, TapReader reconnect `bfa9c29`, explicit servo validation/rejection `f6666b0`.
- Verification: `PYTHON="$PWD/.venv/bin/python" ./run_tests.sh` — 81 tests passed.
- Pymunk/Java test-line on port 5590: 1000 ticks completed; final `x=119.98 y=71.97 h=6.283`, truth `x=119.94 y=72.01 h=6.283`; port released.
- Java `SimHal` timeout changes were intentionally not made because this task forbids robot-code edits; the Python server now bounds reads/writes.
- Java `DebugTap` producer was not edited; Python accepts its existing bare `tap_dropped` line and canonical `seam:meta` footer.
- Process/network byte-for-byte determinism was not added: it is a non-cheap minor and outside the requested behavior changes.
