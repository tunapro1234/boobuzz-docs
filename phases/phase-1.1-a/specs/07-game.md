# F — a credible game world before calling the environment game-ready

> Superseded in parts by [review 2026-09-17](../review-ftc-main-specs-2026-09-17.md);
> known issues, revise after B09. Body retained, NOT a current work order.
> Read [v2 index](README.md) and [hardware-profile-v0](../hardware-profile-v0.md).
> Section5's match-state seam, multi-robot reuse and scoring/settlement findings are known issues. B01 now owns the early object-dimension slice needed by intake; this retained F chapter owns full game fidelity later.

Status: DRAFT, not dispatched. C01's minimal target geometry happens earlier; this
full-game work follows the useful engines. Apply [common gates](00-common.md).

## F01 — versioned rule/geometry inventory and fixtures

S implements; D maintains rule-to-test matrix; R reviews controller-visible data.
Pin official manual, Team Updates and CAD/drawings by URL/date/hash. Recheck latest
season sources at execution. A background image is not geometric authority, and
last year's game manual is not this season's specification.

Current source check: the manual identifies ~2.8-inch pollen, ~3.6-inch nectar and
40/8/8 pollen/red-nectar/blue-nectar match inventory. Its score table includes
20 per Hive tip, 2 per retained Cell element, 5 for bottom-nectar Flower bonus,
2 per element in an owned Flower and 1 per Garden element. Early Flower scoring
can still score while incurring a penalty. These facts need their exact conditions,
not just these numbers. [Official BIOBUZZ manual, §§9.8, 10.5](https://ftc-resources.firstinspires.org/ftc/archive/2027/game/cm-html/BIOBUZZ%20Competition%20Manual%20-%20V1.htm).

Matrix columns: rule/source/version, observable physical condition, clock boundary,
scorer state/event, penalty policy, fixture IDs, implementation status and limitation.
Cover field/body/target geometry; setup/preloads/human introduction; object counts;
match phases; leave/park; Hive/Flower/Garden; ownership and end-state scoring;
out-of-bounds/re-entry; robot interaction and judgment-dependent penalties.
Each condition has positive, negative and boundary fixtures. No unchecked "all rules"
claim: unimplemented material rules block full-game-ready status.

Our robot cannot ingest nectar. Other robots/human-player mechanisms can place it
where rules allow; full-world physics/scoring still models it. Pollen policy must
reason about ownership effects without controlling nectar. Controller input cannot
include private game facts unavailable on the real field; truth stays in evaluator.

Exit: dimensions/constants file with provenance, matrix with no unspecified critical
scoring condition, fixture expectations independently calculated from cited rules.
Rules remain replaceable data where simple; do not build a general rules language.

## F02 — one Hive, then complete field mechanics

S implements one-axis Hive dynamics: angle/rate, mass/inertia approximation, gravity
torque from retained elements and mechanism geometry, damping, stable limits, finite
tip motion and load redistribution/ejection. Compute moment from mass and location,
not a magic global ball-count threshold. Without physical mass/friction evidence,
label a bounded surrogate and publish a parameter sweep; do not claim precise
tipping calibration. Pollen and nectar have distinct physical parameters.

Tip detection is a debounced state transition reaching the prescribed stable/contact
condition, not every oscillation or crossing of an arbitrary central angle. Moving
geometry changes collisions, camera occlusion and valid shooting openings. Use
height-aware contact with C03 flight. If the 2.5D approximation fails a required
fixture, document the smallest alternative before considering full 3D expansion.

Tests: empty stability, symmetric loading, off-center load, near-threshold disturbance,
single versus multiple arrivals, partial spill, reverse tip, simultaneous contact,
dt-halving, no energy explosion and object conservation. Separate physical tip event
from scoring attribution. Then add remaining structures using F01 geometry and
contact rules; avoid a second ball-motion implementation for each target.
Exit: mechanics demo, tip/load sensitivity report and explicit unmeasured constants.

## F03 — clock, score ledger and referee approximations

S implements a deterministic match state machine using sourced durations and phase
transitions. Freeze actions appropriately during disabled intervals; do not compress
transition time accidentally. Separate match clock, simulation clock and wall clock.
The current manual specifies 30 s AUTO, 8 s transition and 120 s TELEOP; pin that
version and recheck updates. Four pollen preloads per robot are starting contacts,
not proof of four-ball internal capacity. These belong in setup fixtures.
Unit-test every boundary just before/at/after and command legality in each state.

Scorer consumes physical state/events and a rule version, never controller intents.
Use unique event IDs and deduplication. Distinguish cumulative achievements from
end-of-period/end-of-match occupancy snapshots; removing an element must affect
provisional occupancy score correctly without undoing genuine earned events.
Publish an event ledger and independently recompute final totals from recorded
snapshots/events. Reset eliminates all former credits, penalties and object ownership.

Implement ownership changes, late landing after clock boundary, contested occupancy,
early prohibited-but-still-scoring actions and sourced foul attribution. Judgment
rules need a named deterministic proxy or explicit unsupported status; no hidden
"perfect referee". Penalty points go to the correct side, not arbitrarily subtracted
from the offending robot twice. Ranking points are separate from match points.

Tests use hand-calculated golden matches, including no scoring, one of each scoring
case, each boundary, removals/ownership changes, fouls and duplicate events. Exit:
every material supported rule has an independent fixture and reproducible ledger.

## F04 — full matches and completeness gate

S runs scripted multi-robot scenarios with physical opponents/partner and seeded
sensors; R runs actual Java engines for our robot. Other robots may use simple legal
scripts, not trained opponents. Include pollen collection loops, nectar placement by
others, repeated tips, misses, blocked intake, defender crossings, occlusion, empty
resources, final park and complete reset. No action produces points by API shortcut.

Required checks: fixed-seed transcript equality; object conservation including
off-field/stored/contained states; valid phase/score ledger; no queue growth or NaNs;
20 full matches under varied seeds with no crash; reset after each phase/fault;
no cross-instance state leakage. Publish wall time separately from simulated time.
Cross-review scorer logic independently from physics and robot code.

Exit: signed-off coverage matrix, compatible release manifest, known approximation
envelope and golden full-match suite. Unsupported important strategy/rule interaction
means "partial-game environment", not full-game RL-ready. Existing engines remain
usable even if this difficult fidelity gate needs another small iteration.
