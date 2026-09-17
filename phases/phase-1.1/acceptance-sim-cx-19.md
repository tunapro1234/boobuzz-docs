# sim-cx-19 simulator acceptance

## Acceptance matrix

Robot-code remote used: `origin/dev-phase-1.1` at `7e80ef5` (fetched before the run).  Each auto was allowed up to 4,000 ticks; `test-line` was allowed 1,000 ticks.  `Δxy` is Euclidean pinpoint-minus-truth distance in inches and `Δh` is the normalized heading difference in degrees.

| Backend | Engine | Scenario | Final (x,y,h rad) | Truth (x,y,h rad) | Δxy in | Δh ° | Steps | Tick mean ms | Wall s |
|---|---|---|---|---|---:|---:|---:|---:|---:|
| pymunk | cplx1 | BlueDoggy6Piece | (40.08,16.05,3.141) | (40.03,16.13,3.142) | 0.094 | -0.057 | 1072 | 0.2510 | 0.27 |
| pymunk | cplx1 | RedDoggy6Piece | (104.08,16.13,0.001) | (103.97,16.15,0.000) | 0.112 | +0.057 | 1152 | 0.2577 | 0.30 |
| pymunk | cplx1 | BlueMissionary9Piece | (55.85,115.87,1.570) | (55.87,115.93,1.570) | 0.063 | +0.000 | 1717 | 0.1976 | 0.34 |
| pymunk | cplx1 | RedMissionary9Piece | (88.16,116.00,1.569) | (88.11,115.98,1.571) | 0.054 | -0.115 | 1754 | 0.1803 | 0.32 |
| pymunk | cplx1 | BlueMissionary9PieceLever | (52.85,79.87,1.570) | (52.86,79.94,1.570) | 0.071 | +0.000 | 1717 | 0.2017 | 0.35 |
| pymunk | cplx1 | RedMissionary9PieceLever | (91.18,80.05,1.567) | (91.13,79.97,1.571) | 0.094 | -0.229 | 2263 | 0.1980 | 0.45 |
| pymunk | cplx1 | test-line | (119.98,71.97,6.283) | (119.94,72.01,6.283) | 0.057 | +0.000 | 1000 | 0.2269 | 0.23 |
| pymunk | direct | BlueDoggy6Piece | (40.08,16.05,3.141) | (40.03,16.13,3.142) | 0.094 | -0.057 | 1072 | 0.2811 | 0.30 |
| pymunk | direct | RedDoggy6Piece | (104.08,16.13,0.001) | (103.97,16.15,0.000) | 0.112 | +0.057 | 1152 | 0.2741 | 0.32 |
| pymunk | direct | BlueMissionary9Piece | (55.85,115.87,1.570) | (55.87,115.93,1.570) | 0.063 | +0.000 | 1717 | 0.2829 | 0.49 |
| pymunk | direct | RedMissionary9Piece | (88.11,115.87,1.570) | (88.12,115.94,1.570) | 0.071 | +0.000 | 1717 | 0.2850 | 0.49 |
| pymunk | direct | BlueMissionary9PieceLever | (52.85,79.87,1.570) | (52.86,79.94,1.570) | 0.071 | +0.000 | 1717 | 0.2579 | 0.44 |
| pymunk | direct | RedMissionary9PieceLever | (91.18,80.05,1.567) | (91.13,79.97,1.571) | 0.094 | -0.229 | 2263 | 0.2372 | 0.54 |
| pymunk | direct | test-line | (119.98,71.97,6.283) | (119.94,72.01,6.283) | 0.057 | +0.000 | 1000 | 0.3658 | 0.37 |
| pybullet | cplx1 | BlueDoggy6Piece | (40.12,16.07,3.138) | (40.08,16.16,3.138) | 0.098 | +0.000 | 1072 | 0.3798 | 0.41 |
| pybullet | cplx1 | RedDoggy6Piece | (104.01,16.04,6.281) | (103.94,16.16,6.282) | 0.139 | -0.057 | 1336 | 0.3088 | 0.41 |
| pybullet | cplx1 | BlueMissionary9Piece | (55.87,115.92,1.571) | (55.83,115.98,1.571) | 0.072 | +0.000 | 2080 | 0.4809 | 1.00 |
| pybullet | cplx1 | RedMissionary9Piece | (88.15,115.94,1.576) | (88.19,115.96,1.575) | 0.045 | +0.057 | 1822 | 0.3144 | 0.57 |
| pybullet | cplx1 | BlueMissionary9PieceLever | (52.79,80.08,1.563) | (52.79,80.01,1.567) | 0.070 | -0.229 | 2277 | 0.2693 | 0.61 |
| pybullet | cplx1 | RedMissionary9PieceLever | (91.17,79.87,1.568) | (91.11,79.93,1.571) | 0.085 | -0.172 | 2375 | 0.2466 | 0.59 |
| pybullet | cplx1 | test-line | (120.11,71.97,6.282) | (120.07,72.01,6.281) | 0.057 | +0.057 | 1000 | 0.2294 | 0.23 |
| pybullet | direct | BlueDoggy6Piece | (40.12,16.07,3.138) | (40.08,16.16,3.138) | 0.098 | +0.000 | 1072 | 0.2791 | 0.30 |
| pybullet | direct | RedDoggy6Piece | (103.97,16.11,6.283) | (103.96,16.14,6.283) | 0.032 | +0.000 | 892 | 0.3562 | 0.32 |
| pybullet | direct | BlueMissionary9Piece | (55.85,115.94,1.571) | (55.83,115.91,1.570) | 0.036 | +0.057 | 2288 | 0.2532 | 0.58 |
| pybullet | direct | RedMissionary9Piece | (88.18,115.88,1.567) | (88.12,115.93,1.570) | 0.078 | -0.172 | 2375 | 0.2542 | 0.61 |
| pybullet | direct | BlueMissionary9PieceLever | (52.80,80.02,1.567) | (52.84,80.01,1.568) | 0.041 | -0.057 | 2612 | 0.2425 | 0.64 |
| pybullet | direct | RedMissionary9PieceLever | (91.10,80.05,1.571) | (91.16,79.96,1.572) | 0.108 | -0.057 | 2682 | 0.2701 | 0.73 |
| pybullet | direct | test-line | (120.11,71.97,6.282) | (120.07,72.01,6.281) | 0.057 | +0.057 | 1000 | 0.2687 | 0.27 |
| kinematic | cplx1 | BlueDoggy6Piece | (40.04,16.13,3.141) | (40.02,16.12,3.142) | 0.022 | -0.057 | 2208 | 0.1701 | 0.38 |
| kinematic | cplx1 | RedDoggy6Piece | (103.91,16.15,6.283) | (103.87,16.10,6.283) | 0.064 | +0.000 | 2721 | 0.1554 | 0.42 |
| kinematic | cplx1 | BlueMissionary9Piece | (55.83,116.01,1.568) | (55.87,115.93,1.571) | 0.089 | -0.172 | 1524 | 0.2101 | 0.32 |
| kinematic | cplx1 | RedMissionary9Piece | (88.23,116.02,1.570) | (88.14,115.98,1.571) | 0.098 | -0.057 | 1583 | 0.2001 | 0.32 |
| kinematic | cplx1 | BlueMissionary9PieceLever | (52.97,80.00,1.570) | (52.90,79.99,1.571) | 0.071 | -0.057 | 1821 | 0.1908 | 0.35 |
| kinematic | cplx1 | RedMissionary9PieceLever | (91.24,79.90,1.571) | (91.15,79.96,1.571) | 0.108 | +0.000 | 2193 | 0.1687 | 0.37 |
| kinematic | cplx1 | test-line | (120.00,71.97,0.001) | (119.96,72.01,0.000) | 0.057 | +0.057 | 1000 | 0.2718 | 0.27 |
| kinematic | direct | BlueDoggy6Piece | (40.03,16.15,3.142) | (40.03,16.12,3.142) | 0.030 | +0.000 | 2090 | 0.2095 | 0.44 |
| kinematic | direct | RedDoggy6Piece | (103.94,16.13,6.283) | (103.92,16.12,0.000) | 0.022 | -0.011 | 2208 | 0.2167 | 0.48 |
| kinematic | direct | BlueMissionary9Piece | (55.83,116.01,1.568) | (55.87,115.93,1.571) | 0.089 | -0.172 | 1524 | 0.2633 | 0.40 |
| kinematic | direct | RedMissionary9Piece | (88.23,116.02,1.570) | (88.14,115.98,1.571) | 0.098 | -0.057 | 1583 | 0.2471 | 0.39 |
| kinematic | direct | BlueMissionary9PieceLever | (52.97,80.00,1.570) | (52.90,79.99,1.571) | 0.071 | -0.057 | 1821 | 0.2444 | 0.45 |
| kinematic | direct | RedMissionary9PieceLever | (91.24,79.90,1.571) | (91.15,79.96,1.571) | 0.108 | +0.000 | 2193 | 0.2953 | 0.65 |
| kinematic | direct | test-line | (120.00,71.97,0.001) | (119.96,72.01,0.000) | 0.057 | +0.057 | 1000 | 0.3533 | 0.35 |

## Tick-time means

| Backend | Engine | Mean tick over seven scenarios (ms) | Slowest scenario mean (ms) |
|---|---|---:|---:|
| pymunk | cplx1 | 0.2162 | 0.2577 |
| pymunk | direct | 0.2834 | 0.3658 |
| pybullet | cplx1 | 0.3185 | 0.4809 |
| pybullet | direct | 0.2749 | 0.3562 |
| kinematic | cplx1 | 0.1953 | 0.2718 |
| kinematic | direct | 0.2614 | 0.3533 |

## Additional checks

| Check | Command/setup | Result |
|---|---|---|
| Two-robot lockstep | pymunk headless server `--robots 2 --port 5764`; two compiled `boobuzz.sim.SimMain` clients on 5764/5765, cplx1, `BlueDoggy6Piece` and `RedDoggy6Piece`, seed 0 | Both exit 0; client 1: 1,072 ticks, final `(40.08,16.05,3.141)`, truth `(40.03,16.13,3.142)`; client 2: 1,152 ticks, final `(104.08,16.13,0.001)`, truth `(103.97,16.15,0.000)`; server log confirms both connected before either bye |
| Pymunk determinism | Fresh headless server per run; protocol client reset seed 42, 200 × 20 ms full-forward steps; repeated on ports 5770 and 5771 | Truth SHA-256 `0af7de95eb3616c3df93ceee5f1e859977b2069346be9a0d60082aa8cece48b4` on both runs; final truth `(135.10000023029198,12.727922468625833,-4.39648317751562e-14)` |
| Kinematic determinism | Same protocol client/setup on ports 5772 and 5773 | Truth SHA-256 `76a8fd550a559e9a53efb9cedf912e9332cb61ebe4ac6f900f84be4ec31a9279` on both runs; final truth `(131.27207793864216,12.727922061357855,0.0)` |
| Bag record/replay | Record `test-line` with cplx1 on pymunk port 5780 to a temporary JSONL bag; replay the bag on port 5781 with `--controller replay` | Both Gradle clients exit 0, 1,000 ticks; record and replay final/truth pose exactly `(119.98,71.97,6.283)` / `(119.94,72.01,6.283)`; bag contained 3,001 lines |

## Anomalies and acceptance notes

- All 42 matrix rows exited successfully and all six autos reported their complete sequence (10/10, 16/16, or 19/19).  The largest normalized matrix error was `Δxy=0.139 in` and `|Δh|=0.229°`; therefore no row exceeded the requested `0.15 in` or `0.3°` thresholds.
- A concurrent `./gradlew :sim:run` two-client attempt on ports 5766/5767 exposed a startup race: client 0 failed with server `send reset before step (reset barrier is incomplete)` while client 1 completed.  No code was changed.  Running the same clients from the already-built robot-code `SimMain` classes on 5764/5765 produced a true overlapping lockstep pass; the successful result above is the acceptance run.  A Gradle retry with delayed second startup (5768/5769) also exited 0 but completed sequentially.
- Kinematic headings may print as `6.283` while truth prints `0.000`; delta calculations normalize this wrap to zero.
- Matrix server command (each isolated port): `PYTHON="$PWD/.venv/bin/python" python -m sim.server --mechanism ../robot-code/TeamCode/core/src/main/java/boobuzz/core/hal/RobotConstants.java --physics BACKEND --headless --port PORT`.
- Matrix client commands: `cd ../robot-code && JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew -q :sim:run --args="--port PORT --auto NAME --engine ENGINE --steps 4000 --tap-port 0"` (or replace `--auto NAME` with `--path test-line --steps 1000`).  No robot-code or simulator source files were modified.  All acceptance servers were terminated; ports 5700–5781 are free.
