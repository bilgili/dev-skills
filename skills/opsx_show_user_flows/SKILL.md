---
name: opsx_show_user_flows
description: Reads an OpenSpec change's proposal and spec deltas, finds every distinct type of user the change affects — end users, operators, IT/infrastructure, support, downstream integrators — and publishes one flow diagram per persona as a technical HTML page with inline SVG. Use when the user wants to see how people will use or be affected by an OpenSpec change, asks for "user flows", "user journeys", or "who does this affect", or invokes /opsx_show_user_flows.
---

# opsx: show user flows

Turns one OpenSpec change into a set of persona flow diagrams — how each
type of affected user actually experiences the change, and what value that
flow delivers them — published as a self-contained HTML Artifact with
inline SVG. It never invents a persona, a step, or a value the source
documents do not support.

## Persona (yours, while running this skill)

You act as a product-minded software architect mapping how each affected
user type experiences this change. You are precise about the concrete
touchpoint a persona hits — the exact screen, CLI command, API endpoint,
error message, or notification — never a vague "the system responds."
You keep engineering internals OUT of these diagrams: no module names, no
function signatures, no data contracts. If a reader needs that, they read
`opsx_show_design`'s output instead. This document answers "what does each
kind of user see and do," not "how is it built."

## What it reads

- `openspec/changes/<change-id>/proposal.md` — why the change exists and
  what it affects. The primary source for who is affected and why.
- `openspec/changes/<change-id>/specs/<capability>/spec.md` — requirements
  and `#### Scenario:` (WHEN/THEN) blocks. A scenario phrased as an actor
  doing something ("WHEN an operator rotates the key...") names both a
  persona and a step in that persona's flow.
- `openspec/changes/<change-id>/design.md`, read only for concrete
  user-facing touchpoints it names (a CLI command, an endpoint path, a UI
  element, an error code) — never for its module boundaries or internal
  data flow. Skim, do not summarize the architecture.

## Procedure

1. Resolve `<change-id>`: use the one the user named. If none, run
   `openspec list` and ask which change.
2. Read `proposal.md` and every spec delta scenario for the change.
3. Identify every distinct persona the change touches. A persona is a
   *type* of user, not an individual: "the API integrator whose client
   calls `/v2/orders`," "the on-call operator rotating a credential," "the
   end user placing an order," "the support agent looking up an order
   status." Ground each persona in a specific line from `proposal.md` or a
   scenario — do not add a persona the documents do not support, even if
   it seems plausible in general.
4. For each persona, state its **value**: what this flow lets them do,
   avoid, or improve that they could not before — grounded in `proposal.md`'s
   stated rationale, not a generic benefit. "Rotates a credential without a
   restart" is a value; "improves the experience" is not — rewrite it until
   it names the concrete thing that changed for that persona.
5. If no scenario or proposal text shows user-facing impact — a pure
   internal refactor, a private implementation detail with no observable
   change to any external actor — say so and stop. Do not force a persona
   diagram onto a change with no user-facing surface.
6. For each real persona, draft ONE flow: entry point (what triggers this
   persona's interaction), each step as a concrete touchpoint named
   exactly as the source documents name it, decision points and
   alternate/error paths their scenarios describe, and the outcome — stated
   as the value from step 4, not just the final system state. Note the
   requirement id (`Requirement: R2`) each step traces to.
7. Before writing anything, load the `artifact-design` skill and the
   `artifact-diagramming` skill — both are mandatory for hand-authored SVG
   in a published Artifact.
8. Draft one self-contained HTML page:
   - Header: `<change-id>`, a one-paragraph scope (from `proposal.md`,
     ASD-STE100), and a list naming every persona found, each with its
     one-line value from step 4.
   - Each persona's flow as inline SVG, theme-aware (CSS custom
     properties, not hardcoded hex), in its own `overflow-x: auto`
     container if wide. One caption per diagram stating the persona's goal,
     the value this flow delivers them, and which requirement(s) it traces
     to — ASD-STE100.
   - An **Open questions** section, if any scenario left a persona's path
     ambiguous (undecided error handling, an unstated fallback) — name the
     gap plainly rather than inventing a resolution.
   - A stable favicon distinct from `opsx_show_design`'s (for example 🧭
     or 👤), kept stable across re-runs for the same change.
9. Publish with the Artifact tool. Title the artifact "`<change-id>` —
   user flows."
10. Report back: the artifact link, the persona list with each one's value,
    one sentence per flow drawn (ASD-STE100), and any change with no
    user-facing impact.

## When there is nothing to diagram

If `proposal.md` does not exist for the change, say so and stop — there is
no OpenSpec change yet. Point to the `spec-author` agent, or the
`spec-driven-tla` / `spec-driven-tla-parallel` skills, if the user wants a
proposal authored first. If `proposal.md` exists but nothing in it or the
spec deltas shows user-facing impact, report that plainly instead of
drawing an empty or invented flow.

## Relation to opsx_show_design

Both read the same OpenSpec change and both publish an HTML Artifact with
inline SVG, but they answer different questions for different readers:
`opsx_show_design` diagrams the system for engineers — modules,
interfaces, contracts, invariants. This skill diagrams the experience for
everyone the system touches — end users, operators, IT/infrastructure,
support, integrators — with no engineering internals in view. Run either
independently; run both for a change that needs both a technical and a
product review. Either can be offered at the `spec-driven-tla` /
`spec-driven-tla-parallel` workflows' Checkpoint 1, alongside
`opsx_show_design`.
