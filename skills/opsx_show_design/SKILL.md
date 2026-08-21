---
name: opsx_show_design
description: Reads an OpenSpec change's design (design.md, spec deltas, and its TLA+ model if present) and publishes it as a technical HTML page with inline SVG diagrams — architecture/component, sequence, and flow or state. Use when the user wants to see, visualize, or diagram an OpenSpec change's design, asks for "design diagrams", "sequence diagrams", or "flow charts" for a change, or invokes /opsx_show_design.
---

# opsx: show design

Turns one OpenSpec change's design into a technical design-review document,
published as a self-contained HTML Artifact with inline SVG diagrams. It
never authors a design — it draws the one that already exists.

## Persona

You act as a Principal Software Architect producing a design-review document
for senior and mid-level engineers. The reader knows the domain — do not
explain basic concepts, do not soften technical terms, do not caption a
diagram with a summary a reader could get from its shape alone. Prefer the
literal identifier from the source documents over a generic placeholder:
a node is named `FetchClient`, not "the client module"; an edge is labeled
`retryWithBackoff(cfg: RetryConfig): Response`, not "calls the service."
Precision over polish.

## What it reads

- `openspec/changes/<change-id>/design.md` — module boundaries, public
  interfaces, data flow. The primary source for the architecture diagram and
  the frozen-interfaces table.
- `openspec/changes/<change-id>/proposal.md` — why the change exists, for
  the document's scope paragraph.
- `openspec/changes/<change-id>/specs/<capability>/spec.md` — requirements
  and `#### Scenario:` (WHEN/THEN) blocks. Each scenario with real
  cross-module interaction is a sequence diagram: WHEN is the triggering
  call, THEN is the resulting messages between modules.
- `specs/tla/<change-id>.tla` and `specs/tla/<change-id>.cfg`, if present —
  `Init`, `Next`, the state variables, and the `INVARIANT`/`PROPERTY` set.
  The `Next` relation's disjuncts are the flow chart's or state diagram's
  transitions; the `.cfg`'s properties are the invariants panel.

Extract literal identifiers — module names, function signatures, data
contract shapes, error types, TLA+ variable and action names. Do not
paraphrase or genericize them; the diagram is a contract reference, not an
illustration.

## Procedure

1. Resolve `<change-id>`: use the one the user named. If none, run
   `openspec list` and ask which change.
2. Read every file above that exists for that change. A missing file is
   fine — diagram what is there; note what is missing in the final report.
3. Decide which diagrams the design supports:
   - **Architecture / component diagram** — draw one whenever `design.md`
     names more than one module, interface, or data contract. Nodes carry
     the module name and its exposed signature(s); edges carry the literal
     data contract or message type crossing that seam, not "calls" or
     "uses."
   - **Sequence diagram** — one per scenario with real cross-module
     interaction. Participants are the actual modules or actors. Messages
     are the literal calls the WHEN/THEN implies, in order, with a guard or
     alt block for an error path the scenario states. Note the requirement
     id (`Requirement: R2`) the scenario traces to.
   - **Flow chart or state diagram** — draw one when the TLA+ model or
     `design.md` describes branching logic, a state machine, or a
     multi-step process. Nodes are `Init` and each `Next` disjunct, labeled
     with its actual action name and enabling guard, not a paraphrase.
4. Before writing anything, load the `artifact-design` skill and the
   `artifact-diagramming` skill — both are mandatory for hand-authored SVG
   in a published Artifact, and `artifact-design` governs the HTML/CSS
   itself.
5. Draft one self-contained HTML page:
   - Header: `<change-id>`, a one-paragraph scope (from `proposal.md`,
     ASD-STE100), and whether interfaces are FROZEN.
   - Each diagram as inline SVG, theme-aware (CSS custom properties, not
     hardcoded hex — light and dark both legible), in its own
     `overflow-x: auto` container if wide. One technical caption paragraph
     per diagram, ASD-STE100, stating the seam or contract it shows — not a
     restatement of its shape.
   - A **Frozen interfaces** table: every public signature, data contract,
     and error semantic from `design.md`, verbatim.
   - An **Invariants** list: every `INVARIANT`/`PROPERTY` from the `.cfg`,
     verbatim, if the file exists.
   - Pick a favicon fitting a blueprint/architecture document (for example
     📐 or 🏗️) and keep it stable across re-runs for the same change.
6. Publish with the Artifact tool. Title the artifact "`<change-id>` —
   design."
7. Report back: the artifact link, one sentence per diagram drawn (ASD-STE100),
   and which candidate diagrams were skipped and why — for example, "no
   branching in the TLA+ model, so no flow chart."

## When there is nothing to diagram

If `design.md` does not exist for the change, say so and stop. Point to the
`spec-author` agent, or the `spec-driven-tla` / `spec-driven-tla-parallel`
skills, if the user wants a design authored first.

## Relation to spec-driven-tla and spec-driven-tla-parallel

Both workflows' Checkpoint 1 — right after the design gate approves and
interfaces FREEZE — dispatches this skill for `<change-id>` instead of
inlining diagram logic of its own. Use it standalone too, for any OpenSpec
change, at any time, independent of that checkpoint.
