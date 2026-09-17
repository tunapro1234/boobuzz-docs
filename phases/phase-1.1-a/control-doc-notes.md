# Notes for the eventual control document

These notes preserve Tuna's handover intent while the implementation-planning
hold remains active. They are not an implementation order and do not amend the
protected historical specifications.

## Working structure

- The working labels are **Astra/Fable orchestrator** above **Luna Max**
  robot-code, simulator, and docs workers.
- Tasks and goals stay bounded. Robot and simulator work is cross-reviewed in
  both directions before an acceptance claim.
- Completed steps report the commit, push, hash, and any accepted-step tag;
  tags and acceptance remain approval-gated.
- Tuna retains approval authority for control-document content, acceptance, and
  scope. These are user-named model/role labels, not an independently verified
  product identity or a fixed requirement that both orchestrators run at once.

## Robot and simulator scope

- The intake collects **small POLLEN balls only**; it must never collect NECTAR.
- The full-field simulator still represents NECTAR and the rule effects that
  depend on it, even though the robot intake does not collect it.

## Current guard

This note is documentation-only. Do not start implementation, distribute tasks,
launch agents, train models, or edit protected historical specs. Tuna's separate
draft specifications are for Tuna's review and are not work orders for this
agent.
