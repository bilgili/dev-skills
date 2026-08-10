# TLA+

TLA+ is a formal specification language. It models a system's state machine
and checks safety and liveness properties before code exists.

## Core ideas

- **Variables** — the state of the system at one instant.
- **Init** — the predicate that describes valid start states.
- **Next** — the predicate that describes valid state transitions (the
  "actions" the system can take).
- **Spec** — `Init /\ [][Next]_vars`, the full behavior: start in `Init`, then
  take only `Next` steps forever (or stutter).
- **Invariant** — a predicate that must hold in every reachable state (a
  safety property, e.g. "the queue never exceeds its bound").
- **Property** — a temporal statement across a behavior (a liveness property,
  e.g. "every request eventually gets a response").

## The model checker: TLC

TLC explores the full reachable state space of a spec, up to bounds you give
it (small constants — 2-3 processes, short queues), and reports one of two
outcomes:

- **PASS** — every invariant held in every state TLC visited, within the
  stated bounds.
- **FAIL** — a **counterexample**: the exact sequence of states that violates
  an invariant or property. This trace is the payoff. It shows precisely how
  the design breaks, before a single line of implementation code exists.

SANY parses and type-checks a module before TLC runs; a syntax or semantic
error stops there with a clear message.

## Why a design gate uses it

A design review by prose catches what a reviewer thinks to ask. A design
review by TLC catches every state the model can reach. Turning a reviewer's
objection into an `INVARIANT` or `PROPERTY` in the `.cfg` makes the objection
checkable, not just arguable — and a counterexample is unambiguous in a way
a review comment is not.

## Bounds are load-bearing

TLC is finite-state: it cannot check unboundedly many processes or an
unbounded queue directly. A PASS is a PASS **only within the stated bounds**
(e.g. `Procs = {p1, p2}`, `MaxQueue = 3`). Always report the bounds beside the
result — an unscoped "PASS" is not a claim, it's a category error.

## In this skill

[`spec-driven-tla`](../skills/spec-driven-tla) uses TLA+ as the formal gate
between design and implementation:

- The **spec-author** models the feature's protocol, state machine, or
  concurrency behavior in `specs/tla/<change-id>.tla`.
- The **design-gate** turns every objection it can formalize into an
  `INVARIANT` / `PROPERTY` in `specs/tla/<change-id>.cfg`.
- The **tla-checker** runs SANY then TLC (and Apalache, if installed, as a
  symbolic cross-check) and returns PASS or a full counterexample trace.
- A counterexample sends the spec-author back to revise the `.tla` model —
  never a prose argument back to the gate.

## Learn more

- [Lamport's TLA+ Home Page](https://lamport.azurewebsites.net/tla/tla.html)
- [Learn TLA+](https://learntla.com/)
- [TLA+ Examples repository](https://github.com/tlaplus/Examples)
