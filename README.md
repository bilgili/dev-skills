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
and task doc is written in ASD-STE100 Simplified Technical English.

See [docs/spec-driven-tla.md](docs/spec-driven-tla.md) for the full pipeline
diagram and per-agent write boundaries, [docs/tla-plus.md](docs/tla-plus.md)
for what TLA+ and TLC check, and [docs/openspec.md](docs/openspec.md) for the
OpenSpec phases and commands.

## Adding a skill

Each skill lives under `skills/<skill-name>/` and gets one doc,
`docs/<skill-name>.md`, with its own diagram. List it here under Skills with
a one-paragraph summary and a link to its doc. Also add `./skills/<skill-name>`
to the `skills` array in [.claude-plugin/marketplace.json](.claude-plugin/marketplace.json)
so the marketplace picks it up.

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
