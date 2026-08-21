# opsx_show_design

Skill: [`skills/opsx_show_design`](../skills/opsx_show_design). A plain
instruction skill — no sub-agents, no installer. It draws diagrams for an
OpenSpec change's existing design; it never authors one.

## What it does

1. Resolves `<change-id>` — the one named, or asks after `openspec list`.
2. Reads whatever exists of: `design.md` (module boundaries, interfaces,
   data flow), `proposal.md` (why, for titles), the spec deltas'
   `#### Scenario:` blocks (WHEN/THEN — one candidate sequence diagram
   each), and `specs/tla/<change-id>.tla` if present (`Init`/`Next` — the
   state transitions behind a flow chart or state diagram).
3. Picks the diagrams the design actually supports: an architecture diagram
   whenever more than one module or interface is named, one sequence
   diagram per scenario with real cross-module interaction, and a flow
   chart or state diagram when there is branching logic to show.
4. Invokes the `design` skill (Claude Code's design canvas) to draft them
   as artboards on one canvas, each titled with the change and diagram
   kind, each seeded only with the excerpt it needs — not the whole file.
5. Reports what was drawn, and what was skipped and why.

If `design.md` does not exist yet, it says so and stops, pointing to
`spec-author` (or the `spec-driven-tla` / `spec-driven-tla-parallel`
skills) to author a design first.

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
