# Quick sanity check: required agent files exist. Optional: run gemini (commented).
# Usage: pwsh -File scripts/prompt-smoke.ps1
$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$required = @(
  ".gemini/system.md",
  "docs/shared/agent-rules-gemini.md",
  "docs/shared/datahen-conventions.md",
  "docs/workflows/phases/01-site-discovery.md",
  "profiles/dmart-dloc.toml",
  ".gemini/commands/scrape.toml",
  "scripts/chain.ps1"
)
$missing = @()
foreach ($rel in $required) {
  if (-not (Test-Path -LiteralPath (Join-Path $root $rel))) { $missing += $rel }
}
if ($missing.Count -gt 0) {
  Write-Host "FAIL: missing:" ($missing -join ", ")
  exit 1
}
Write-Host "OK: all required paths present under $root"
# Uncomment to run CLI (requires gemini in PATH):
# Set-Location $root; gemini -y -i "/scrape url=https://example.com name=smoke_test project=dmart-dloc auto_next=false"
