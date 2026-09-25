# ADR B07.0 — analog seam, protocol v3

Status: **R implemented at robot-code `1c25ac3` (dev-phase-1.1-a), request
switch still at 2. S (re-cock-nize) not implemented.** This ADR does not amend
`protokol.md`; ftc-main folds it into the protected contract. Spec source:
`specs/03-mechanisms-cplx1.md` B07.0.

## Wire delta (v2 → v3)

```
reset  {"type":"reset", "proto":3, ...}                      unchanged shape
ready  {"type":"ready", "motors":[..], "servos":[..], "proto":3,
        "analogs":["turret_analog"],                          NEW, ordered
        "state":{ ... , "analog":{"turret_analog":1.1458333333}}}
state  {"type":"state", "t_ms":N, "enc":{..}, ..., "voltage":V,
        "analog":{"turret_analog":<volts sampled at t_ms>}}   NEW, every state
step   unchanged (two maps + events; analog is input only)
```

| Rule | v3 session | v1/v2 session |
|---|---|---|
| `ready.analogs` | required, must equal `RobotConstants.ANALOG_INPUTS` in order | must be absent |
| `state.analog` | required in `ready.state` and every `state` | must be absent |
| declared key missing / `null` / non-number | protocol error | — |
| value outside declared range (turret: `TURRET_ANALOG_MIN_V..MAX_V` = 0..3.3 V) | protocol error | — |
| undeclared key | protocol error | — |
| unit | volts (millivolts fail the range check) | — |
| Java result | `RobotState.analogVolts` = name → volts | empty map |

A missing or invalid analog value is **never** 0 V. `IHal` is unchanged.

## Negotiation

```
RobotConstants.SIM_PROTOCOL_VERSION  (Java int, R side)
        │  typed profile → reset.proto = SIM_PROTOCOL_VERSION
        ▼
server _require_proto: reset.proto == ready.proto, else reject
```

- Today `SIM_PROTOCOL_VERSION = 2`: the current server derives 2 from the profile
  and rejects any other `reset.proto`, so R keeps working unchanged.
- Proposal for S: derive the served version from the same constant (the parser
  already accepts `public static final int`). Flipping it to 3 then switches both
  sides in one edit, and no silent v2 fallback exists for a v3 request.

## Real robot (RealHal)

- `Hardware` binds `AnalogInput turret_analog` from `ANALOG_INPUTS`.
- `RealHal.read()` fills `analogVolts` from `getVoltage()` each tick and **omits**
  a reading outside the declared range, so consumers see it as invalid.
- `shooterLeft` is read as the turret encoder only through the existing encoder
  alias: no direction, FLOAT, run-mode or reset call. The single central B01 reset
  stays. `turret_servo` / `turret_servo2` stay FORWARD via the typed CR declarations.

## Fixtures

robot-code `sim/src/test/resources/protocol-v3/`:
`ready.json`, `state.json` (= v2 state + `analog`), and negatives
`state-analog-missing.json`, `state-analog-null.json`,
`state-analog-millivolts.json`, `state-analog-negative.json`,
`ready-analogs-mismatch.json`. S should mirror them in re-cock-nize
`tests/fixtures/protocol-v3/`, as with protocol-v2.

## v3 amendment (2026-09-25, ftc-main decision)

Why: under the original table the sim could not model a faulty sensor (B09 B-fault),
while the real robot already reads a value and drops it. Real hardware returns *some*
value even with a disconnected sensor; a structurally missing field only comes from a
bug.

| Rule | v3 session (amended) |
|---|---|
| declared key missing | protocol error (unchanged) |
| undeclared key | protocol error (unchanged) |
| value `null` / string / other non-number | protocol error (unchanged) |
| value finite but outside the declared range | **allowed on the wire**; the HAL omits it → invalid |
| value non-finite (`NaN`, `Infinity`, `-Infinity`) | **allowed on the wire**; the HAL omits it → invalid |

- Wire form of non-finite values: the bare tokens `NaN`, `Infinity`, `-Infinity`
  (what Python `json.dumps` emits by default). The Java `Json` parser accepts exactly
  these three tokens as numbers.
- **One code path.** `SimHal` and `RealHal` call the same core method to turn raw
  readings into `RobotState.analogVolts` (built on `Mechanism.AnalogInput.isValid`).
  There is no second copy of the range check in `SimHal`.
- Fixtures: `state-analog-millivolts.json` and `state-analog-negative.json` move from
  negatives to positives, and their expected result is "input omitted".
  `state-analog-missing.json` and `state-analog-null.json` stay negative. Add a `NaN`
  positive.
- S: the `--turret-analog-invalid-until-ms` fault hook sends `NaN` for the declared
  key and never drops the key.
- R: once S sends `NaN`, the Java-side B-fault harness workaround (removing the
  turret analog from reads in session 0) is deleted, and B-fault uses the S hook.

## Open

- S: serve proto3 (turret plant supplies `turret_analog`), then flip
  `SIM_PROTOCOL_VERSION` to 3.
- ftc-main: amend `protokol.md`.
- Debug bag (`SeamJson.hal`) does not record `analogVolts` yet.
