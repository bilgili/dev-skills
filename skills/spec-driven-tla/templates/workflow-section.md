## Development workflow (spec-driven, sub-agent)

All feature work runs through OpenSpec as a sub-agent pipeline. The phases are
**proposal → design → tasks → implementation → verification → archive**. Design
comes first. Implementation is an implementation detail of an approved design.

The **main session is the orchestrator**. It routes work between the sub-agents in
`.claude/agents/`, enforces the phase gates and the frozen-interface rule, and
**never writes specs or code itself** during this workflow.

Every Markdown artifact — `proposal.md`, spec deltas, `design.md`, `tasks.md`,
and the optimizer's proposals — is written in **ASD-STE100 Simplified
Technical English**: one instruction per sentence, active voice, one word per
meaning. Code, identifiers, and quoted error or trace text stay exact; STE
governs prose only.

### The agents and their rules

- **spec-author** — writes the OpenSpec change (`proposal.md`, spec deltas with
  requirements + `#### Scenario:` blocks, `design.md`) AND a TLA+ module at
  `specs/tla/<change-id>.tla` that models the feature's protocol, state machine, or
  concurrency behavior. Public interfaces — function signatures, API shapes, data
  contracts, error semantics — are defined explicitly in `design.md`. Writes only
  under `openspec/` and `specs/tla/`.
- **design-gate** — reviews the proposal like a principal engineer. Runs
  `openspec validate --strict`, checks interface consistency and backward
  compatibility, and owns the model config `specs/tla/<change-id>.cfg`. Read-only on
  code; may write only `specs/tla/*.cfg`. **Every objection it can formalize becomes
  a safety invariant or liveness property** in the `.cfg`, not prose.
- **tla-checker** — runs SANY + TLC (and Apalache if installed) against the model
  and the gate's `.cfg`. Read-only; never edits the spec. Returns **PASS**, or
  **FAIL** with the full counterexample trace and the violated invariant. Uses small
  bounded constants (2–3 processes, small queues) and states the bounds as
  assumptions.
- **task-planner** — decomposes the approved spec into `tasks.md`. Every task traces
  to a spec requirement and plans around the frozen interfaces. Writes only
  `tasks.md`.
- **implementer** — codes strictly to the frozen contracts. Full code write access
  EXCEPT `design.md`, `specs/tla/*`, and interface definition files. On any interface
  friction it **stops and reports** rather than tweaking the interface.
- **verifier** — derives tests from spec scenarios and interface contracts, **not
  from the code**. Green means "matches spec". On green it runs
  `openspec archive <change-id>`. Writes tests only.
- **optimizer** — runs post-archive, advisory only, READ-ONLY everywhere. Emits
  markdown proposals labeled **SAFE** (internals only → task for the implementer,
  the "safe" loop) or **INTERFACE** (touches a public contract → fresh OpenSpec
  proposal for the spec author, the "new spec" loop, where the revised TLA+ model is
  re-checked against ALL previously established invariants).

### The two hard rules

1. **Frozen interfaces.** Once the design gate approves, public interfaces — every
   type signature, error contract, and spec scenario — are FROZEN. No downstream
   agent may alter one. Any needed interface change goes back through a **new**
   OpenSpec change proposal, never patched inline. **This rule has no exceptions.**
2. **Revise loop.** When the design gate rejects, the TLA+ checker runs TLC against
   the gate's properties. It returns either a **counterexample** (spec-author revises
   the model and re-checks before re-review) or **evidence the objection does not
   hold** (returned to the gate). The gate re-reviews only models that PASS TLC.

### Human checkpoints

Only the orchestrator talks to the user — no sub-agent asks a question. It pauses
at two points and waits for a reply before dispatching the next agent. It never
assumes an answer.

1. **Diagrams checkpoint** — right after the design gate approves and interfaces
   FREEZE, before dispatching the task planner. Ask the user: "Design approved for
   `<change-id>`. Create diagrams before implementation — engineering diagrams
   (`opsx_show_design`), user-flow diagrams (`opsx_show_user_flows`), both, or
   skip?" Invoke each skill the user picked, for `<change-id>`. On skip, or once
   diagramming is done, dispatch the task planner.
2. **Implementation checkpoint** — right after the task planner writes `tasks.md`,
   before dispatching the implementer. Ask the user: "`tasks.md` ready for
   `<change-id>` (N tasks). Continue to implementation?" On no, stop the pipeline —
   `tasks.md` is saved, and the user resumes it explicitly later. On yes, dispatch
   the implementer.

### Mechanical guard

Reject any diff that modifies `design.md`, `specs/tla/*`, or an interface definition
file **outside the design phase**. A change to a frozen contract that did not come
through a new OpenSpec proposal is invalid by construction.

### Graph

```
                            ┌──────────────┐
                 request →  │ spec-author  │ ←──────────────┐
                            │ proposal.md  │                │ counterexample
                            │ design.md    │                │ (revise .tla)
                            │ <id>.tla     │                │
                            └──────┬───────┘                │
                                   ▼                        │
                            ┌──────────────┐         ┌──────┴───────┐
                            │ design-gate  │────────▶│ tla-checker  │
                            │ validate     │ props   │ SANY + TLC   │
                            │ owns <id>.cfg│◀────────│ PASS / FAIL  │
                            └──────┬───────┘  PASS   └──────────────┘
                          APPROVE  │  ▲ REJECT (named property)
                  interfaces FROZEN ▼  └──────────────┐
                            ┌──────────────┐          │ interface friction
                            │ CHECKPOINT 1 │          │ → new OpenSpec change
                            │  diagrams?   │          │
                            └──────┬───────┘          │
                                   ▼                  │
                            ┌──────────────┐          │
                            │ task-planner │          │
                            │ tasks.md     │          │
                            └──────┬───────┘          │
                                   ▼                  │
                            ┌──────────────┐          │
                            │ CHECKPOINT 2 │          │
                            │ implement?   │          │
                            └──────┬───────┘          │
                                   ▼                  │
                            ┌──────────────┐          │
                            │ implementer  │──────────┘  stop + escalate
                            │ code to spec │
                            └──────┬───────┘
                                   ▼
                            ┌──────────────┐
                            │  verifier    │  tests from spec scenarios
                            │  pytest      │  green → openspec archive
                            └──────┬───────┘
                                   ▼ (post-archive, advisory)
                            ┌──────────────┐
                            │  optimizer   │  SAFE ─────▶ implementer (safe loop)
                            │  read-only   │  INTERFACE ▶ spec-author (new spec loop)
                            └──────────────┘
```
