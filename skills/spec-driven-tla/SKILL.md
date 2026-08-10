---
name: spec-driven-tla
description: Install a spec-driven, sub-agent development workflow into the current project — OpenSpec phases (proposal → design → tasks → implementation → verification → archive) with TLA+ design verification. Use when the user wants to set up, bootstrap, or add this workflow (spec author, design gate, TLA+ checker, task planner, implementer, verifier, optimizer) to a repo, or asks for "the spec-driven workflow", "TLA+ design gate", or "OpenSpec sub-agents". Cross-platform: macOS, Linux, Windows.
---

# Spec-driven + TLA+ sub-agent workflow

Bootstraps a full spec-driven pipeline into a target project. It installs seven
role-scoped sub-agents, a TLA+ model directory, an OpenSpec workspace, a CLAUDE.md
workflow section, and the TLA+ toolchain (TLC + SANY).

## What it installs

- `.claude/agents/*.md` — spec-author, design-gate, tla-checker, task-planner,
  implementer, verifier, optimizer (tool-scoped per role).
- `specs/tla/` — home for `<change-id>.tla` models and `<change-id>.cfg` configs.
- `openspec/` — via `openspec init` if not already present.
- A `## Development workflow (spec-driven, sub-agent)` section appended to `CLAUDE.md`.
- TLA+ toolchain: JDK + `~/tools/tla2tools.jar` + `tlc`/`sany` wrappers.

Every step is idempotent — re-running keeps what exists.

## How to run

Run the installer from the target project root. **Pick the script by OS:**

- **macOS / Linux / Git Bash / WSL:**
  ```sh
  sh ~/.claude/skills/spec-driven-tla/install.sh
  ```
- **Windows (PowerShell):**
  ```powershell
  powershell -ExecutionPolicy Bypass -File "$HOME\.claude\skills\spec-driven-tla\install.ps1"
  ```

Pass a target directory as the first argument to install elsewhere. When the skill
lives at a different path (another machine, a plugin dir), substitute that path.

## After install

- Verify the toolchain: `tlc -help` (POSIX) or `tlc -help` from any Windows shell.
  If `tlc` is not on PATH, add `~/.local/bin` (POSIX) or `%USERPROFILE%\.local\bin`
  (Windows) to PATH.
- The main session is the **orchestrator**: it routes work between the sub-agents,
  enforces the phase gates, and never writes specs or code itself. See the appended
  CLAUDE.md section for the full contract, the two hard rules (frozen interfaces,
  revise loop), the mechanical guard, and the pipeline graph.

## Using the workflow

1. Dispatch **spec-author** for a new feature → `proposal.md`, spec deltas,
   `design.md`, and `specs/tla/<change-id>.tla`.
2. Dispatch **design-gate** → reviews, writes `specs/tla/<change-id>.cfg`, requests
   a TLA+ check. On APPROVE, interfaces FREEZE.
3. Dispatch **tla-checker** → SANY + TLC; PASS or FAIL with counterexample.
4. On approval → **task-planner** (`tasks.md`) → **implementer** (code to frozen
   contracts) → **verifier** (spec-derived tests, then `openspec archive`).
5. Post-archive → **optimizer** (advisory; SAFE or INTERFACE proposals).
