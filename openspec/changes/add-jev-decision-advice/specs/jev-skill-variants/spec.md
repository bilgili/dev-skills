## ADDED Requirements

### Requirement: Two SKILL.md-only sibling skills
The repository SHALL contain `skills/spec-driven-tla-jev/SKILL.md` and `skills/spec-driven-tla-parallel-jev/SKILL.md`. The sibling directories SHALL contain no installer script and no template. Each sibling SHALL run the installer of its base skill without change. The skills `spec-driven-tla`, `spec-driven-tla-parallel`, `opsx_show_design`, and `opsx_show_user_flows` SHALL NOT change.

#### Scenario: Originals untouched
- **WHEN** the change is complete
- **THEN** `git diff` shows no change under the four existing skill directories

#### Scenario: No sibling installer
- **WHEN** a user lists a sibling directory
- **THEN** it holds `SKILL.md` only

### Requirement: Installed agents stay unchanged
A JEV skill SHALL NOT edit the agent files that the base installer writes.

#### Scenario: Install through the JEV skill
- **WHEN** the user installs through `spec-driven-tla-jev`
- **THEN** the target agent files equal the files from a base install

### Requirement: One protocol source
The file `skills/_shared/jev-protocol.md` SHALL be the only source of the Jev protocol text. Both sibling `SKILL.md` files SHALL refer to it and SHALL NOT copy it.

#### Scenario: Protocol edit
- **WHEN** a maintainer edits the protocol file
- **THEN** both siblings use the edited rules without a change to either `SKILL.md`

### Requirement: Marketplace registration
`.claude-plugin/marketplace.json` SHALL list both sibling skill paths.

#### Scenario: Plugin manifest
- **WHEN** a user reads the plugin manifest
- **THEN** the skill list contains `./skills/spec-driven-tla-jev` and `./skills/spec-driven-tla-parallel-jev`

### Requirement: Static check
The script `scripts/check-jev-variants.sh` SHALL fail unless each sibling directory holds only `SKILL.md`, each `SKILL.md` names `typesafe:typesafe-ai` and links `../_shared/jev-protocol.md`, and the manifest lists both siblings. It SHALL also fail when the four existing skill directories differ from a base revision (default `main`) or hold untracked files. The check SHALL NOT call Jev.

#### Scenario: Stray installer
- **WHEN** a sibling directory holds an `install.sh`
- **THEN** the static check exits non-zero and names the file
