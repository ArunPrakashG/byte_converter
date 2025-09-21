# Purpose: Pull latest changes from remote for wiki submodule and update superproject pointer
# Usage:   Run directly or via VS Code task: "Wiki: Pull latest"

param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not (Test-Path -LiteralPath "$(Join-Path $PSScriptRoot '..' 'wiki')")) {
  throw "Submodule folder 'wiki' not found. Run .scripts/wiki-init.ps1 first."
}

Push-Location (Join-Path $PSScriptRoot '..' 'wiki')
try {
  Write-Host "[wiki-pull] Fetching wiki submodule..." -ForegroundColor Cyan
  git fetch --all --tags | Out-Host

  Write-Host "[wiki-pull] Checking out default branch (origin/HEAD)..." -ForegroundColor Cyan
  $default = git symbolic-ref --short refs/remotes/origin/HEAD
  if (-not $default) { $default = 'origin/master' }
  $branch = $default -replace '^origin/',''

  git checkout $branch 2>$null | Out-Host
  git pull --ff-only | Out-Host
}
finally {
  Pop-Location
}

Write-Host "[wiki-pull] Updating superproject pointer..." -ForegroundColor Cyan
git add wiki | Out-Host
git commit -m "chore(wiki): update submodule to latest" 2>$null | Out-Host

Write-Host "[wiki-pull] Done." -ForegroundColor Green
