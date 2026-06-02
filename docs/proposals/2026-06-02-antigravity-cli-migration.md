# Proposal: Migrate Gemini CLI → Antigravity CLI

**Created:** 2026-06-02
**Status:** Done
**Scope:** `.gemini/`, `GEMINI.md`, `scripts/chain.ps1`, `scripts/chain.sh`, `docs/shared/agent-rules-gemini.md`, `CLAUDE.md`

## 1. Background

Google deprecated Gemini CLI effective **June 18, 2026**. The replacement is **Antigravity CLI** (`agy`), announced at Google I/O 2026 as part of the Antigravity 2.0 platform. All free, Pro, and Ultra users must migrate by that date. Enterprise/paid-API users can continue on Gemini CLI temporarily, but the active toolchain here uses free/personal access.

## 2. Current State

| Concept | Gemini CLI path |
|---|---|
| Binary | `gemini` |
| Project context | `GEMINI.md` (persona) + `.gemini/system.md` (firmware, loaded via `GEMINI_SYSTEM_MD=1`) |
| MCP config | `.gemini/settings.json` |
| Slash commands | `.gemini/commands/*.toml` (10 active files) |
| Env vars | `GEMINI_API_KEY`, `GEMINI_MODEL`, `GEMINI_SYSTEM_MD` in `.gemini/.env` |
| Auto-chain scripts | `scripts/chain.ps1` / `chain.sh` — invoke `gemini -y -i "/<phase> ..."` |

The TOML slash commands use two Gemini-specific features with no Antigravity equivalent:
- `@{filepath}` — inline file-include into the prompt at invocation time
- `{{args}}` — substitutes the user's slash-command arguments

## 3. Problems

1. **Binary gone June 18** — `gemini` stops responding; chain scripts break immediately.
2. **Config directory** — Antigravity uses `.agents/` not `.gemini/`; config file is `mcp_config.json`.
3. **Project context** — `GEMINI.md` becomes `AGENTS.md`; the two-layer split (persona + firmware) collapses into one file since Antigravity has no `GEMINI_SYSTEM_MD` mechanism.
4. **Slash commands format** — `.gemini/commands/*.toml` → `.agents/skills/*.md`. Skills are static Markdown (YAML frontmatter + body); no `@{include}` or `{{args}}` templating. Agent reads shared docs via explicit `read_file` calls inside each skill body.
5. **Env vars** — `GEMINI_*` prefix → `AGY_*` prefix (`AGY_API_KEY`, `AGY_MODEL`). `GEMINI_SYSTEM_MD` has no equivalent (AGENTS.md is always loaded).
6. **MCP server `url` field** — Antigravity requires `serverUrl` for HTTP-based MCP servers. The playwright-mod uses `command`/`args` (not `url`) so this is unaffected, but documented for future servers.

### Known gap: `context.fileFiltering`

The old `.gemini/settings.json` had:
```json
"context": { "fileFiltering": { "respectGitIgnore": false, "respectGeminiIgnore": false } }
```
This allowed agents to read `.gitignore`d paths (`.scraper-state/`). The Antigravity equivalent config key is not yet documented publicly. If agents start failing to read `.scraper-state/` files, check Antigravity docs for `respectAgentsIgnore` or similar in `mcp_config.json`.

## 4. Proposal

### 4.1 New directory structure

```
.agents/
  config/
    mcp_config.json     ← .gemini/settings.json (mcpServers only; url→serverUrl for HTTP)
  skills/               ← .gemini/commands/*.toml converted to *.md
    scrape.md
    navigation-parser.md
    details-parser.md
    restaurant-details-parser.md
    menu-listings-parser.md
    menu-parser.md
    greenfield-scrape.md
    api-scrape.md
    api-navigation-parser.md
    api-details-parser.md
  .env                  ← .gemini/.env (GEMINI_* → AGY_*)
  .env.example
  system.md             ← .gemini/system.md (kept for reference; content merged into AGENTS.md)

AGENTS.md               ← merge of GEMINI.md + .gemini/system.md (updated refs)
```

### 4.2 Skill format

```markdown
---
name: <skill-name>
description: <full usage description — LLM uses this for semantic invocation matching>
---

<Phase description>. Session-independent.

## Preamble
1. `read_file` → `docs/shared/agent-rules-gemini.md`
2. `read_file` → `docs/shared/datahen-conventions.md`
[…additional shared docs as needed per skill…]

## Parse args
From the slash command invocation, extract: `param=` …

## Load profile and workflow
…

## Execute
…

## Auto-chain
…
```

The `@{docs/shared/X.md}` inlining is replaced by explicit `read_file` instructions. `{{args}}` is replaced by "From the slash command invocation, extract:".

### 4.3 Chain script update

```powershell
# Old
$command = "Set-Location -LiteralPath '$rootEsc'; gemini -y -i '$lineEsc'"
$LogDir  = Join-Path $RepoRoot ".gemini"

# New
$command = "Set-Location -LiteralPath '$rootEsc'; agy -y -i '$lineEsc'"
$LogDir  = Join-Path $RepoRoot ".agents"
```

> **Note:** `agy -y` flag assumed equivalent to `gemini -y`. Verify with `agy --help` — may be `-d` / `--dangerously-skip-permissions`. Same for `-i` (initial prompt flag).

### 4.4 `.gemini/` retention

The old `.gemini/` directory is left in place (not deleted) as a fallback reference. It becomes inert once the `gemini` binary stops responding on June 18. Remove it after confirming the Antigravity setup works.

## 5. Implementation Order

| Step | Action | Risk |
|---|---|---|
| 1 | Create `AGENTS.md` (merge + update refs) | Low |
| 2 | Create `.agents/config/mcp_config.json` | Low |
| 3 | Create `.agents/.env` + `.env.example` | Low |
| 4 | Create all 10 `.agents/skills/*.md` files | Medium (format change) |
| 5 | Update `scripts/chain.ps1` + `chain.sh` | Low |
| 6 | Update `docs/shared/agent-rules-gemini.md` | Low |
| 7 | Update `CLAUDE.md` | Low |
| 8 | Install `agy` and smoke-test `/scrape` | Medium |
