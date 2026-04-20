#!/usr/bin/env bash
# Install UI/UX PRO MAX skill for Kiro IDE (macOS / Linux)
# Upstream: https://github.com/nextlevelbuilder/ui-ux-pro-max-skill

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

# uipro-cli only installs into the current working directory. Run it in a
# temp folder, then move the generated skill into ~/.kiro/skills/.
stage="$(mktemp -d -t uipro-stage.XXXXXX)"
cleanup() { rm -rf "$stage"; }
trap cleanup EXIT

(
    cd "$stage"
    step 'Running: uipro init --ai kiro --force'
    uipro init --ai kiro --force
)

generated="$stage/.kiro/steering/ui-ux-pro-max"
if [ ! -d "$generated" ]; then
    err "Did not find expected output at $generated"
    exit 1
fi

kiro_skills="$HOME/.kiro/skills"
target="$kiro_skills/ui-ux-pro-max"
mkdir -p "$kiro_skills"
rm -rf "$target"

step "Installing to $target"
cp -R "$generated" "$target"

ok "Installed to $target"
echo
printf '\033[33m%s\033[0m\n' 'Restart Kiro (or reload window) to see ui-ux-pro-max under AGENT STEERING & SKILLS > Global.'
