## Jev decision advice

Jev is the TypeSafe judgment model.
Only the main-session orchestrator calls Jev and writes the decision log.
Subagents return their decisions through the base workflow.
The parallel implementation-orchestrator is a subagent for these rules.
The base skill owns installation, agent files, tool permissions, and workflow gates.

### Select and frame a choice

1. Weigh a choice when your runtime judgment requires advice.
2. Consider decisions in subagent results and your own routing choices.
3. Do not use a fixed list of decision points.
4. Check the settled decisions before each call.
5. Never weigh a settled decision again.
6. Use `typesafe:typesafe-ai` for framing guidance when it is available.
7. Select the call route before the first Jev call in each workflow run.
8. Keep the same route for the whole run.

The TypeSafe skill provides guidance; the orchestrator makes the call.
Select the first route that is available in the current session:

| Order | Route | Use |
| --- | --- | --- |
| 1 | A Model Context Protocol (MCP) tool that asks Jev a choice question, from any server | Example: mcpflow `jev_classify`. Pass `act_above` 0.8 and `review_above` 0.5. Set `add_none` to false. |
| 2 | The TypeSafe HTTP API | Follow `typesafe:typesafe-ai` and its live documentation. |

Find MCP routes by tool name or description that names Jev or TypeSafe.
Do not hard-code one server.
Use a batch tool, such as mcpflow `jev_ask`, for several independent choices over the same state.

1. Write a decision brief with the question, candidate options, current pick, and key evidence.
2. Include relevant excerpts from the specification, design, code, or subagent result when necessary.
3. Exclude secrets, credentials, tokens, and environment-file contents from the brief.
4. Keep the application programming interface (API) key in the environment.
5. Never put the API key in a brief or log entry.
6. Frame each judgment as a TypeSafe Choice among the candidate options.
7. Put the decision brief in the Choice state.
8. Use the Choice confidence for the threshold mapping.

### Apply the answer

Map the Choice confidence to these fixed actions:

| Confidence | Jev action |
| --- | --- |
| At least 0.8 | `act` |
| At least 0.5 and below 0.8 | `review` |
| Below 0.5 | `abstain` |

Do not change these thresholds.
Jev provides advice.
The current pick stands unless the user overrides it.

1. Keep the current pick on `abstain`.
2. Continue without escalation when Jev agrees with the current pick.
3. Escalate when Jev selects another option with `act` or `review`.
4. Batch all disagreements from one wave into one user question.
5. Include disagreements about your own routing choices in that question.
6. Present each brief, Jev answer, and current pick to the user.
7. Ask the user to choose an option for each disagreement.
8. Wait for the user answer before continuing the affected work.

### Record each call

Only the main-session orchestrator appends to `decisions.md` in the current change directory.
Subagents never write this log.
Before the archive, the change directory is `openspec/changes/<change-id>/`.
`openspec archive` moves the directory and its log to `openspec/changes/archive/<date>-<change-id>/`.
After the archive, append to the log in the archived directory.
Never create a second log for the same change.

1. Append one entry for each Jev call, including each failed call.
2. Append each entry exactly once.
3. Use `caller` as the escalation outcome when the current pick stands without escalation.
4. Hold an escalated entry until the user answers.
5. After the answer, append that entry with outcome `user` and the user choice.
6. If the workflow stops first, append that entry with outcome `unresolved`.
7. Never append an entry without an outcome.
8. Log all calls before you re-dispatch, finish, or stop.

### Carry settled decisions forward

1. Retain each settled decision with its question and choice.
2. After an override, re-dispatch the affected subagent with the user decision.
3. Pass every settled decision to later dispatches.
4. Keep settled decisions when a subagent crashes.
5. Do not weigh those decisions again after a re-dispatch.

### Stop on failure

Each sibling checks for at least one route before the base install.
A route is a Jev MCP tool or the `typesafe:typesafe-ai` skill.
When no route exists, the sibling stops before installation.
The sibling shows the TypeSafe plugin install commands.

1. On a Jev call failure, append the failed call with outcome `channel-failed`.
2. Use `unavailable` for answer fields that the failed call cannot supply.
3. Append all waiting escalations with outcome `unresolved`.
4. Exclude credentials from failure details and log entries.
5. Tell the user to check the selected route and its credentials.
6. Stop the workflow after the log writes.

### Log entry fields

Use these fields for each call entry:

| Field | Content |
| --- | --- |
| caller | Main-session orchestrator and the decision or dispatch identifier. |
| brief | Question, candidate options, current pick, and key evidence sent to Jev. |
| options | Candidate options sent to Jev. |
| probabilities | Jev probability for each option. |
| confidence | Choice confidence value. |
| Jev action | `act`, `review`, or `abstain`, from the fixed thresholds. |
| current pick | The choice before Jev advice and any user override. |
| escalation outcome | `caller`, `user` with the user choice, `unresolved`, or `channel-failed`. |

### Decision loop

```
 subagent result, or own routing choice  (holds the current pick)
        │
        ▼
 needs weighting? ──── no ────────────────▶ continue with current pick
        │ yes
        ▼
 already settled? ──── yes ───────────────▶ use the settled decision
        │ no
        ▼
 decision brief ─▶ route: 1. Jev MCP tool  2. TypeSafe HTTP API
        │                         │
        │                         └─ call fails ─▶ log channel-failed,
        │                                          log waiting as unresolved,
        ▼                                          STOP (check route)
 Jev Choice ─▶ confidence: act ≥ 0.8 │ review ≥ 0.5 │ abstain < 0.5
        │
        ├─ abstain, or Jev agrees ─▶ log (caller) ─▶ continue with current pick
        │
        └─ act / review for another option
                 │
                 ▼
          batch with the other disagreements of this wave
                 │
                 ▼
          ask the user ─▶ log (user) ─▶ settle the decision
                 │
                 ▼
          user overrode a subagent? ─▶ re-dispatch it with every
                                       settled decision
```
