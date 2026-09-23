# Design Review: add-jev-decision-advice

## Verdict

APPROVE WITH CHANGES. The user accepted the model on 2026-09-23 and stopped the last TLC (TLA+ model checker) run before it finished. The changes below are in `design.md`, `specs/`, and `tasks.md`.

## Model scope

- Module: `design.tla`. Configs: `design.cfg` (proposed design), `design_asis_logearly.cfg`, `design_asis_reask.cfg`.
- The model has two subagents, one orchestrator, two questions per agent, four JEV calls, one crash per agent, and one orchestrator JEV call.
- The model covers JEV answers, agree or disagree, channel failure, agent crash, the batched user question, re-dispatch, and log writes.
- The installer has no TLA+ model. Reason: it is a single-owner script with no concurrency. The static check in tasks section 5 covers write-before-validate, splice idempotence, and tool-grant idempotence.

## TLC results

| Config | Result |
|--------|--------|
| `design_asis_logearly.cfg` | FAIL. `NoPendingEntry` violated at depth 12. |
| `design_asis_reask.cfg` | PASS. `NoRepeatUserQuestion` held. 270 million distinct states. Run on the model before fixes 3 and 4. |
| `design.cfg` | PARTIAL. No safety violation in 53.3 million distinct states, depth 46. About 366 thousand states stayed in the queue. The user stopped the run. TLC did not check the liveness properties. |

## Counterexamples and fixes

1. Log before the user answers (design as written). The orchestrator logs an `ESCALATE` entry as `pending`. A channel failure then stops the workflow. The entry stays `pending`. Fix: log the entry after the user answers, or as `unresolved` on stop (D7).
2. Model error. The orchestrator logged entries from agent memory. A crashed agent returns nothing, so the orchestrator cannot see its entries. Fix: the orchestrator logs only the entries that a result carries (D7).
3. Model error. A crash kept the caller decisions of the lost dispatch. Fix: a crash clears the caller decisions and keeps the user decisions (D9).
4. Design gap. A re-dispatch after `ESCALATE` restarted the agent task. The agent asked JEV again about a question that it had already decided. It then escalated a choice that it had made the other way before. Fix: each re-dispatch carries every returned decision forward (D9).

## Redesign after review

The user removed the installer layer and channel discovery. Only the orchestrator calls Jev now. Subagents make no Jev calls.

The model does not cover the final design. It checks the earlier protocol, where subagents call Jev. Its orchestrator allows one call at a time and one call in total. It cannot show an escalation that waits while a later orchestrator call fails. Failed calls in the model have no own call record.

The user stopped the TLA+ work and accepted the model on 2026-09-23. The final protocol rules for these cases carry over from the counterexamples above. No model checks them. The codex review found this gap.

## Open items

- Liveness (`Terminates`, `EscalationResolves`) is not checked. Run `design.cfg` to completion to check it.
- The fixed `design.cfg` run did not finish. The safety result holds only for the states that TLC explored.
