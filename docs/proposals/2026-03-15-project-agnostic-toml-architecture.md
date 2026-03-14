# Proposal: Project-Agnostic TOML Architecture with Multi-Agent Portability

**Created:** 2026-03-15
**Status:** Draft
**Scope:** `.gemini/commands/*.toml`, new `profiles/` directory, new `docs/workflows/` directory, cross-agent portability (Gemini CLI, Cursor, Windsurf)

---

## 1. Background

The current TOML commands (`dmart-scrape.toml`, `dmart-navigation-parser.toml`, etc.) are monolithic — they mix together:
- General workflow logic (phases, state machine, selector discovery protocol)
- DataHen V3 parser conventions
- Project-specific config (which template to copy, which boilerplate files to edit)
- Agent-specific execution rules (Gemini CLI tool names, PowerShell auto-chaining, forbidden Python patterns)

Adding a second project (`dhero`, `gmu`) today means duplicating all ~800 lines per TOML.
Porting to Cursor or Windsurf means rewriting everything.

---

## 2. Current State

### Structure
```
.gemini/commands/
  dmart-scrape.toml              # ~800 lines, Phase 1
  dmart-navigation-parser.toml   # ~900 lines, Phase 2
  dmart-details-parser.toml      # ~1200 lines, Phase 3
  dmart-api-scrape.toml          # ~700 lines
  dmart-api-navigation-parser.toml
  dmart-api-details-parser.toml
  dmart-fix-parser.toml
  dmart-analyze-phase.toml

templates/
  dmart_dloc_boilerplate/        # THE only boilerplate (hardcoded)
```

### What is hardcoded today (examples)
- `dmart-scrape.toml:27` — `"Copy entire templates/dmart_dloc_boilerplate/ directory"`
- `dmart-scrape.toml:111` — `xcopy /E /I /Y templates\\dmart_dloc_boilerplate generated_scraper\\<scraper_slug>`
- `dmart-scrape.toml:4` — `"using the dmart_dloc_boilerplate template"`
- All files assume `parsers/categories.rb`, `parsers/listings.rb`, `parsers/details.rb` exist (dmart structure)
- Auto-chaining always spawns `/dmart-navigation-parser` by name
- All completion reports say "Next Command: /dmart-navigation-parser"

---

## 3. Problems

1. **No multi-project support.** Adding `dhero` requires forking all 8 TOMLs.
2. **No agent portability.** Cursor/Windsurf use markdown rules files, not TOML. There is no shared logic to reference.
3. **Repeated content.** The ~40-line agent execution preamble (CRITICAL: YOU ARE IN GEMINI CLI...) appears in every TOML. Any fix requires editing 8 files.
4. **Implicit coupling.** The template name, parser file names, and next-command name are scattered across prose — hard to find, easy to miss.
5. **No override point.** There is nowhere to say "use `dhero_boilerplate` instead of `dmart_dloc_boilerplate`" without editing the full TOML body.

---

## 4. Proposal

### 4.1 Three-Layer Architecture

```
Layer 1: Core Workflow (agent-agnostic)
  docs/workflows/<phase>.md
  → Pure logic: what to do, in what order, what state to write
  → No tool names, no PowerShell, no Ruby gems

Layer 2: Project Profiles (project-specific config)
  profiles/<project>.toml  (or .json)
  → Which template to copy
  → Which boilerplate files exist and what to edit in each
  → Field-spec default path
  → Phase command names (for completion messages)
  → Output directory default

Layer 3: Agent Commands (agent-specific wrappers)
  .gemini/commands/<project>-<phase>.toml   ← Gemini CLI
  .cursor/rules/<project>-scraper.mdc       ← Cursor
  .windsurf/rules/<project>-scraper.md      ← Windsurf
  → Thin: just imports core workflow + profile, adds agent-specific execution context
```

### 4.2 New Directory Layout

```
profiles/
  dmart-dloc.toml       # dmart D-LOC project config
  dhero.toml            # DHero project config (future)
  gmu.toml              # GMU project config (future)

docs/workflows/
  phase1-site-discovery.md        # Core Phase 1 logic
  phase2-navigation-parser.md     # Core Phase 2 logic
  phase3-details-parser.md        # Core Phase 3 logic
  phase1-api-scrape.md            # Core API Phase 1 logic
  phase2-api-navigation.md        # Core API Phase 2 logic
  phase3-api-details.md           # Core API Phase 3 logic

docs/shared/
  agent-rules-gemini.md           # Gemini CLI execution preamble (shared across all TOMLs)
  agent-rules-cursor.md           # Cursor-specific execution context
  datahen-conventions.md          # DataHen V3 parser rules (referenced by workflows)
  selector-discovery-protocol.md  # browser_grep_html → inspect → verify workflow
  output-hash-rules.md            # 53-field output hash requirements

.gemini/commands/
  scrape.toml                     # Generic Phase 1 (takes project= param)
  navigation-parser.toml          # Generic Phase 2
  details-parser.toml             # Generic Phase 3
  api-scrape.toml
  api-navigation-parser.toml
  api-details-parser.toml
  fix-parser.toml
  analyze-phase.toml
  # Legacy dmart- commands become thin aliases (or removed after migration)

.cursor/rules/
  scraper-workflow.mdc            # Cursor rule file (imports core workflow docs)
```

### 4.3 Profile File Format

`profiles/dmart-dloc.toml`:
```toml
[project]
name = "dmart-dloc"
display_name = "D-Mart D-LOC"

[template]
boilerplate_dir = "templates/dmart_dloc_boilerplate"
copy_command_windows = "xcopy /E /I /Y templates\\dmart_dloc_boilerplate generated_scraper\\{scraper}"
copy_command_unix = "cp -r templates/dmart_dloc_boilerplate generated_scraper/{scraper}"

[boilerplate.files]
# Files that exist in the boilerplate and what role they play
headers_rb = "lib/headers.rb"          # update BASE_URL constant
seeder_rb = "seeder/seeder.rb"         # update url:, page_type:, fetch_type:
config_yaml = "config.yaml"            # verify only
parsers = ["parsers/categories.rb", "parsers/subcategories.rb", "parsers/listings.rb", "parsers/details.rb"]

[defaults]
field_spec = "spec_full.json"
output_dir = "./generated_scraper"

[commands]
# Phase command names — used in completion messages and auto_next chaining
phase1 = "scrape"
phase2 = "navigation-parser"
phase3 = "details-parser"
api_phase1 = "api-scrape"
api_phase2 = "api-navigation-parser"
api_phase3 = "api-details-parser"
```

### 4.4 Generic TOML Command (Slim)

The new `.gemini/commands/scrape.toml` becomes ~200 lines instead of ~800:

```toml
description = "Phase 1: Site discovery and boilerplate initialization."

prompt = """
{{include docs/shared/agent-rules-gemini.md}}

You are performing Phase 1: Site Discovery.

**Project Profile**: Load profile from `profiles/{{project}}.toml` where `project` comes from {{args}}.
If `project` not provided, use `dmart-dloc` as default.

**Core Workflow**: Follow the steps in `docs/workflows/phase1-site-discovery.md` exactly.
Replace any `{boilerplate_dir}`, `{scraper}`, `{phase2_command}` placeholders
with values from the loaded profile and {{args}}.

Inputs (via {{args}}):
  - url=<site_url> (REQUIRED)
  - name=<scraper_name> (REQUIRED)
  - project=<profile_name> (OPTIONAL, default: dmart-dloc)
  - spec=<path> (OPTIONAL, default from profile)
  - out=<base_dir> (OPTIONAL, default from profile)
  - auto_next=true|false (OPTIONAL, default: false)

{{include docs/shared/agent-rules-gemini.md#auto-chaining}}
"""
```

> **Note on `{{include}}`**: Gemini CLI does not natively support file includes in TOML prompts today. Two implementation options:
> - **Option A (short-term)**: Keep inline content but extract it into clearly labeled sections that are copy-pasted during updates. A build script (`scripts/build-tomls.sh`) assembles final TOMLs from partials.
> - **Option B (preferred long-term)**: The agent reads the workflow file as its first tool call (`read_file docs/workflows/phase1-site-discovery.md`) and follows it. The TOML just instructs "read and follow this workflow file."

### 4.5 Cursor / Windsurf Portability

For Cursor/Windsurf, create `.cursor/rules/scraper-workflow.mdc`:

```markdown
---
description: DataHen scraper generation workflow
globs: ["generated_scraper/**/*", "profiles/**/*"]
alwaysApply: false
---

# DataHen Scraper Generator

When the user asks to generate a scraper, follow the workflow in:
`docs/workflows/phase1-site-discovery.md`

## Tool Differences (Cursor vs Gemini CLI)
- Use built-in browser tools instead of `browser_grep_html` MCP
- Use file system tools instead of `read_file`/`write_file` MCP calls
- Auto-chaining is not needed — Cursor keeps conversation context

## Project Profile
Ask the user: "Which project profile? (dmart-dloc / dhero / gmu)"
Then load `profiles/<project>.toml` for template and file paths.
```

The `docs/workflows/` files become the **single source of truth** that all agents reference — Gemini reads them via `read_file`, Cursor/Windsurf reference them via rule includes.

### 4.6 Migration Path (Backward Compatible)

Keep the existing `dmart-*.toml` commands working as thin aliases:

```toml
# .gemini/commands/dmart-scrape.toml (alias)
description = "Alias for /scrape with project=dmart-dloc"
prompt = """
This is an alias. Execute /scrape with project=dmart-dloc and all provided {{args}}.
Equivalent to: /scrape project=dmart-dloc {{args}}
"""
```

---

## 5. Implementation Order

| Step | Description | Effort | Risk |
|------|-------------|--------|------|
| 1 | Extract `docs/shared/agent-rules-gemini.md` (the CRITICAL preamble) | Low | Low |
| 2 | Extract `docs/shared/datahen-conventions.md` and `selector-discovery-protocol.md` | Low | Low |
| 3 | Create `profiles/dmart-dloc.toml` with all current hardcoded values | Low | Low |
| 4 | Extract `docs/workflows/phase1-site-discovery.md` from dmart-scrape.toml | Medium | Medium |
| 5 | Extract `docs/workflows/phase2-navigation-parser.md` | Medium | Medium |
| 6 | Extract `docs/workflows/phase3-details-parser.md` | Medium | Medium |
| 7 | Rewrite `.gemini/commands/scrape.toml` to load profile + workflow | Medium | Medium |
| 8 | Rewrite navigation-parser and details-parser TOMLs | Medium | Medium |
| 9 | Add `dmart-*.toml` as aliases (backward compat) | Low | Low |
| 10 | Create `profiles/dhero.toml` (second project, validates the model) | Low | Low |
| 11 | Create `.cursor/rules/scraper-workflow.mdc` | Medium | Low |
| 12 | API TOMLs (api-scrape, api-navigation, api-details) | Medium | Medium |
| 13 | Remove alias TOMLs once team is migrated | Low | Low |

**Recommended starting point**: Steps 1–3 (pure extraction, zero risk) then Step 7 (new generic scrape.toml) tested against a real run before touching the other phases.

---

## 6. Key Design Decisions

### Q: Should workflow files be Markdown or TOML?
**Markdown.** The agent reads them as instructions. TOML is for machine-parseable config (profiles). Mixing them adds cognitive overhead.

### Q: Should `project=` be a separate param or inferred from `name=`?
**Separate param with default.** Scraper name (e.g., `naivas_online`) doesn't imply the project profile. Default to `dmart-dloc` for backward compatibility.

### Q: Should we use a build script to assemble TOMLs, or have the agent read files at runtime?
**Runtime read (preferred).** Build scripts add a dev step that will be forgotten. The agent calling `read_file` on workflow docs is simpler, more transparent, and works identically across agents. The slight token overhead (reading a 2KB markdown file) is negligible vs the maintenance benefit.

### Q: How does Cursor/Windsurf get the same workflow without MCP tool access?
The `docs/workflows/` files are plain markdown. Cursor reads them as context files (via `@docs/workflows/phase1-site-discovery.md`). Windsurf uses `@file` references. The core workflow is the same — only the tool execution layer differs, documented in `docs/shared/agent-rules-cursor.md`.
