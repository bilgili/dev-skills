---
name: spec-driven-tla-parallel-jev
description: >-
  Use the spec-driven-tla-parallel workflow with Jev advice via a Jev MCP tool or typesafe:typesafe-ai.
  The main-session orchestrator weighs choices and handles user escalation.
  Supports macOS, Linux, and Windows.
---

# spec-driven-tla-parallel with Jev advice

Jev is the TypeSafe judgment model.
TLA+ means Temporal Logic of Actions.
This directory contains only `SKILL.md`.
The base skill owns installation and the workflow.

## Step 0: Check for a Jev route

Check the current session for at least one Jev route:

- A Model Context Protocol (MCP) tool from any server that asks Jev a choice question, such as mcpflow `jev_classify`.
- The skill `typesafe:typesafe-ai`.

Find MCP tools by a name or description that names Jev or TypeSafe.
If no route exists, show these commands:

```sh
claude plugin marketplace add typesafe-ai/skills
claude plugin install typesafe@typesafe-ai
```

Stop before the base install when no route exists.
Do not call Jev to check availability.
[The shared Jev protocol](../_shared/jev-protocol.md) sets the route order.

## Step 1: Run the base installer

Read [the base skill](../spec-driven-tla-parallel/SKILL.md).
Run its documented installer command from the target project root for the current operating system.
Use only the path substitution and target argument that the base skill documents.
Keep this directory beside `../spec-driven-tla-parallel/` and `../_shared/`.
Do not change the installed agents or their tool permissions.

## Step 2: Run the base workflow

Run the workflow as the main-session orchestrator, as [the base skill](../spec-driven-tla-parallel/SKILL.md) directs.
Keep its phase gates and user checkpoints.
Read [the shared Jev protocol](../_shared/jev-protocol.md).
Apply that protocol throughout the workflow.

## Agent workflow

```
 Step 0   Jev route?  (Jev MCP tool │ typesafe:typesafe-ai)
             │ yes                         └── none ─▶ STOP, show install commands
             ▼
 Step 1   base installer  (install.sh │ install.ps1)   agents stay unchanged
             │
             ▼
 Step 2   base workflow; the main-session orchestrator weighs at ◆

spec-author → design-gate ⇄ tla-checker
      │ ◆ APPROVE / REJECT
      ▼ interfaces FROZEN
CHECKPOINT 1 — user decides: opsx_show_design and/or opsx_show_user_flows?
      │
      ▼
task-planner → tasks.md (groups tagged Files: / Depends on:)
      │
      ▼
CHECKPOINT 2 — user decides: continue to implementation?
      │
      ▼
implementation-orchestrator (Plan)
      │  ◆ batch composition: which ready groups run together?
      ▼
main session dispatches implementer × N — ONE message, concurrent
      │
      ├─ group DONE ─────────────────────┐
      └─ group STOPS ─┐                  ▼
                      │   implementation-orchestrator (Integrate)
                      │    merges DONE worktrees, checks off tasks.md
                      ▼
          ◆ stop: safe fix, re-scope, or new spec?
          (one user question for all disagreements of the wave)
      │
      ▼ (repeat Plan → dispatch → Integrate until every group is checked)
verifier ◆ tests match the spec? → green → openspec archive
      ▼ (post-archive, advisory)
optimizer ◆ SAFE → implementer (safe loop) · INTERFACE → spec-author

 ◆  The orchestrator may weigh the returned decision with Jev.
    It weighs by runtime judgment, not from a fixed list; ◆ marks typical points.
    Subagents, including the implementation-orchestrator, never call Jev.
    Checkpoints stay user decisions.
    Each ◆ runs the decision loop in the shared protocol.
    Every Jev call goes to decisions.md in the current change directory.
```
