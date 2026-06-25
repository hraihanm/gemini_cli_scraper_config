<#
.SYNOPSIS
  Sync .agents/skills/<name>/SKILL.md -> .claude/commands/<name>.md

.DESCRIPTION
  Claude Code reads .claude/commands/<name>.md as the /<name> slash command prompt.
  This script strips the YAML frontmatter from each SKILL.md and writes the body
  to .claude/commands/. Re-run after adding or editing any skill.

  Works alongside setup-agy.ps1 (which syncs to agy global paths and Cursor).
  You can run both independently:
    pwsh -File scripts/setup-agy.ps1    # agy + Cursor
    pwsh -File scripts/sync-to-claude.ps1  # Claude Code

.EXAMPLE
  pwsh -NoProfile -File scripts/sync-to-claude.ps1
#>

$ErrorActionPreference = 'Stop'
$RepoRoot    = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$SkillsDir   = Join-Path $RepoRoot ".agents\skills"
$CommandsDir = Join-Path $RepoRoot ".claude\commands"

if (-not (Test-Path -LiteralPath $SkillsDir)) {
    throw "Skills directory not found: $SkillsDir"
}

if (-not (Test-Path -LiteralPath $CommandsDir)) {
    New-Item -ItemType Directory -Force -Path $CommandsDir | Out-Null
    Write-Host "Created $CommandsDir"
}

$count = 0
foreach ($skillDir in Get-ChildItem -LiteralPath $SkillsDir -Directory) {
    $skillFile = Join-Path $skillDir.FullName "SKILL.md"
    if (-not (Test-Path -LiteralPath $skillFile)) { continue }

    $raw  = Get-Content -LiteralPath $skillFile -Raw -Encoding UTF8
    # Strip YAML frontmatter: everything from start through the closing ---
    $body = $raw -replace '(?s)^---.*?---\r?\n', ''

    $outFile = Join-Path $CommandsDir "$($skillDir.Name).md"
    Set-Content -LiteralPath $outFile -Value $body -Encoding UTF8 -NoNewline
    Write-Host "  synced: $($skillDir.Name) -> .claude/commands/$($skillDir.Name).md"
    $count++
}

Write-Host ""
Write-Host "Done. Synced $count skills to .claude/commands/"
Write-Host "Restart Claude Code to pick up new/changed commands."
