# Proposal: Harden Skills for Cross-Tool Portability

**Created:** 2026-06-21
**Status:** Done
**Scope:** `.agents/skills/*/SKILL.md` (description fields), `scripts/setup-agy.ps1`, `docs/antigravity-cli-setup.md`, `CLAUDE.md`

## 1. Background

`.agents/skills/<name>/SKILL.md` is the canonical format used by Antigravity CLI (AGY), Cursor, and other AI tools. All three tools read the same `name:` + `description:` YAML frontmatter. Making the skills portable means: (a) fixing the description length, (b) syncing to each tool's global path.

## 2. Current State

- 20 skills total: 11 command + 9 knowledge
- AGY truncates skill bodies past **~500 lines** (documented in astro-dev-id reference project); our skills are 6–26 lines — safe
- `description:` field: astro-dev-id max is **190 chars**; our knowledge skills range from **243–371 chars** — likely causing silent truncation or parse failure in some tools
- `scripts/setup-agy.ps1` only syncs to `~/.gemini/antigravity-cli/skills/` and `~/.gemini/skills/`; does NOT sync to `~/.cursor/skills/`
- `docs/antigravity-cli-setup.md` still documents the old three-layer model with `workflows/` (stale since migration)

## 3. Problems

1. Knowledge skill descriptions are 296–371 chars — over the safe limit for cross-tool compatibility
2. Cursor users can't import skills from `.agents/skills/` without manual copy (no sync path)
3. Antigravity setup doc is stale (references removed `workflows/` layer)

## 4. Proposal

1. **Shorten all description fields to ≤200 chars** — trim verbose keyword lists; keep the semantic trigger words but remove repetition
2. **Add `~/.cursor/skills/` sync** to `setup-agy.ps1`
3. **Update `docs/antigravity-cli-setup.md`** — remove stale workflows layer, add Cursor path, document 500-line body limit
4. **Update `CLAUDE.md`** — add description length rule (≤200 chars) and body line limit (~500)

## 5. Implementation Order

1. Create this proposal (In Progress)
2. Shorten description fields in all 10 over-limit skills
3. Update `scripts/setup-agy.ps1` — add Cursor sync path
4. Update `docs/antigravity-cli-setup.md`
5. Update `CLAUDE.md`
6. Update this proposal to Done
