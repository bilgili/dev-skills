## Why

The spec-driven TLA+ (Temporal Logic of Actions) workflows accept the choices of their agents without a second opinion. Examples are the design-gate verdict and the optimizer SAFE or INTERFACE split. Jev, the TypeSafe judgment model, returns calibrated probabilities for a choice. This change lets the orchestrator weigh these choices with Jev and gives the user a record of each advice and its outcome.

## What Changes

- Add the skill `spec-driven-tla-jev`. It is a `SKILL.md` file only. It uses the `spec-driven-tla` installer without change and guides the orchestrator to weigh choices with Jev.
- Add the skill `spec-driven-tla-parallel-jev` with the same shape for `spec-driven-tla-parallel`.
- Add one canonical protocol file, `skills/_shared/jev-protocol.md`. Both skills refer to it.
- The orchestrator calls Jev through a Jev MCP (Model Context Protocol) tool from any server, such as mcpflow `jev_classify`, or else through the TypeSafe skill `typesafe:typesafe-ai`.
- The skills stop when no Jev route exists or a Jev call fails.
- The orchestrator owns user escalation and the decision log `openspec/changes/<change-id>/decisions.md`.
- The installed agents do not change. The skills add no installer scripts.
- Add a static check script for the skill files and the manifest.
- Register both skills in `.claude-plugin/marketplace.json`.
- The existing four skills do not change.

## Capabilities

### New Capabilities
- `jev-skill-invocation`: The orchestrator selects a Jev route (MCP tool first, TypeSafe skill second), frames each judgment as a Choice, and stops when no route exists or a call fails.
- `jev-decision-advice`: The orchestrator weighs choices with Jev at run time, escalates disagreements to the user, carries decisions into re-dispatches, and logs every Jev call.
- `jev-skill-variants`: The two `SKILL.md`-only sibling skills, the shared protocol file, the marketplace entries, and the static check.

### Modified Capabilities
- None.

## Impact

- New directories: `skills/spec-driven-tla-jev/`, `skills/spec-driven-tla-parallel-jev/`, `skills/_shared/`.
- New script: `scripts/check-jev-variants.sh`.
- Changed files: `.claude-plugin/marketplace.json` (two new skill paths, version bump) and `README.md`.
- Dependency at run time: one Jev route on the user machine (a Jev MCP server, or the `typesafe@typesafe-ai` plugin with a TypeSafe API key).
- Data leaves the machine: each Jev call sends an orchestrator-written brief to the TypeSafe service. The brief never contains secrets.
