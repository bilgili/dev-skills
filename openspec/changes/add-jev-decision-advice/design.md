## Context

The skills `spec-driven-tla` and `spec-driven-tla-parallel` install agent files into a target project. The main session acts as the orchestrator. It dispatches subagents and reads their results.

Each installed agent file has an explicit `tools:` allowlist. Subagents cannot ask the user a question.

Jev is the TypeSafe judgment model. The plugin `typesafe@typesafe-ai` provides the skill `typesafe:typesafe-ai`. That skill does not call Jev itself. It guides the caller to frame a judgment as a Choice, a Noul, or a Score, and it points to the live API documentation for the call. A Choice answer holds option probabilities and a confidence value.

The source requirements are in `.omc/specs/deep-interview-jev-decision-advice.md`. The user later replaced runtime channel discovery and the installer layer with a direct invocation of the TypeSafe skill by name.

## Goals / Non-Goals

**Goals:**
- Two sibling skills that use the base workflows and add Jev advice.
- One source for the protocol text.
- One owner for every Jev call: the orchestrator.
- A decision log with one entry per Jev call and no pending entries.

**Non-Goals:**
- JEV siblings for `opsx_show_design` and `opsx_show_user_flows`.
- Jev as the final decision maker.
- A fixed list of decision points.
- Channel discovery by subagents or by an installer.
- Installer scripts, edits to installed agents, or tool grants.
- A mode that runs without Jev.
- User-configurable thresholds.
- A live Jev call in the static check.

## Decisions

### D1. A JEV skill is a SKILL.md only
Each sibling holds `SKILL.md` and nothing else. It checks for the TypeSafe skill, then runs the base installer command without change. It then guides the orchestrator.
- Alternative: a sibling installer that splices the protocol into agents. Rejected by the user: no separate install script.
- Trade-off: the sibling depends on the base skill directory beside it. Both ship in one plugin.

### D2. One protocol source, read at run time
`skills/_shared/jev-protocol.md` holds the protocol. Both `SKILL.md` files link it. The orchestrator reads it when it uses the skill.
- Alternative: copy the protocol into each `SKILL.md`. Rejected: the two copies drift.

### D3. The orchestrator is the only Jev caller
Subagents do not call Jev. The orchestrator weighs the decisions that subagents return, and its own routing choices.
- Alternative: every agent calls Jev. Rejected: that needs edits to installed agents and tool grants, which the user rejected.
- Trade-off: Jev sees only what a result carries. A choice inside a subagent that the result does not expose is not weighed.

### D4. Select one Jev route per run
Before its first Jev call, the orchestrator selects the first available route: an MCP (Model Context Protocol) tool from any server that asks Jev a choice question, else the TypeSafe HTTP API through `typesafe:typesafe-ai`. It finds MCP routes by name or description and keeps the route for the run. The TypeSafe skill stays the framing guide.
- Why this is cheap now: only the orchestrator calls Jev, and the main session has every MCP tool. No agent file or tool grant changes.
- Alternative: the TypeSafe skill only. Rejected by the user: MCP servers such as mcpflow also provide Jev.
- Trade-off: a light runtime lookup of the orchestrator's own tools. No installer and no discovery by subagents.

### D5. Frame each weighed choice as a Choice
The orchestrator asks a Choice among the candidate options. The state holds the decision brief. The Choice confidence feeds the fixed thresholds: `act` at 0.8 or more, `review` at 0.5 or more, `abstain` below 0.5.
- Alternative: a Noul for yes-or-no choices. Rejected: a Noul returns a probability and no confidence, so the thresholds do not apply.

### D6. Escalation goes to the user through the orchestrator
If Jev answers `act` or `review` for an option other than the current pick, the orchestrator asks the user. It batches the disagreements of one wave into one question. On `abstain`, the pick stands.

### D7. The orchestrator is the single writer of the decision log
The orchestrator appends to `openspec/changes/<change-id>/decisions.md`. It logs an escalated call after the user answers, or as `unresolved` when the workflow stops first. It logs before it re-dispatches, finishes, or stops.

### D8. Failure stops the workflow
If no route exists (no Jev MCP tool and no `typesafe:typesafe-ai`), the JEV skill stops before the base install. If a Jev call fails, the orchestrator logs `channel-failed` and stops. It tells the user to check the selected route and its credentials.

### D9. A re-dispatch carries settled decisions forward
When the user overrides a subagent decision, the orchestrator re-dispatches the subagent with the user decision. It passes every settled decision to later dispatches. It does not weigh a settled decision again.

## Risks / Trade-offs

- [The orchestrator never asks Jev] → The runtime rule cannot force a call. The log shows the call count per change.
- [A brief leaks a secret] → The protocol forbids secrets. The orchestrator writes the brief itself.
- [The API key leaks] → The key stays in the environment. It never goes into a brief or a log entry.
- [The TypeSafe API changes] → The orchestrator reads the live documentation through the skill. It does not hard-code the call.
- [A subagent hides a choice] → D3 accepts this limit.

## Migration Plan

- The change adds files only. Existing installs of the base skills do not change.
- Rollback: remove the two sibling directories, `skills/_shared/`, and the two manifest entries.

## Open Questions

- None.
