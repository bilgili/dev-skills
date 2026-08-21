---
name: opsx_show_design
description: Reads an OpenSpec change's design (design.md, spec deltas, and its TLA+ model if present) and publishes it as a technical HTML page with inline SVG diagrams — architecture/component, sequence, and flow or state. Use when the user wants to see, visualize, or diagram an OpenSpec change's design, asks for "design diagrams", "sequence diagrams", or "flow charts" for a change, or invokes /opsx_show_design.
---

# opsx: show design

Turns one OpenSpec change's design into a technical design-review document,
published as a self-contained HTML Artifact with inline SVG diagrams. Each
diagram states which technical persona uses it and for what — the
implementer, a reviewer, an on-call operator, a downstream system, whoever
the design actually gives a real use to. It never authors a design, and it
never credits a persona with a use the design does not support.

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
4. For each diagram, name the technical personas it actually serves and the
   concrete use each makes of it — ground every pairing in the design, do
   not pad the list with a role that has no real use for that diagram:
   - **Implementer** — which diagram they code straight from (the sequence
     diagram's call order, the state diagram's guards) and which frozen
     contract they must not deviate from.
   - **Reviewer / design-gate** — which diagram lets them check a PR or a
     proposal against the frozen boundary without reading the whole diff.
   - **On-call operator** — only when a flow or state diagram exists: which
     diagram they match a stuck or failing system's current state against,
     and which edge is the recovery transition.
   - **Downstream / consuming system** — only when `design.md` names a
     caller outside this change: which diagram is that caller's integration
     contract — the exact signature or message shape they code to.
   - **Verifier** — which sequence diagram's steps become its spec-derived
     test assertions.
   - **Future maintainer** — which diagram is the fastest path to
     understanding the seam before touching it again.
   Skip any persona the design gives no real diagram to use.
5. Before writing anything, load the `artifact-design` skill and the
   `artifact-diagramming` skill — both are mandatory for hand-authored SVG
   in a published Artifact, and `artifact-design` governs the HTML/CSS
   itself.
6. Draft one self-contained HTML page:
   - Header: `<change-id>`, a one-paragraph scope (from `proposal.md`,
     ASD-STE100), whether interfaces are FROZEN, and a **Who this helps**
     list — every technical persona from step 4, each with the one-line use
     it makes of a named diagram.
   - Each diagram as inline SVG, theme-aware (CSS custom properties, not
     hardcoded hex — light and dark both legible), in its own
     `overflow-x: auto` container if wide. One technical caption paragraph
     per diagram, ASD-STE100, stating the seam or contract it shows AND
     which persona uses it for what — not a restatement of its shape.
   - A **Frozen interfaces** table: every public signature, data contract,
     and error semantic from `design.md`, verbatim.
   - An **Invariants** list: every `INVARIANT`/`PROPERTY` from the `.cfg`,
     verbatim, if the file exists.
   - Pick a favicon fitting a blueprint/architecture document (for example
     📐 or 🏗️) and keep it stable across re-runs for the same change.
7. Publish with the Artifact tool. Title the artifact "`<change-id>` —
   design."
8. Report back: the artifact link, the persona list from step 4 with each
   one's use, one sentence per diagram drawn (ASD-STE100), and which
   candidate diagrams were skipped and why — for example, "no branching in
   the TLA+ model, so no flow chart."

## When there is nothing to diagram

If `design.md` does not exist for the change, say so and stop. Point to the
`spec-author` agent, or the `spec-driven-tla` / `spec-driven-tla-parallel`
skills, if the user wants a design authored first.

## Relation to opsx_show_user_flows

Both read the same OpenSpec change and both publish an HTML Artifact with
inline SVG, but for different readers. This skill diagrams the system for
technical personas — implementer, reviewer, on-call operator, downstream
system, verifier, maintainer — with the frozen contracts and invariants in
view. [`opsx_show_user_flows`](../opsx_show_user_flows) diagrams the
experience for everyone the system touches — end users, operators,
IT/infrastructure, support — with no engineering internals in view. Run
either independently, or both for a change that needs a technical and a
product review.

## Relation to spec-driven-tla and spec-driven-tla-parallel

Both workflows' Checkpoint 1 — right after the design gate approves and
interfaces FREEZE — dispatches this skill for `<change-id>` instead of
inlining diagram logic of its own. Use it standalone too, for any OpenSpec
change, at any time, independent of that checkpoint.
