#!/usr/bin/env bash
# Install UI/UX PRO MAX skill for Kiro IDE (macOS / Linux)
# Upstream: https://github.com/nextlevelbuilder/ui-ux-pro-max-skill
#
# Note: `uipro init --ai kiro` generates Kiro *steering* files, which do NOT
# show up in Kiro's Skills panel. We use `--ai codex` instead, which outputs
# the Agent Skills format (SKILL.md + YAML front-matter) that Kiro recognizes.

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

step 'Installing uipro-cli globally'
npm install -g uipro-cli

# uipro-cli writes into the current working directory. Run it in a temp folder,
# then move the generated Skill into ~/.kiro/skills/.
stage="$(mktemp -d -t uipro-stage.XXXXXX)"
cleanup() { rm -rf "$stage"; }
trap cleanup EXIT

(
    cd "$stage"
    step 'Running: uipro init --ai codex --force'
    uipro init --ai codex --force
)

generated="$stage/.codex/skills/ui-ux-pro-max"
if [ ! -d "$generated" ]; then
    err "Did not find expected output at $generated"
    exit 1
fi
if [ ! -f "$generated/SKILL.md" ]; then
    err "Generated folder is missing SKILL.md at $generated/SKILL.md"
    exit 1
fi

kiro_skills="$HOME/.kiro/skills"
target="$kiro_skills/ui-ux-pro-max"
mkdir -p "$kiro_skills"
rm -rf "$target"

step "Installing to $target"
cp -R "$generated" "$target"

step 'Verifying installed skill'
installed_skill_md="$target/SKILL.md"
if [ ! -f "$installed_skill_md" ]; then
    err "SKILL.md not found at $installed_skill_md"
    exit 1
fi

# Require YAML front-matter with at least name: and description: in the first 10 lines.
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
printf '\033[33m%s\033[0m\n' 'Restart Kiro (or reload window) to see ui-ux-pro-max under AGENT STEERING & SKILLS > Global.'
