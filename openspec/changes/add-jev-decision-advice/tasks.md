## 1. Protocol source

- [x] 1.1 Rewrite `skills/_shared/jev-protocol.md` in ASD-STE100 for an orchestrator-only protocol: invoke `typesafe:typesafe-ai`, frame each choice as a Choice, brief rules, fixed thresholds, escalation, failure stop, log rules, carry-forward.

## 2. Sibling skills

- [x] 2.1 Delete `install.sh` and `install.ps1` from both sibling directories.
- [x] 2.2 Delete `skills/_shared/jev-layer.sh` and `skills/_shared/jev-layer.ps1`.
- [x] 2.3 Rewrite `skills/spec-driven-tla-jev/SKILL.md`: check for `typesafe:typesafe-ai`, stop with the install command when absent, run the base installer command, then guide the orchestrator with the shared protocol.
- [x] 2.4 Rewrite `skills/spec-driven-tla-parallel-jev/SKILL.md` with the same shape against the parallel base.
- [x] 2.5 Update the `README.md` section and the marketplace description for the new shape.

## 3. Static check

- [x] 3.1 Rewrite `scripts/check-jev-variants.sh`: each sibling holds only `SKILL.md`; each `SKILL.md` names `typesafe:typesafe-ai` and links `../_shared/jev-protocol.md`; the manifest lists both siblings; no change under the four existing skill directories.

## 4. Gates

- [x] 4.1 Run `openspec validate add-jev-decision-advice --strict`.
- [x] 4.2 Run the codex review before the merge to `main`.
