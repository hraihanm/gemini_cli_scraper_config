# Quick sanity check: required agent files exist. Optional: run agy (commented).
# Usage: pwsh -File scripts/prompt-smoke.ps1
$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$required = @(
  "AGENTS.md",
  "docs/shared/agent-rules-gemini.md",
  "docs/shared/datahen-conventions.md",
  "docs/shared/KB_HUB.md",
  "docs/workflows/phases/01-site-discovery.md",
  "profiles/dmart-dloc.toml",
  ".agents/skills/scrape/SKILL.md",
  ".agents/skills/run-pipeline/SKILL.md",
  ".agents/skills/kb/SKILL.md",
  ".agents/mcp_config.json"
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
# Uncomment to run CLI (requires agy in PATH):
# Set-Location $root; agy --dangerously-skip-permissions --prompt-interactive "/scrape url=https://example.com name=smoke_test project=dmart-dloc auto_next=false"
