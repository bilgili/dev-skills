---
name: spec-driven-tla-parallel
description: Spec-driven, sub-agent development workflow with a parallel, multi-agent implementation phase — OpenSpec phases (proposal → design → tasks → parallel implementation → verification → archive) with TLA+ design verification. Use when the user wants the spec-driven + TLA+ workflow but with implementation fanned out across multiple concurrent implementer agents, or asks for "parallel implementation", "multi-agent implementer", or "an orchestrator for the implementers". Cross-platform: macOS, Linux, Windows.
---

# Spec-driven + TLA+ sub-agent workflow (parallel implementation)

A fork of `spec-driven-tla` that fans implementation out across multiple
concurrent implementer agents instead of one. It installs eight role-scoped
sub-agents, a TLA+ model directory, an OpenSpec workspace, and the TLA+
toolchain (TLC + SANY).

## What is different from spec-driven-tla

- **task-planner** now tags every group in `tasks.md` with a `Files:` list
  and a `Depends on:` list, so groups can be checked for parallel safety.
- **implementation-orchestrator** (new) turns those tags into batches of
  parallel-safe groups, assigns one git worktree per group, and — after the
  main session runs the implementer agents — merges the finished worktrees
  back and updates `tasks.md`.
- **implementer** now implements exactly one group, inside the worktree it
  was assigned, scoped to that group's declared files. Touching a file
  outside that scope is a stop condition, the same tier as interface
  friction.

## What it installs

- `.claude/agents/*.md` — spec-author, design-gate, tla-checker,
  task-planner, implementation-orchestrator, implementer, verifier,
  optimizer (tool-scoped per role).
- `specs/tla/` — home for `<change-id>.tla` models and `<change-id>.cfg` configs.
- `openspec/` — via `openspec init` if not already present.
- TLA+ toolchain: JDK + `~/tools/tla2tools.jar` + `tlc`/`sany` wrappers.

Every agent that writes Markdown — spec-author, task-planner,
implementation-orchestrator, optimizer, and design-gate's verdicts — writes
it in **ASD-STE100 Simplified Technical English**. This rule is built into
each agent's prompt, so it holds in any target project, independent of that
project's own `CLAUDE.md`.

Every step is idempotent — re-running keeps what exists.

## How to run

Run the installer from the target project root. **Pick the script by OS:**

- **macOS / Linux / Git Bash / WSL:**
  ```sh
  sh ~/.claude/skills/spec-driven-tla-parallel/install.sh
  ```
- **Windows (PowerShell):**
  ```powershell
  powershell -ExecutionPolicy Bypass -File "$HOME\.claude\skills\spec-driven-tla-parallel\install.ps1"
  ```

Pass a target directory as the first argument to install elsewhere. When the
skill lives at a different path (another machine, a plugin dir), substitute
that path.

## After install

- Verify the toolchain: `tlc -help`. If `tlc` is not on PATH, add
  `~/.local/bin` (POSIX) or `%USERPROFILE%\.local\bin` (Windows).
- The main session is the **orchestrator**: it routes work between the
  sub-agents, enforces the phase gates, and never writes specs or code
  itself. It is also the only agent that dispatches other agents — the
  implementation-orchestrator plans batches and integrates results, but the
  main session fires the parallel `implementer` calls. See
  [templates/workflow-section.md](templates/workflow-section.md) for the
  full contract, the two hard rules, the batch loop, and the pipeline graph.

## Using the workflow

1. Dispatch **spec-author** for a new feature → `proposal.md`, spec deltas,
   `design.md`, and `specs/tla/<change-id>.tla`.
2. Dispatch **design-gate** → reviews, writes `specs/tla/<change-id>.cfg`,
   requests a TLA+ check. On APPROVE, interfaces FREEZE.
3. Dispatch **tla-checker** → SANY + TLC; PASS or FAIL with counterexample.
4. On approval → **task-planner** → `tasks.md`, every group tagged `Files:`
   and `Depends on:`.
5. Dispatch **implementation-orchestrator** (Plan mode) → batches
   parallel-safe groups, creates one git worktree per group, reports the
   batch.
6. Dispatch one **implementer** per group in the batch, in a single message
   so they run concurrently. Each works only inside its own worktree.
7. Dispatch **implementation-orchestrator** (Integrate mode) → merges each
   finished worktree, checks off `tasks.md`, removes worktrees, escalates on
   conflict or scope friction.
8. Repeat 5–7 until every group in `tasks.md` is checked.
9. Dispatch **verifier** → spec-derived tests on the integrated branch, then
   `openspec archive`.
10. Post-archive → **optimizer** (advisory; SAFE or INTERFACE proposals).
