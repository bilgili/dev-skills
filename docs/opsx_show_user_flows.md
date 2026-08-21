# opsx_show_user_flows

Skill: [`skills/opsx_show_user_flows`](../skills/opsx_show_user_flows). A
plain instruction skill — no sub-agents, no installer. It publishes a
persona flow diagram for every distinct type of user an OpenSpec change
affects, and states the value each flow delivers that persona; it never
invents a persona, a step, or a value the source documents do not support.

## Persona (the skill's own, while it runs)

It acts as a product-minded software architect mapping how each affected
user type experiences the change: the exact screen, CLI command, API
endpoint, error message, or notification a persona hits, never a vague "the
system responds." It keeps engineering internals out — no module names, no
signatures, no data contracts. That is [opsx_show_design](opsx_show_design.md)'s
job.

## What it does

1. Resolves `<change-id>` — the one named, or asks after `openspec list`.
2. Reads `proposal.md` (why, what it affects) and every spec delta's
   `#### Scenario:` block, plus `design.md` skimmed only for concrete
   user-facing touchpoints — never its architecture.
3. Identifies every distinct persona the change touches, each grounded in a
   specific line from `proposal.md` or a scenario — never an invented
   plausible-sounding role.
4. States each persona's **value**: the concrete thing this flow lets them
   do, avoid, or improve — "rotates a credential without a restart," not
   "improves the experience." A pure internal refactor with no user-facing
   surface gets no personas: the skill says so and stops.
5. Drafts one flow per persona: entry point, each step as a concrete
   touchpoint, decision and error paths, and the outcome stated as that
   persona's value — plus the requirement id each step traces to.
6. Loads `artifact-design` and `artifact-diagramming`, then hand-authors one
   self-contained HTML page: a scope header listing every persona with its
   value, one theme-aware inline-SVG flow per persona (captioned with goal,
   value, and requirement id), and an **Open questions** section for
   anything a scenario left ambiguous.
7. Publishes it with the Artifact tool, titled "`<change-id>` — user
   flows."
8. Reports back the artifact link, the persona list with each one's value,
   and one sentence per flow drawn.

## Relation to opsx_show_design

Both read the same OpenSpec change and both publish an HTML Artifact with
inline SVG, but for different readers. `opsx_show_design` diagrams the
system for engineers — modules, interfaces, contracts, invariants. This
skill diagrams the experience for everyone the system touches, with no
engineering internals in view. Run either independently, or both for a
change that needs a technical review and a product review. Either can be
offered at the `spec-driven-tla` / `spec-driven-tla-parallel` workflows'
Checkpoint 1.

## See also

- [opsx_show_design](opsx_show_design.md) — the engineering counterpart:
  architecture, sequence, and state diagrams from the same change.
- [spec-driven-tla](spec-driven-tla.md) and
  [spec-driven-tla-parallel](spec-driven-tla-parallel.md) — the workflows
  whose Checkpoint 1 can dispatch this skill.
- [OpenSpec](openspec.md) — where `proposal.md`, spec deltas, and
  `change-id`s come from.
