# Purpose: Initialize and update git submodules (specifically the wiki)
# Usage:   Run directly or via VS Code task: "Wiki: Init/Update Submodules"
# Notes:   Safe to run multiple times; it will sync and fetch the latest submodule mapping.

param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

Write-Host "[wiki-init] Syncing submodule URLs..." -ForegroundColor Cyan
git submodule sync | Out-Host

Write-Host "[wiki-init] Initializing/updating submodules (recursive)..." -ForegroundColor Cyan
git submodule update --init --recursive | Out-Host

Write-Host "[wiki-init] Done." -ForegroundColor Green
