# robot-cx-22 simulator cross-review

Review target: completed robot-code round pinned at `d5bda622d5bba6df6c4bfefed69e0cc20d7e67`, with source change `1e555cbedb716af97cb4eef6c05885fe0a0f582d` after the R8 baseline `4b8ba23`. The review is read-only; no robot-code files were edited. The final commit contains the author's R9 audit and simulator cross-review reports only.

## Commit disposition

- `1e555cb` — **closed the named defect**. `StubTurret.hold()` now clears `aiming`, `scanning`, `lockedEventPending`, and `scanEventPending` (`TeamCode/core/src/main/java/boobuzz/core/subsystem/stub/StubTurret.java:60-66`). This prevents a cancelled settling aim or scan from becoming a later actuator event while preserving the current angle. The focused regression covers the settling-aim/lock path (`StubTurretTest.java:42-57`).
- `d5bda62` — **documentation only**. It records the R9 audit, hardware-deferred inventory, and acceptance evidence; it adds no executable behavior or protocol fields.

No blocker or major robot-code regression was found. No commit body records an author disagreement. The source remains Java-8/Android-compatible in this change and uses only existing stub state; no hardware names, request types, JSON fields, or simulator physics were changed.

## Finding

### [minor] The new hold regression does not exercise the pending scan event

Location: `TeamCode/core/src/test/java/boobuzz/core/subsystem/stub/StubTurretTest.java:42-57`.

The implementation correctly clears both `lockedEventPending` and `scanEventPending`, but the test only starts `aimAt()`, so `scanEventPending` is false when `hold()` runs. A future edit could regress scan cancellation while this test remains green. Add a focused `scan(); hold(); update()` assertion that no `turret.scan` event is emitted (or extend the existing test with that sequence). This is coverage-only; the current implementation passes the contract.

## Pinned pymunk acceptance

I cloned robot-code into isolated checkout `/tmp/sim-cx-21-r9-GPIBgJ` and detached at `d5bda62`; the original robot worktree was not built or edited. I ran `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew -q :core:test :sim:test :TeamCode:assembleDebug --rerun-tasks` with `FTC_SIM_ROOT=/home/shared/projects/boobuzz/re-cock-nize` and `PYTHON=/home/shared/projects/boobuzz/re-cock-nize/.venv/bin/python`: **122 core + 10 sim tests passed, 0 failures/errors/skips**, and `TeamCode:assembleDebug` passed (only existing Java-8/deprecation warnings). The isolated clone required its normal temporary `local.properties` SDK pointer; no source files were changed.

Using the current simulator commit `78bad12`, fresh headless pymunk server on port `5836`, tap port `0`, and the pinned Java client, I ran `test-line` plus all six registered autos on both `cplx1` and `direct` (14 runs; logs: `/tmp/sim-cx-21-r9-accept-DFIyg9`). Every run completed successfully. Sensor-versus-truth deltas were at most `0.112 in` and `0.229 deg`; every run stayed below the acceptance limits `0.15 in` and `0.3 deg`, and cplx1/direct endpoints matched in each scenario. Port `5836` was free after teardown.

| scenario | cplx1 ticks | direct ticks | sensor delta (in/deg) |
|---|---:|---:|---:|
| test-line | 10000 | 10000 | 0.014 / 0.000 |
| BlueDoggy6Piece | 1072 | 1072 | 0.094 / 0.057 |
| RedDoggy6Piece | 1152 | 1152 | 0.112 / 0.057 |
| BlueMissionary9Piece | 1717 | 1717 | 0.063 / 0.000 |
| RedMissionary9Piece | 1754 | 1754 | 0.054 / 0.115 |
| BlueMissionary9PieceLever | 1717 | 1717 | 0.071 / 0.000 |
| RedMissionary9PieceLever | 2263 | 2263 | 0.094 / 0.229 |

The robot-authored `review-sim-cx-21-robot.md` was also read. Its simulator findings were against the pre-`78bad12` baseline; the fresh-process determinism item is now closed by that simulator commit. Its separate multi-robot socket I/O and fractional-event-timestamp findings remain simulator scope and are not robot-cx-22 defects.

Severity count: `blocker: 0` · `major: 0` · `minor: 1` · `nit: 0`.
