# dev-skills

Agent Skills for [Claude Code](https://claude.com/claude-code) — packaged,
installable workflows for AI-assisted development.

## Skills

### [spec-driven-tla](skills/spec-driven-tla)

A spec-driven, sub-agent development workflow: OpenSpec phases (proposal →
design → tasks → implementation → verification → archive), gated by a formal
TLA+ design check before interfaces freeze. Installs seven role-scoped
sub-agents, a TLA+ model directory, an OpenSpec workspace, and the TLA+
toolchain (TLC + SANY) into a target project. Every generated spec, design,
and task doc is written in ASD-STE100 Simplified Technical English. The
orchestrator pauses twice for the user: once after the design freezes, to
offer `opsx_show_design` and/or `opsx_show_user_flows` diagrams, and once
after `tasks.md` is written, to confirm before implementation starts.

See [docs/spec-driven-tla.md](docs/spec-driven-tla.md) for the full pipeline
diagram and per-agent write boundaries, [docs/tla-plus.md](docs/tla-plus.md)
for what TLA+ and TLC check, and [docs/openspec.md](docs/openspec.md) for the
OpenSpec phases and commands.

### [spec-driven-tla-parallel](skills/spec-driven-tla-parallel)

A fork of `spec-driven-tla` that fans implementation out across multiple
concurrent implementer agents instead of one. `task-planner` tags every
`tasks.md` group with the files it touches and what it depends on; a new
`implementation-orchestrator` agent batches the parallel-safe groups, runs
each in its own git worktree, and merges finished work back — the main
session dispatches the batch's `implementer` agents concurrently, in one
message. Same two human checkpoints as `spec-driven-tla`: diagrams after the
design freezes, confirmation before implementation starts.

See [docs/spec-driven-tla-parallel.md](docs/spec-driven-tla-parallel.md) for
the full pipeline diagram, the batch loop, and per-agent write boundaries.

### [opsx_show_design](skills/opsx_show_design)

Reads an OpenSpec change's `design.md`, spec deltas, and TLA+ model, and
publishes a technical design-review document — an HTML Artifact with inline
SVG diagrams (architecture, one sequence diagram per scenario, a flow chart
for any branching logic), written as a Principal Software Architect
presenting to senior and mid-level engineers: literal signatures and
contracts, not illustrative boxes. Each diagram states which technical
persona uses it and for what — implementer, reviewer, on-call operator,
downstream system, verifier, maintainer — skipping any persona the design
gives no real use to. It never authors a design, only diagrams an existing
one. Both `spec-driven-tla` skills' Checkpoint 1 dispatches this; use it
standalone too, for any OpenSpec change.

See [docs/opsx_show_design.md](docs/opsx_show_design.md) for what it reads
and how it picks which diagrams and personas to include.

### [opsx_show_user_flows](skills/opsx_show_user_flows)

Reads an OpenSpec change's `proposal.md` and spec deltas, finds every
distinct type of user the change affects — end users, operators,
IT/infrastructure, support, downstream integrators — and publishes one flow
diagram per persona as an HTML Artifact with inline SVG: the exact screen,
command, endpoint, or message each persona hits, and the concrete value that
flow delivers them, no module names or signatures. The product-facing
counterpart to `opsx_show_design`; run either independently, or both for a
change that needs a technical and a product review.

See [docs/opsx_show_user_flows.md](docs/opsx_show_user_flows.md) for how it
finds personas, states their value, and what it does when a change has no
user-facing impact.

## Adding a skill

Each skill lives under `skills/<skill-name>/` and gets one doc,
`docs/<skill-name>.md`, often with its own diagram — skip the diagram for a
simple linear skill where the doc's own procedure list already shows the
flow. List it here under Skills with a one-paragraph summary and a link to
its doc. Also add `./skills/<skill-name>` to the `skills` array in
[.claude-plugin/marketplace.json](.claude-plugin/marketplace.json) so the
marketplace picks it up.

## Install

### As a Claude Code plugin marketplace (recommended)

```sh
claude plugin marketplace add bilgili/dev-skills
claude plugin install dev-skills@dev-skills
```

This registers this repo as a marketplace (`.claude-plugin/marketplace.json`)
and installs the `dev-skills` plugin, which bundles every skill listed in
that manifest — `spec-driven-tla` today, more as they're added. Claude Code
picks up new skills on the next `claude plugin update` after a manifest
change.

### Standalone installer

The installer is idempotent — re-running keeps what already exists. Run it
from the target project's root.

#### macOS / Linux / Git Bash / WSL

```sh
git clone https://github.com/bilgili/dev-skills.git ~/dev-skills
sh ~/dev-skills/skills/spec-driven-tla/install.sh
```

#### Windows (PowerShell)

```powershell
git clone https://github.com/bilgili/dev-skills.git $HOME\dev-skills
powershell -ExecutionPolicy Bypass -File "$HOME\dev-skills\skills\spec-driven-tla\install.ps1"
```

Pass a target directory as the first argument to install somewhere other than
the current directory.

### As a Claude Code skill (manual symlink)

Copy (or symlink) the skill directory into your Claude Code skills folder so
`Skill` can discover it directly:

```sh
git clone https://github.com/bilgili/dev-skills.git ~/dev-skills
ln -s ~/dev-skills/skills/spec-driven-tla ~/.claude/skills/spec-driven-tla
```

### What gets installed

- `.claude/agents/*.md` — `spec-author`, `design-gate`, `tla-checker`,
  `task-planner`, `implementer`, `verifier`, `optimizer` (tool-scoped per
  role).
- `specs/tla/` — home for `<change-id>.tla` models and `<change-id>.cfg`
  configs.
- `openspec/` — via `openspec init`, if not already present.
- The TLA+ toolchain: JDK + `tla2tools.jar` + `tlc` / `sany` wrappers.

The installer does not touch your `CLAUDE.md`. The orchestrator contract —
roles, the two hard rules, the mechanical guard, the pipeline graph — lives in
[skills/spec-driven-tla/templates/workflow-section.md](skills/spec-driven-tla/templates/workflow-section.md).
Read it, or paste it into your own `CLAUDE.md` if you want it there.

### After install

- Verify the toolchain: `tlc -help`. If `tlc` is not on `PATH`, add
  `~/.local/bin` (POSIX) or `%USERPROFILE%\.local\bin` (Windows).
- The main session becomes the **orchestrator**: it routes work between the
  sub-agents, enforces the phase gates, and never writes specs or code
  itself. See `workflow-section.md` (linked above) for the full contract, the
  two hard rules, and the pipeline graph.

### Using the workflow

1. Dispatch **spec-author** for a new feature → `proposal.md`, spec deltas,
   `design.md`, and `specs/tla/<change-id>.tla`.
2. Dispatch **design-gate** → reviews, writes `specs/tla/<change-id>.cfg`,
   requests a TLA+ check. On APPROVE, interfaces FREEZE.
3. Dispatch **tla-checker** → SANY + TLC; PASS or FAIL with counterexample.
4. On approval → **task-planner** (`tasks.md`) → **implementer** (code to
   frozen contracts) → **verifier** (spec-derived tests, then
   `openspec archive`).
5. Post-archive → **optimizer** (advisory; SAFE or INTERFACE proposals).

## License

[MIT](LICENSE)
