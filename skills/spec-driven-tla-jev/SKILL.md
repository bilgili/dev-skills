---
name: spec-driven-tla-jev
description: >-
  Use the spec-driven-tla workflow with Jev advice via a Jev MCP tool or typesafe:typesafe-ai.
  The main-session orchestrator weighs choices and handles user escalation.
  Supports macOS, Linux, and Windows.
---

# spec-driven-tla with Jev advice

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

Read [the base skill](../spec-driven-tla/SKILL.md).
Run its documented installer command from the target project root for the current operating system.
Use only the path substitution and target argument that the base skill documents.
Keep this directory beside `../spec-driven-tla/` and `../_shared/`.
Do not change the installed agents or their tool permissions.

## Step 2: Run the base workflow

Run the workflow as the main-session orchestrator, as [the base skill](../spec-driven-tla/SKILL.md) directs.
Keep its phase gates and user checkpoints.
Read [the shared Jev protocol](../_shared/jev-protocol.md).
Apply that protocol throughout the workflow.
