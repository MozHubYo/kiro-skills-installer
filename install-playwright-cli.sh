#!/usr/bin/env bash
# Install Playwright CLI skill for Kiro IDE (macOS / Linux)
# Upstream: https://github.com/microsoft/playwright-cli

set -euo pipefail

step() { printf '\033[36m==> %s\033[0m\n' "$1"; }
ok()   { printf '\033[32m[OK] %s\033[0m\n' "$1"; }
err()  { printf '\033[31m[ERROR] %s\033[0m\n' "$1" >&2; }

step 'Checking prerequisites'
if ! command -v node >/dev/null 2>&1; then
    err 'Node.js not found. Install from https://nodejs.org/ (or: brew install node)'
    exit 1
fi
if ! command -v npm >/dev/null 2>&1; then
    err 'npm not found. Reinstall Node.js.'
    exit 1
fi
ok "node $(node --version), npm $(npm --version)"

step 'Installing @playwright/cli globally'
npm install -g '@playwright/cli@latest'

# `playwright-cli install --skills` installs into the CURRENT working directory
# (e.g. ./.claude/skills/playwright-cli), not ~/.claude/skills/. Run it in a
# temp folder, then mirror the skill into ~/.kiro/skills/.
stage="$(mktemp -d -t pwcli-stage.XXXXXX)"
cleanup() { rm -rf "$stage"; }
trap cleanup EXIT

(
    cd "$stage"
    step 'Running: playwright-cli install --skills'
    playwright-cli install --skills
)

candidates=(
    "$stage/.claude/skills/playwright-cli"
    "$stage/.copilot/skills/playwright-cli"
    "$stage/.github/copilot/skills/playwright-cli"
)
source_dir=""
for c in "${candidates[@]}"; do
    if [ -d "$c" ]; then source_dir="$c"; break; fi
done
if [ -z "$source_dir" ]; then
    err 'Could not find an installed playwright-cli skill to copy into Kiro.'
    err 'Checked:'
    for c in "${candidates[@]}"; do echo "  - $c"; done
    exit 1
fi
step "Mirroring skill from: $source_dir"

if [ ! -f "$source_dir/SKILL.md" ]; then
    err "Generated folder is missing SKILL.md at $source_dir/SKILL.md"
    exit 1
fi

kiro_skills="$HOME/.kiro/skills"
target="$kiro_skills/playwright-cli"
mkdir -p "$kiro_skills"
rm -rf "$target"
cp -R "$source_dir" "$target"

step 'Verifying installed skill'
installed_skill_md="$target/SKILL.md"
if [ ! -f "$installed_skill_md" ]; then
    err "SKILL.md not found at $installed_skill_md"
    exit 1
fi
head_block="$(head -n 10 "$installed_skill_md")"
if ! printf '%s\n' "$head_block" | grep -qE '^---\s*$'; then
    err 'SKILL.md has no YAML front-matter opener (---).'
    err 'Kiro Skills panel will NOT detect this skill. Aborting.'
    exit 1
fi
if ! printf '%s\n' "$head_block" | grep -qE '^name:[[:space:]]*\S+'; then
    err 'SKILL.md front-matter is missing: name:'
    err 'Kiro Skills panel will NOT detect this skill. Aborting.'
    exit 1
fi
if ! printf '%s\n' "$head_block" | grep -qE '^description:[[:space:]]*\S+'; then
    err 'SKILL.md front-matter is missing: description:'
    err 'Kiro Skills panel will NOT detect this skill. Aborting.'
    exit 1
fi
ok 'SKILL.md has valid YAML front-matter (name, description)'

ok "Installed to $target"
echo
printf '\033[33m%s\033[0m\n' 'Restart Kiro (or reload window) to see playwright-cli under AGENT STEERING & SKILLS > Global.'
