#!/usr/bin/env pwsh
# Install UI/UX PRO MAX skill for Kiro IDE (Windows)
# Upstream: https://github.com/nextlevelbuilder/ui-ux-pro-max-skill

$ErrorActionPreference = 'Stop'

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
npm install -g uipro-cli
if ($LASTEXITCODE -ne 0) { Write-Err 'Failed to install uipro-cli'; exit 1 }

# uipro-cli only installs into the current working directory. Run it in a
# temp folder, then move the generated skill into ~/.kiro/skills/.
$stage = Join-Path $env:TEMP ("uipro-stage-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage -Force | Out-Null
try {
    Push-Location $stage
    Write-Step 'Running: uipro init --ai kiro --force'
    uipro init --ai kiro --force
    if ($LASTEXITCODE -ne 0) { Write-Err 'uipro init failed'; exit 1 }

    $generated = Join-Path $stage '.kiro\steering\ui-ux-pro-max'
    if (-not (Test-Path $generated)) {
        Write-Err "Did not find expected output at $generated"
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

Write-Ok "Installed to $target"
Write-Host ''
Write-Host 'Restart Kiro (or reload window) to see ui-ux-pro-max under AGENT STEERING & SKILLS > Global.' -ForegroundColor Yellow
