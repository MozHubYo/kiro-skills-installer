#!/usr/bin/env pwsh
# Install Playwright CLI skill for Kiro IDE (Windows)
# Upstream: https://github.com/microsoft/playwright-cli

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

Write-Step 'Installing @playwright/cli globally'
npm install -g '@playwright/cli@latest' 2>&1 | ForEach-Object { "$_" } | Out-Host
if ($LASTEXITCODE -ne 0) { Write-Err 'Failed to install @playwright/cli'; exit 1 }

# `playwright-cli install --skills` installs into the CURRENT working directory
# (e.g. ./.claude/skills/playwright-cli), not ~/.claude/skills/. Run it in a
# temp folder, then mirror the skill into ~/.kiro/skills/.
$stage = Join-Path $env:TEMP ("pwcli-stage-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage -Force | Out-Null
try {
    Push-Location $stage
    Write-Step 'Running: playwright-cli install --skills'
    playwright-cli install --skills 2>&1 | ForEach-Object { "$_" } | Out-Host
    if ($LASTEXITCODE -ne 0) { Write-Err 'playwright-cli install --skills failed'; exit 1 }

    $candidates = @(
        (Join-Path $stage '.claude\skills\playwright-cli'),
        (Join-Path $stage '.copilot\skills\playwright-cli'),
        (Join-Path $stage '.github\copilot\skills\playwright-cli')
    )
    $source = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $source) {
        Write-Err 'Could not find an installed playwright-cli skill to copy into Kiro.'
        Write-Err 'Checked:'
        $candidates | ForEach-Object { Write-Host "  - $_" }
        exit 1
    }

    $sourceSkillMd = Join-Path $source 'SKILL.md'
    if (-not (Test-Path $sourceSkillMd)) {
        Write-Err "Generated folder is missing SKILL.md at $sourceSkillMd"
        exit 1
    }
    Write-Step "Mirroring skill from: $source"

    Pop-Location
    $kiroSkills = Join-Path $HOME '.kiro\skills'
    $target     = Join-Path $kiroSkills 'playwright-cli'
    if (-not (Test-Path $kiroSkills)) { New-Item -ItemType Directory -Path $kiroSkills -Force | Out-Null }
    if (Test-Path $target) { Remove-Item -Recurse -Force $target }
    Copy-Item -Recurse -Force $source $target
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
$hasOpen = ($head -match '^---\s*$').Count -ge 1
$hasName = ($head -match '^name:\s*\S+').Count -ge 1
$hasDesc = ($head -match '^description:\s*\S+').Count -ge 1
if (-not ($hasOpen -and $hasName -and $hasDesc)) {
    Write-Err 'SKILL.md is missing required YAML front-matter (name / description).'
    Write-Err 'Kiro Skills panel will NOT detect this skill. Aborting.'
    exit 1
}
Write-Ok 'SKILL.md has valid YAML front-matter (name, description)'

Write-Ok "Installed to $target"
Write-Host ''
Write-Host 'Restart Kiro (or reload window) to see playwright-cli under AGENT STEERING & SKILLS > Global.' -ForegroundColor Yellow
