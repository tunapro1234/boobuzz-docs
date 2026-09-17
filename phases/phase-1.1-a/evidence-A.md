# Chapter A evidence ledger

Status: **open, documentation-only.** This is the sole Chapter A evidence file.
It records approved pins, task slots, commands and limitations; an empty result is
not a passing result. No implementation or acceptance outcome is claimed here.

## Pinned inputs

| Repository / source | Branch | Pin | Role |
|---|---|---|---|
| docs | `dev-phase-1.1-a` | `e5796b7c1b005d4c1559d5339621c99080de0903` | v2.2 docs entry |
| robot-code (R) | `dev-phase-1.1-a` | `d5bda622d5bba6dfef6c4bfefed69e0cc20d7e67` | Java core, FTC adapter, Java sim |
| re-cock-nize (S) | `dev-phase-1.1-a` | `5dd6daacedbd629deb0827b36240f3064a808f3b` | Python server, physics and tests |
| archive (OLD) | archived source | `d7711d043280034ab5c75ae26a253629fd2d4a7b` | behavior/calibration provenance |

The protected `protokol.md` and `phases/phase-1.1/design-spec.md` are read-only.
R and S source are read-only for this documentation checkpoint. A source pin is
not a test result; later entries must name the exact command and artifact.

## Approved Chapter A slots

| Slot | Owner / seam | Planned evidence | State |
|---|---|---|---|
| A00 | D release cleanup | fixed-prefix retirement, English-content rule, ADR/evidence paths | **Recorded in this docs increment; no implementation outcome** |
| A01 | S transport/events | bounded fragmented I/O, integral millisecond events, no mixed-world advance | **Not started; no outcome recorded** |
| A02.0 | D + ftc-main protocol owner | `adr-device-seam-v2.md`; protected protocol amendment gate | **ADR draft recorded; approval pending** |
| A02 | R/S mass seam + R regression | Java-source mass parsing, 18 kg isolated fixture, cancellation/deadband tests | **Not started; no outcome recorded** |
| A03 | R/S e2e seam | two fixed Pymunk scenarios and JSONL traces | **Not started; no outcome recorded** |
| A04 | R analysis + D evidence | extension of predecessor gamepad/request evidence with archive file:line handoff | **Blocked pending ftc-watchdog source-grounded handoff** |
| A05 | R + D checkpoint | registry/order fixtures, A-drive/A-cancel gate, chapter manifest/tag only after approval | **Not started; no tag** |

## A00/A02 documentation record

- `00-common.md` now retains the English-content rule but no fixed message prefix.
- `adr-device-seam-v2.md` distinguishes current proto1 zero-fill from proposed
  proto2 positional-servo hold, keeps DC/CR omission at zero, lists paired devices,
  units, ownership and validation, and blocks code until ftc-main approves the
  protected protocol amendment.
- A02's planned Java-source reader rule requires a finite positive
  `ROBOT_MASS_KG` in kg, clear missing/invalid failure, and an isolated 18 kg body/
  inertia fixture. These are requirements for a future task, not completed tests.

## Commands and outcomes

| Check | Command / artifact | Outcome |
|---|---|---|
| Documentation diff | `git diff --check` | Pending until this increment is committed |
| Mass parser | named A02 isolated fixture | Not run; no implementation dispatched |
| Protocol fixture | proto1/proto2 paired golden frames | Not run; protected amendment pending |
| Chapter A e2e | A03 runner and two Pymunk scenarios | Not run; A03 not started |

Prior robot/simulator reports remain provenance references, not new Chapter A
outcomes. Their test counts and smoke results must not be copied into this ledger as
fresh evidence.

## A04 handoff gate

Do not add A04 findings until ftc-watchdog supplies a source-grounded handoff with
the predecessor files, archive paths/lines, and the corrected-vs-deferred boundary.
Once received, append only verified facts and link the handoff; do not invent a
golden trace or claim a controller behavior from the task text alone.

## Safety and publication boundary

No code, protocol, tag, reviewer, ball, training or phase change is authorized by
this ledger. The proto2 decision, paired fixtures, and A02 mass proof remain review
gates. Future evidence must separate `unit-tested`, `sim-integrated`,
`Android-built`, `archive-derived`, and `hardware-validated`; the last label remains
absent until a physical robot is available.
