<#
.SYNOPSIS
  One-time (or repeat) Antigravity CLI setup for this repo.

.DESCRIPTION
  Workspace is the single source of truth:
    - .agents/skills/<name>/SKILL.md   -> all slash commands AND reusable knowledge
      (knowledge skills: semantic-loaded by description match)
      (command skills: invoked as /<name> slash commands)
  Running `agy` from the repo root auto-discovers both. This script additionally:
    - Syncs skills to agy global paths (so they are available from any cwd)
    - Re-stages the workspace plugin under .agents/plugins/gemini_cli_testbed/
      (bundles skills/) and runs `agy plugin install` for the
      playwright-mod MCP.

  Canonical layout (do NOT add flat *.md skills or a plugin.json at .agents/ root):
    .agents/skills/<name>/SKILL.md
    .agents/plugins/gemini_cli_testbed/plugin.json   (manifest only; skills/ is generated)

  NOTE: agy global paths are still being confirmed across releases
  (~/.gemini/antigravity-cli/ vs ~/.gemini/config/). Verify with `agy inspect`
  / `agy --help` if the Skills/commands panel is empty, and adjust $Global* below.
#>
param(
    [switch]$SkipPluginInstall
)

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$WorkspaceSkills = Join-Path $RepoRoot ".agents\skills"
$PluginRoot      = Join-Path $RepoRoot ".agents\plugins\gemini_cli_testbed"
$PluginSkills    = Join-Path $PluginRoot "skills"

$GlobalCliSkills    = Join-Path $env:USERPROFILE ".gemini\antigravity-cli\skills"
$GlobalSharedSkills = Join-Path $env:USERPROFILE ".gemini\skills"
$CursorSkills       = Join-Path $env:USERPROFILE ".cursor\skills"

if (-not (Test-Path -LiteralPath $WorkspaceSkills)) { throw "Missing $WorkspaceSkills" }

# Mirror every child of $SourceRoot into $DestinationRoot.
function Sync-Tree {
    param([string]$SourceRoot, [string]$DestinationRoot)
    if (-not (Test-Path -LiteralPath $DestinationRoot)) {
        New-Item -ItemType Directory -Path $DestinationRoot -Force | Out-Null
    }
    Get-ChildItem -LiteralPath $SourceRoot | ForEach-Object {
        $dest = Join-Path $DestinationRoot $_.Name
        if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
        Copy-Item -LiteralPath $_.FullName -Destination $dest -Recurse -Force
        Write-Host "  -> $dest"
    }
}

Write-Host "Syncing skills to global CLI path: $GlobalCliSkills"
Sync-Tree -SourceRoot $WorkspaceSkills -DestinationRoot $GlobalCliSkills
Write-Host "Syncing skills to shared global path: $GlobalSharedSkills"
Sync-Tree -SourceRoot $WorkspaceSkills -DestinationRoot $GlobalSharedSkills
Write-Host "Syncing skills to Cursor global path: $CursorSkills"
Sync-Tree -SourceRoot $WorkspaceSkills -DestinationRoot $CursorSkills

Write-Host "Syncing skills to Claude Code commands (.claude/commands/)..."
& pwsh -NoProfile -File (Join-Path $PSScriptRoot "sync-to-claude.ps1")

Write-Host "Staging plugin bundle: $PluginRoot"
if (Test-Path -LiteralPath $PluginSkills) { Remove-Item -LiteralPath $PluginSkills -Recurse -Force }
New-Item -ItemType Directory -Path $PluginSkills -Force | Out-Null
Sync-Tree -SourceRoot $WorkspaceSkills -DestinationRoot $PluginSkills

if (-not $SkipPluginInstall) {
    if (-not (Get-Command agy -ErrorAction SilentlyContinue)) {
        Write-Warning "agy not in PATH - skip plugin install. Install Antigravity CLI, then re-run."
    } else {
        Push-Location $RepoRoot
        try {
            Write-Host "Validating plugin..."
            agy plugin validate $PluginRoot
            Write-Host "Installing plugin (MCP + skills)..."
            agy plugin install $PluginRoot
            agy plugin list
        } finally {
            Pop-Location
        }
    }
}

Write-Host ""
Write-Host "Done. Restart agy from: $RepoRoot"
Write-Host "  - Slash commands: /scrape, /run-pipeline, /navigation-parser, /details-parser, /qa, ..."
Write-Host "  - Knowledge base: /kb loads docs/shared/KB_HUB.md (spokes read on demand)"
Write-Host "  - MCP: check /mcp for playwright-mod"
