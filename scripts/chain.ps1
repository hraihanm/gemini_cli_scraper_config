<#
  Spawn next Gemini CLI phase from repo root. Used by auto_next workflows.
  Example: pwsh -NoProfile -File scripts/chain.ps1 -Phase navigation-parser -Scraper mysite -Project dmart-dloc
#>
param(
  [Parameter(Mandatory = $true)][string]$Phase,
  [Parameter(Mandatory = $true)][string]$Scraper,
  [Parameter(Mandatory = $true)][string]$Project,
  [string]$AutoNext = "true"
)

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$LogDir = Join-Path $RepoRoot ".gemini"
if (-not (Test-Path -LiteralPath $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }
$LogPath = Join-Path $LogDir "auto-chain.log"
$GeminiLine = "/$Phase scraper=$Scraper project=$Project auto_next=$AutoNext"

$stamp = Get-Date -Format "o"
Add-Content -LiteralPath $LogPath -Value "[$stamp] chain.ps1 cwd=$RepoRoot cmd=$GeminiLine" -Encoding utf8

$rootEsc = $RepoRoot.Replace("'", "''")
$lineEsc = $GeminiLine.Replace("'", "''")
$command = "Set-Location -LiteralPath '$rootEsc'; gemini -y -i '$lineEsc'"

try {
  Start-Process -FilePath "pwsh" -ArgumentList @("-NoExit", "-NoProfile", "-Command", $command) -WorkingDirectory $RepoRoot
} catch {
  Add-Content -LiteralPath $LogPath -Value "[$stamp] ERROR: $($_.Exception.Message)" -Encoding utf8
  Write-Host "AUTO_CHAIN_FAILED: run manually: gemini -y -i `"$GeminiLine`""
  exit 1
}
