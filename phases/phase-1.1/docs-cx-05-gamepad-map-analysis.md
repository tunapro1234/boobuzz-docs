# docs-cx-05 — Last season's gamepad maps → this season's Request set (analysis, read-only)

Read-only analysis of last season's robot code. Output: ONE file
`docs/phases/phase-1.1/gamepad-map-analysis.md` (English), commit + push on `stable`.
Do not edit any code. Do not touch protokol.md or design-spec.md.

Source: `/home/shared/projects/archive/ftc/de-cock/robot-code/TeamCode/src/main/java/org/firstinspires/ftc/teamcode/contingency/lvbelc5/`
(`teleop/`, `controllers/`, `engines/`, `Robot.java`, `ZoneHelper.java`; also `auto/AutoBuilder.java`
for the auto-side commands). If other packages under `teamcode/` contain teleop opmodes or
gamepad handling, include them and say where.

## Deliverable sections
1. **Button map table** per teleop opmode: gamepad (1/2), control (button/stick/trigger),
   edge type (press / hold / release / toggle), what it does, which robot method(s) it calls
   (file:line). Include reset, manual-mode / fallback / contingency switching, aiming
   overrides/offsets, tuning/settings changes at runtime, driver-relative vs field-relative.
2. **Shared input mechanics**: how edge detection / debounce / toggles were implemented
   (file:line), what deserves to become a common `controller/input` helper.
3. **Engine / mode switching**: what "contingency", manual mode, or engine swap existed,
   how it was triggered, what state carried over. Tuna wants mid-match engine switching.
4. **Subsystem-side tricks worth keeping**: motor-level tricks in shooter/intake/turret/feeder
   code (ramping, anti-jam reversal, hold power, rpm control, warmup) with file:line, one line each.
   Tuna's intent: subsystems may be written "dirty" from this code; upper layers stay clean.
5. **Proposed Request set for this season** derived from 1–3: a table of
   `RequestType` name, parameters, who issues it (gamepad / auto / RL), expected completion
   (instant / when-done / continuous), and which of last season's actions it replaces.
   Group: drive, shooting, offsets/aim overrides, settings/tuning, reset, mode/engine switch.
   Note explicitly which last-season actions should NOT become requests because the logic
   layer will do them automatically (e.g. turret always tracks the goal).
6. Open questions for Tuna (max 5).
