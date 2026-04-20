#!/usr/bin/env pwsh
# Install UI/UX PRO MAX skill for Kiro IDE (Windows)
# Upstream: https://github.com/nextlevelbuilder/ui-ux-pro-max-skill
#
# Note: `uipro init --ai kiro` generates Kiro *steering* files, which do NOT
# show up in Kiro's Skills panel. We use `--ai codex` instead, which outputs
# the Agent Skills format (SKILL.md + YAML front-matter) that Kiro recognizes.

# Use Continue so that native tool progress messages written to stderr do not
# abort the script. We check $LASTEXITCODE explicitly after each external call.
$ErrorActionPreference = 'Continue'

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Err($msg)  { Write-Host "[ERROR] $msg" -ForegroundColor Red }

Write-Step 'Checking prerequisites'
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Err 'Node.js not found. Please install Node.js 18+ from https://nodejs.org/'
    exit 1
}
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Err 'npm not found. Please reinstall Node.js.'
    exit 1
}
Write-Ok ("node {0}, npm {1}" -f (node --version), (npm --version))

Write-Step 'Installing uipro-cli globally'
npm install -g uipro-cli 2>&1 | ForEach-Object { "$_" } | Out-Host
if ($LASTEXITCODE -ne 0) { Write-Err 'Failed to install uipro-cli'; exit 1 }

# uipro-cli writes into the current working directory. Run it in a temp folder,
# then move the generated Skill into ~/.kiro/skills/.
$stage = Join-Path $env:TEMP ("uipro-stage-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage -Force | Out-Null
try {
    Push-Location $stage
    Write-Step 'Running: uipro init --ai codex --force'
    uipro init --ai codex --force 2>&1 | ForEach-Object { "$_" } | Out-Host
    if ($LASTEXITCODE -ne 0) { Write-Err 'uipro init failed'; exit 1 }

    $generated = Join-Path $stage '.codex\skills\ui-ux-pro-max'
    if (-not (Test-Path $generated)) {
        Write-Err "Did not find expected output at $generated"
        exit 1
    }

    $skillMd = Join-Path $generated 'SKILL.md'
    if (-not (Test-Path $skillMd)) {
        Write-Err "Generated folder is missing SKILL.md at $skillMd"
        exit 1
    }

    Pop-Location
    $kiroSkills = Join-Path $HOME '.kiro\skills'
    $target     = Join-Path $kiroSkills 'ui-ux-pro-max'
    if (-not (Test-Path $kiroSkills)) { New-Item -ItemType Directory -Path $kiroSkills -Force | Out-Null }
    if (Test-Path $target) { Remove-Item -Recurse -Force $target }

    Write-Step "Installing to $target"
    Copy-Item -Recurse -Force $generated $target
} finally {
    if (Get-Location | Where-Object { $_.Path -eq $stage }) { Pop-Location }
    if (Test-Path $stage) { Remove-Item -Recurse -Force $stage -ErrorAction SilentlyContinue }
}

Write-Step 'Verifying installed skill'
$installedSkillMd = Join-Path $target 'SKILL.md'
if (-not (Test-Path $installedSkillMd)) {
    Write-Err "SKILL.md not found at $installedSkillMd"
    exit 1
}
$head = Get-Content $installedSkillMd -TotalCount 10 -ErrorAction Stop
$hasOpen   = ($head -match '^---\s*$').Count -ge 1
$hasName   = ($head -match '^name:\s*\S+').Count -ge 1
$hasDesc   = ($head -match '^description:\s*\S+').Count -ge 1
if (-not ($hasOpen -and $hasName -and $hasDesc)) {
    Write-Err 'SKILL.md is missing required YAML front-matter (name / description).'
    Write-Err 'Kiro Skills panel will NOT detect this skill. Aborting.'
    exit 1
}
Write-Ok 'SKILL.md has valid YAML front-matter (name, description)'

Write-Ok "Installed to $target"
Write-Host ''
Write-Host 'Restart Kiro (or reload window) to see ui-ux-pro-max under AGENT STEERING & SKILLS > Global.' -ForegroundColor Yellow
