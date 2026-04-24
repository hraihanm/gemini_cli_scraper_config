# Aggregate session-audit-*.json under generated_scraper into a CSV row per file.
# Usage: pwsh -File scripts/session-report.ps1 [path_to_generated_scraper]
param([string]$GeneratedRoot = "")
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
if (-not $GeneratedRoot) { $GeneratedRoot = Join-Path $repo "generated_scraper" }
if (-not (Test-Path -LiteralPath $GeneratedRoot)) {
  Write-Host "No generated_scraper at $GeneratedRoot"
  exit 0
}
$rows = @()
Get-ChildItem -Path $GeneratedRoot -Recurse -Filter "session-audit-*.json" -File | ForEach-Object {
  try {
    $j = Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json
    $tc = $j.tool_call_counts
    $sum = 0
    if ($tc) { $tc.PSObject.Properties | ForEach-Object { $sum += [int]$_.Value } }
    $rows += [pscustomobject]@{
      path            = $_.FullName
      phase           = $j.phase
      scraper         = $j.scraper
      completed_at    = $j.completed_at
      tool_calls_sum  = $sum
      incomplete_flag = [bool]$j.tool_call_counts_incomplete
    }
  } catch {
    $rows += [pscustomobject]@{ path = $_.FullName; phase = "PARSE_ERROR"; scraper = ""; completed_at = ""; tool_calls_sum = 0; incomplete_flag = $true }
  }
}
$out = Join-Path $repo ".gemini" "session-report.csv"
$rows | Export-Csv -NoTypeInformation -Encoding utf8 -Path $out
Write-Host "Wrote $out ($($rows.Count) rows)"
