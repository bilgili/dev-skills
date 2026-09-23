#!/bin/sh
# Static checks only. No Jev or TypeSafe API calls.
set -eu

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

ROOT=$(CDPATH='' cd "$(dirname "$0")/.." && pwd) ||
    fail 'scripts/check-jev-variants.sh: cannot locate repository root'
cd "$ROOT" || fail "$ROOT: cannot enter repository root"

check_only_file() (
    checked_dir=$1
    expected_file=$checked_dir/$2
    [ -d "$checked_dir" ] || fail "$checked_dir: missing directory"
    [ -f "$expected_file" ] || fail "$expected_file: missing regular file"
    for entry in "$checked_dir"/* "$checked_dir"/.[!.]* "$checked_dir"/..?*; do
        [ -e "$entry" ] || [ -L "$entry" ] || continue
        [ "$entry" = "$expected_file" ] ||
            fail "$entry: unexpected entry; $checked_dir must hold only $2"
    done
)

for sibling in spec-driven-tla-jev spec-driven-tla-parallel-jev; do
    sibling_dir=skills/$sibling
    check_only_file "$sibling_dir" SKILL.md
    skill_file=$sibling_dir/SKILL.md
    grep -Fq 'typesafe:typesafe-ai' "$skill_file" ||
        fail "$skill_file: missing typesafe:typesafe-ai"
    grep -Eq '\[[^]]+\]\(\.\./_shared/jev-protocol\.md\)' "$skill_file" ||
        fail "$skill_file: missing Markdown link to ../_shared/jev-protocol.md"
    printf 'PASS: %s (SKILL.md only, TypeSafe skill, protocol link)\n' "$sibling_dir"
done

check_only_file skills/_shared jev-protocol.md
printf 'PASS: skills/_shared holds only jev-protocol.md\n'

manifest=.claude-plugin/marketplace.json
[ -f "$manifest" ] || fail "$manifest: missing file"
for skill_path in ./skills/spec-driven-tla-jev ./skills/spec-driven-tla-parallel-jev; do
    awk -v expected="\"$skill_path\"" '
        { document = document $0 "\n" }
        END {
            while (match(document, /"skills"[[:space:]]*:[[:space:]]*\[[^]]*\]/)) {
                skills = substr(document, RSTART, RLENGTH)
                if (index(skills, expected)) found = 1
                document = substr(document, RSTART + RLENGTH)
            }
            exit !found
        }
    ' "$manifest" || fail "$manifest: skills array must list $skill_path"
done
printf 'PASS: %s lists both JEV siblings\n' "$manifest"

# Compare against the merge base, so committed, staged, and unstaged edits all count.
BASE=${1:-main}
protected='skills/spec-driven-tla skills/spec-driven-tla-parallel skills/opsx_show_design skills/opsx_show_user_flows'
# shellcheck disable=SC2086
git diff --quiet "$BASE" -- $protected ||
    fail "git diff $BASE: protected base skill directories changed or diff failed"
# shellcheck disable=SC2086
[ -z "$(git ls-files --others --exclude-standard -- $protected)" ] ||
    fail 'protected base skill directories hold untracked files'
printf 'PASS: protected base skills unchanged against %s; no Jev calls\n' "$BASE"
