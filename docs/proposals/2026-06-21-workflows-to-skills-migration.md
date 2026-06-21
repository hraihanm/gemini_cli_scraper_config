# Proposal: Migrate Workflows to Skills for AGY Slash Command Registration

**Created:** 2026-06-21
**Status:** Done
**Scope:** `.agents/workflows/` → `.agents/skills/`, `scripts/setup-agy.ps1`, `CLAUDE.md`

## 1. Background
AGY (Antigravity CLI) does not have a "workflows" concept. All slash commands come from skills. The AGY docs state: "Skills convert automatically into slash commands inside the TUI."

## 2. Current State
- 11 workflow files live in `.agents/workflows/<name>.md`
- AGY auto-discovers `.agents/skills/<name>/SKILL.md` (working — 10 skills show in panel)
- AGY has no auto-discovery for `.agents/workflows/`
- `setup-agy.ps1` syncs workflows to `~/.gemini/antigravity-cli/workflows/` — a path AGY does not support
- Plugin is not installed; even if installed, setup script copies workflows to `plugins/.../workflows/` but AGY's plugin structure only supports `skills/`, `agents/`, `rules/`
- Result: `/scrape`, `/navigation-parser`, etc. never appear as slash commands

## 3. Problem
Workflow files are in a directory AGY ignores. The slash commands are missing from the TUI.

## 4. Proposal
Move all 11 workflow `.md` files into `.agents/skills/<name>/SKILL.md` with `name:` added to frontmatter. Update `setup-agy.ps1` to drop the dead workflow sync. Update `CLAUDE.md` to reflect that the "workflows" layer no longer exists — skills cover both knowledge and command orchestration.

## 5. Implementation Order

1. Create `docs/proposals/2026-06-21-workflows-to-skills-migration.md` (this file, In Progress)
2. Write 11 `skills/<name>/SKILL.md` files with `name:` frontmatter added
3. Delete `.agents/workflows/` directory
4. Update `scripts/setup-agy.ps1` — remove `$GlobalCliWorkflows` sync and `$PluginWorkflows` copy
5. Update `CLAUDE.md` — collapse "Workflows" layer into "Skills", update paths
6. Update this proposal to Done
