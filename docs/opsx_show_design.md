# opsx_show_design

Skill: [`skills/opsx_show_design`](../skills/opsx_show_design). A plain
instruction skill — no sub-agents, no installer. It publishes a design
document for an OpenSpec change's existing design; it never authors one.

## Persona

It acts as a Principal Software Architect producing a design-review document
for senior and mid-level engineers. It assumes the reader knows the domain,
never softens a technical term, and never captions a diagram with what its
shape already shows. It uses the literal identifiers from the source
documents — a node is `FetchClient`, not "the client module"; an edge is
`retryWithBackoff(cfg: RetryConfig): Response`, not "calls the service."

## What it does

1. Resolves `<change-id>` — the one named, or asks after `openspec list`.
2. Reads whatever exists of: `design.md` (module boundaries, interfaces,
   data flow), `proposal.md` (why, for the scope paragraph), the spec
   deltas' `#### Scenario:` blocks (WHEN/THEN — one candidate sequence
   diagram each), and `specs/tla/<change-id>.tla` plus its `.cfg` if
   present (`Init`/`Next` for a flow chart or state diagram, the
   `INVARIANT`/`PROPERTY` set for the invariants panel).
3. Picks the diagrams the design actually supports: an architecture diagram
   whenever more than one module or interface is named, one sequence
   diagram per scenario with real cross-module interaction, and a flow
   chart or state diagram when there is branching logic to show.
4. Loads the `artifact-design` and `artifact-diagramming` skills, then
   hand-authors one self-contained HTML page: a scope header, each diagram
   as theme-aware inline SVG (CSS custom properties, not hardcoded hex)
   with a technical caption, a **Frozen interfaces** table pulled verbatim
   from `design.md`, and an **Invariants** list pulled verbatim from the
   `.cfg`.
5. Publishes it with the Artifact tool, titled "`<change-id>` — design."
6. Reports back the artifact link, one sentence per diagram drawn, and
   which candidate diagrams were skipped and why.

If `design.md` does not exist yet, it says so and stops, pointing to
`spec-author` (or the `spec-driven-tla` / `spec-driven-tla-parallel`
skills) to author a design first.

## Why HTML and inline SVG, not a design canvas

The output is a reference document engineers read and cite, not a mockup
they iterate on visually. A published Artifact with inline SVG keeps every
diagram, its caption, and the frozen-interfaces table in one static,
linkable page — no editor session, no artboards to arrange.

## Relation to spec-driven-tla and spec-driven-tla-parallel

Both workflows' **Checkpoint 1** — right after the design gate approves and
interfaces FREEZE — dispatches this skill for `<change-id>` instead of
inlining diagram logic of its own. That is the one place this skill's
output is required reading; every other use is standalone, for any
OpenSpec change, at any time.

## See also

- [spec-driven-tla](spec-driven-tla.md) and
  [spec-driven-tla-parallel](spec-driven-tla-parallel.md) — the workflows
  whose Checkpoint 1 calls this skill.
- [OpenSpec](openspec.md) — where `design.md`, spec deltas, and
  `change-id`s come from.
- [TLA+](tla-plus.md) — what `Init`/`Next` model, read here for flow-chart
  and state-diagram source material.
