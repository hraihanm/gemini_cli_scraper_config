<#
  Spawn next Antigravity CLI (agy) phase from repo root. Used by auto_next workflows.
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
$LogDir = Join-Path $RepoRoot ".agents"
if (-not (Test-Path -LiteralPath $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }
$LogPath = Join-Path $LogDir "auto-chain.log"
$AgyCmdLine = "/$Phase scraper=$Scraper project=$Project auto_next=$AutoNext"

$stamp = Get-Date -Format "o"
Add-Content -LiteralPath $LogPath -Value "[$stamp] chain.ps1 cwd=$RepoRoot cmd=$AgyCmdLine" -Encoding utf8

$rootEsc = $RepoRoot.Replace("'", "''")
$lineEsc = $AgyCmdLine.Replace("'", "''")
# NOTE: verify flags with `agy --help` — -y (auto-confirm) may map to -d/--dangerously-skip-permissions
$command = "Set-Location -LiteralPath '$rootEsc'; agy -y -i '$lineEsc'"

try {
  Start-Process -FilePath "pwsh" -ArgumentList @("-NoExit", "-NoProfile", "-Command", $command) -WorkingDirectory $RepoRoot
} catch {
  Add-Content -LiteralPath $LogPath -Value "[$stamp] ERROR: $($_.Exception.Message)" -Encoding utf8
  Write-Host "AUTO_CHAIN_FAILED: run manually: agy -y -i `"$AgyCmdLine`""
  exit 1
}
