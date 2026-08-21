---
name: opsx_show_design
description: Reads an OpenSpec change's design (design.md, spec deltas, and its TLA+ model if present) and renders it as diagrams — architecture/component, sequence, and flow — using Claude Code's design skill. Use when the user wants to see, visualize, or diagram an OpenSpec change's design, asks for "design diagrams", "sequence diagrams", or "flow charts" for a change, or invokes /opsx_show_design.
---

# opsx: show design

Turns one OpenSpec change's design into diagrams, drawn by the `design`
skill (Claude Code's design canvas). It never authors a design — it draws
the one that already exists.

## What it reads

- `openspec/changes/<change-id>/design.md` — module boundaries, public
  interfaces, data flow. The primary source for the architecture diagram.
- `openspec/changes/<change-id>/proposal.md` — why the change exists, for
  diagram titles and captions.
- `openspec/changes/<change-id>/specs/<capability>/spec.md` — requirements
  and `#### Scenario:` (WHEN/THEN) blocks. Each scenario is a candidate
  sequence diagram: WHEN is the triggering call, THEN is the resulting
  messages between modules.
- `specs/tla/<change-id>.tla`, if present — `Init`, `Next`, and the state
  variables. The `Next` relation's disjuncts are candidate flow-chart
  branches or a state diagram's transitions.

## Procedure

1. Resolve `<change-id>`: use the one the user named. If none, run
   `openspec list` and ask which change.
2. Read every file above that exists for that change. A missing file is
   fine — diagram what is there.
3. Decide which diagrams the design supports:
   - **Architecture / component diagram** — draw one whenever `design.md`
     names more than one module, interface, or data contract.
   - **Sequence diagram** — draw one per primary scenario in the spec
     deltas. Skip a scenario with no cross-module interaction.
   - **Flow chart or state diagram** — draw one when the TLA+ model or
     `design.md` describes branching logic, a state machine, or a
     multi-step process.
4. Invoke the `design` skill to draft the diagrams as artboards on one
   canvas, so the user reviews them together. Seed each artboard's prompt
   with the relevant excerpt from step 3 only — a sequence diagram's prompt
   is its one scenario, not the whole spec file.
5. Title each artboard with the change and the diagram kind, for example
   "`<change-id>` — architecture" or "`<change-id>` — sequence:
   `<scenario name>`".
6. Report back which diagrams were drawn, and which candidate diagrams were
   skipped and why — for example, "no branching in the TLA+ model, so no
   flow chart." One sentence per diagram, in ASD-STE100.

## When there is nothing to diagram

If `design.md` does not exist for the change, say so and stop. Point to the
`spec-author` agent, or the `spec-driven-tla` / `spec-driven-tla-parallel`
skills, if the user wants a design authored first.

## Relation to spec-driven-tla and spec-driven-tla-parallel

Both workflows' Checkpoint 1 — right after the design gate approves and
interfaces FREEZE — dispatches this skill for `<change-id>` instead of
inlining its own diagram logic. Use it standalone too, for any OpenSpec
change, at any time, independent of that checkpoint.
