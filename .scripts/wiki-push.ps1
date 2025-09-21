# Purpose: Commit and push changes inside the wiki submodule, then update the superproject pointer
# Usage:   Run directly or via VS Code task: "Wiki: Commit & Push"
# Params:  -Message "Your commit message" (optional; prompts if omitted)

param(
  [string]$Message
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not (Test-Path -LiteralPath "$(Join-Path $PSScriptRoot '..' 'wiki')")) {
  throw "Submodule folder 'wiki' not found. Run .scripts/wiki-init.ps1 first."
}

if (-not $Message -or $Message.Trim().Length -eq 0) {
  $Message = Read-Host "Enter commit message for wiki"
}

Push-Location (Join-Path $PSScriptRoot '..' 'wiki')
try {
  Write-Host "[wiki-push] Adding changes in wiki/ ..." -ForegroundColor Cyan
  git add -A | Out-Host

  $pending = git status --porcelain
  if ($pending) {
    Write-Host "[wiki-push] Committing to wiki submodule..." -ForegroundColor Cyan
    git commit -m $Message | Out-Host
    Write-Host "[wiki-push] Pushing to wiki remote..." -ForegroundColor Cyan
    git push | Out-Host
  } else {
    Write-Host "[wiki-push] No changes to commit in wiki." -ForegroundColor Yellow
  }
}
finally {
  Pop-Location
}

Write-Host "[wiki-push] Updating superproject pointer..." -ForegroundColor Cyan
git add wiki | Out-Host
git commit -m "chore(wiki): update submodule ref" 2>$null | Out-Host

Write-Host "[wiki-push] Done." -ForegroundColor Green
