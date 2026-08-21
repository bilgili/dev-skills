## Development workflow (spec-driven, sub-agent, parallel implementation)

All feature work runs through OpenSpec as a sub-agent pipeline. The phases are
**proposal → design → tasks → parallel implementation → verification →
archive**. Design comes first. Implementation is an implementation detail of
an approved design, fanned out across as many concurrent implementer agents
as `tasks.md` allows.

The **main session is the orchestrator**. It routes work between the
sub-agents in `.claude/agents/`, enforces the phase gates and the
frozen-interface rule, and **never writes specs or code itself** during this
workflow. It is also the only agent that dispatches other agents — the
`implementation-orchestrator` plans and integrates, but the main session
fires the parallel `implementer` calls itself, in one message, so they run
concurrently.

Every Markdown artifact — `proposal.md`, spec deltas, `design.md`,
`tasks.md`, `execution-plan.md`, and the optimizer's proposals — is written
in **ASD-STE100 Simplified Technical English**: one instruction per sentence,
active voice, one word per meaning. Code, identifiers, and quoted error or
trace text stay exact; STE governs prose only.

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
  to a spec requirement and plans around the frozen interfaces. Tags every group
  with a `Files:` list and a `Depends on:` list, so groups with disjoint files and
  no dependency between them are parallel-safe. Writes only `tasks.md`.
- **implementation-orchestrator** — never writes source. In **Plan** mode, batches
  every parallel-safe group whose dependencies are done, creates one git worktree
  per group, and reports the batch. In **Integrate** mode, merges each finished
  worktree's branch, checks off `tasks.md`, and removes the worktree. A merge
  conflict means the `Files:` scopes were wrong — it stops and sends the groups
  back to the task planner, never resolves by hand.
- **implementer** — implements exactly ONE group, inside the worktree it was
  assigned, strictly to the frozen contracts and the group's declared `Files:`
  list. Full code write access within that scope EXCEPT `design.md`,
  `specs/tla/*`, and interface definition files. On interface friction or on
  needing a file outside its scope, it **stops and reports** rather than
  tweaking the interface or the scope.
- **verifier** — derives tests from spec scenarios and interface contracts, **not
  from the code**. Green means "matches spec". Runs after the
  implementation-orchestrator reports every group merged into the change's
  integration branch. On green it runs `openspec archive <change-id>`. Writes
  tests only.
- **optimizer** — runs post-archive, advisory only, READ-ONLY everywhere. Emits
  markdown proposals labeled **SAFE** (internals only → task for the implementer,
  the "safe" loop) or **INTERFACE** (touches a public contract → fresh OpenSpec
  proposal for the spec author, the "new spec" loop, where the revised TLA+ model is
  re-checked against ALL previously established invariants).

### The three hard rules

1. **Frozen interfaces.** Once the design gate approves, public interfaces — every
   type signature, error contract, and spec scenario — are FROZEN. No downstream
   agent may alter one. Any needed interface change goes back through a **new**
   OpenSpec change proposal, never patched inline. **This rule has no exceptions.**
2. **Revise loop.** When the design gate rejects, the TLA+ checker runs TLC against
   the gate's properties. It returns either a **counterexample** (spec-author revises
   the model and re-checks before re-review) or **evidence the objection does not
   hold** (returned to the gate). The gate re-reviews only models that PASS TLC.
3. **Declared scope.** An implementer touches only the files its group declares in
   `tasks.md`. Needing another file is scope friction: it stops and reports, the
   task planner re-scopes the groups, and the batch re-runs. No implementer ever
   widens its own scope mid-batch.

### Human checkpoints

Only the orchestrator talks to the user — no sub-agent asks a question, including
the implementation-orchestrator. It pauses at two points and waits for a reply
before dispatching the next agent. It never assumes an answer.

1. **Diagrams checkpoint** — right after the design gate approves and interfaces
   FREEZE, before dispatching the task planner. Ask the user: "Design approved for
   `<change-id>`. Create diagrams (architecture, sequence, or flow) with
   `opsx_show_design` before implementation?" On yes, invoke the
   `opsx_show_design` skill for `<change-id>`. On no, or once diagramming is
   done, dispatch the task planner.
2. **Implementation checkpoint** — right after the task planner writes `tasks.md`,
   before dispatching the implementation-orchestrator's first **Plan**. Ask the
   user: "`tasks.md` ready for `<change-id>` (N groups). Continue to
   implementation?" On no, stop the pipeline — no worktree is created, `tasks.md`
   is saved, and the user resumes it explicitly later. On yes, dispatch the
   implementation-orchestrator to plan the first batch.

### Mechanical guard

Reject any diff that modifies `design.md`, `specs/tla/*`, or an interface definition
file **outside the design phase**. Reject any implementer diff that touches a file
outside its group's `Files:` list. Either is invalid by construction.

### The batch loop

```
design-gate APPROVE (interfaces FROZEN)
      │
      ▼
CHECKPOINT 1 — ask user: opsx_show_design diagrams before implementation?
      │
      ▼
task-planner → tasks.md (groups tagged Files: / Depends on:)
      │
      ▼
CHECKPOINT 2 — ask user: continue to implementation?
      │
      ▼
implementation-orchestrator (Plan)
      │  batches every group whose deps are done and whose Files: don't overlap
      │  one git worktree + branch per group
      ▼
main session dispatches implementer × N for the batch — ONE message, concurrent
      │
      ├─ group DONE ──────────────┐
      └─ group STOPS (interface   │
         or scope friction) ──┐   │
                               │   ▼
                               │  implementation-orchestrator (Integrate)
                               │   merges each DONE worktree, checks off tasks.md
                               │   removes worktrees
                               │
                               ▼
                    stop reported to main session
                    → task-planner re-scopes → re-plan the batch
      │
      ▼ (repeat Plan → dispatch → Integrate until every group is checked)
verifier → tests from spec scenarios → green → openspec archive
      ▼ (post-archive, advisory)
optimizer → SAFE → implementer (safe loop) · INTERFACE → spec-author (new spec loop)
```
