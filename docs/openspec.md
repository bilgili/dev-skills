# OpenSpec

[OpenSpec](https://github.com/Fission-AI/OpenSpec) is a spec-driven workflow
tool for AI-assisted development. It keeps a change's intent, its approved
design, and its implementation in three separate, ordered artifacts instead of
one prompt.

## Workspace layout

```
openspec/
  specs/                        capability specs, current truth
    <capability>/spec.md
  changes/                      in-flight change proposals
    <change-id>/
      proposal.md                why the change exists, what it affects
      specs/<capability>/spec.md  spec deltas: requirements + scenarios
      design.md                   the design, frozen interfaces
      tasks.md                    ordered implementation checklist
```

## The phases

1. **Proposal** — states why the change exists, what it affects, and the
   discarded alternative for any non-obvious decision.
2. **Spec delta** — requirements as `#### Scenario:` blocks (WHEN/THEN). One
   requirement owns one behavior.
3. **Design** — defines every public interface explicitly: function
   signatures, API shapes, data contracts, error semantics.
4. **Tasks** — an ordered checklist; every task traces back to a spec
   requirement.
5. **Implementation** — code written strictly to the frozen design.
6. **Verification** — tests derived from the spec scenarios, not from the
   code. Green means "matches spec".
7. **Archive** — `openspec archive <change-id>` moves the change's spec deltas
   into `openspec/specs/`, the new source of truth.

## Key commands

```sh
openspec init                          # create openspec/ in a new project
openspec list                          # list active changes, pick a fresh id
openspec validate <change-id> --strict # check a change's structure and scenarios
openspec archive <change-id>           # fold an approved, verified change into specs/
```

## Why design comes first

Implementation is downstream of an approved design, not a substitute for one.
Once a design is approved, its public interfaces are **frozen** — no
downstream phase may alter one inline. Any needed interface change goes
through a **new** OpenSpec change proposal. This keeps "the code" and "the
approved contract" from silently drifting apart.

## In this skill

[`spec-driven-tla`](../skills/spec-driven-tla) drives the OpenSpec phases
through seven role-scoped sub-agents, and adds a formal design gate: before
interfaces freeze, the design is model-checked with [TLA+](tla-plus.md), not
just read. See [spec-driven-tla](spec-driven-tla.md) for the full pipeline
diagram and agent roles.

## Learn more

- [OpenSpec on GitHub](https://github.com/Fission-AI/OpenSpec)
