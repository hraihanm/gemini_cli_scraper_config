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

## 6. Post-Implementation: YAML Frontmatter Pitfall

After migration, the 11 command skills did not appear in the AGY `/skills` panel even after restart and global sync. The 9 knowledge skills appeared fine.

**Root cause:** AGY parses `SKILL.md` frontmatter as YAML. In YAML, `[` and `]` are **flow-indicator characters** reserved for inline sequences — they are forbidden in unquoted plain scalars. All command skill descriptions contained usage strings with optional-arg notation, e.g.:

```
description: Phase 1 ... [project=dmart-dloc|dhero|...] [auto_next=true]
```

A strict YAML parser treats the `[` as the start of a flow sequence token, fails to parse the value, and the skill is silently dropped — no error surfaced in the TUI. The knowledge skills happened not to use `[...]` in their descriptions, so they parsed fine.

**Fix:** Double-quote all `description:` values that contain `[`, `]`, `{`, `}`, or `,`:

```yaml
description: "Phase 1 ... [project=dmart-dloc|dhero|...] [auto_next=true]"
```

**Rule added to `CLAUDE.md`:** Description values in `SKILL.md` must always be double-quoted. Commit: `d7388fa fix(skills): quote description values to fix YAML parsing of [optional-arg] syntax`.
