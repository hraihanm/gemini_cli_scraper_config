# Proposal: Multi-Project Modular Pipelines

**Created:** 2026-04-05
**Status:** Done
**Scope:** `profiles/`, `docs/workflows/phases/`, `.gemini/commands/`, `templates/`

---

## 1. Background

The 2026-03-15 proposal established the three-layer architecture:
- Layer 1: `docs/workflows/` — agent-agnostic phase logic
- Layer 2: `profiles/` — project-specific config
- Layer 3: `.gemini/commands/` — thin Gemini CLI wrappers

That proposal was never implemented. This proposal extends it with the **variable-depth pipeline** concept required by projects like `dhero`, where the phase sequence differs from `dmart`.

**dmart pipeline:** `scrape → navigation-parser → details-parser`
**dhero pipeline:** `scrape → navigation-parser → restaurant-details-parser → menu-parser`

The dhero menu phase is genuinely different: it fetches menu item listings per restaurant, not product details. The number and types of phases are project-defined.

---

## 2. Current State

- All 8 TOML commands are `dmart`-prefixed monoliths (~800–1200 lines each)
- Hardcoded pipeline: every TOML chains to the next `dmart-*` command by name
- No profile system exists; boilerplate path, parser file names, and command names are scattered inline
- Adding `dhero` today means duplicating all 8 TOMLs and hand-editing ~50 hardcoded references per file
- The CRITICAL preamble (YOU ARE IN GEMINI CLI) is repeated verbatim in all 8 files

---

## 3. Problems

1. **No multi-project support** — adding dhero requires forking all TOMLs
2. **Fixed pipeline depth** — no mechanism for a 4-phase project
3. **No phase extensibility** — dhero's `menu-parser` phase type doesn't exist as a concept
4. **Preamble drift** — CRITICAL rules updated in one TOML don't propagate to others
5. **Auto-chaining is hardcoded** — `auto_next` always spawns `/dmart-navigation-parser` regardless of project

---

## 4. Proposal

### 4.1 Core Idea: Profiles Define the Pipeline

A project profile is the single source of truth for:
- What phases exist, in what order
- What workflow doc governs each phase
- What boilerplate template to use
- What parser files exist in that project's boilerplate

The agent's job is: **read profile → find current phase → follow its workflow doc → chain to next phase in profile**.

### 4.2 Directory Layout

```
profiles/
  dmart-dloc.toml           # D-Mart DLOC project profile
  dhero.toml                # DHero restaurants project profile

docs/workflows/
  phases/
    01-site-discovery.md        # Phase: scrape (any project)
    02-navigation-parser.md     # Phase: navigation-parser (any project)
    03-details-parser.md        # Phase: details-parser (dmart-style products)
    03-restaurant-details.md    # Phase: restaurant-details-parser (dhero)
    04-menu-parser.md           # Phase: menu-parser (dhero extra phase)
    api-01-scrape.md            # API variant phases
    api-02-navigation.md
    api-03-details.md
  shared/
    agent-rules-gemini.md       # CRITICAL preamble — shared across all TOMLs
    datahen-conventions.md      # DataHen V3 parser rules
    selector-discovery.md       # browser_grep_html → inspect → verify protocol
    output-hash-rules.md        # 53-field requirement

templates/
  dmart_dloc_boilerplate/       # existing
  dhero_boilerplate/            # new: listings.rb, restaurant_details.rb, menu.rb

.gemini/commands/
  # Generic commands (project= param selects profile)
  scrape.toml
  navigation-parser.toml
  details-parser.toml
  menu-parser.toml              # NEW: dhero-specific phase type
  api-scrape.toml
  api-navigation-parser.toml
  api-details-parser.toml
  fix-parser.toml
  analyze-phase.toml
  rebuild.toml

  # Project aliases (thin wrappers — backward compat + ergonomics)
  dmart-scrape.toml             # → /scrape project=dmart-dloc
  dmart-navigation-parser.toml  # → /navigation-parser project=dmart-dloc
  dmart-details-parser.toml     # → /details-parser project=dmart-dloc
  dhero-scrape.toml             # → /scrape project=dhero
  dhero-navigation-parser.toml  # → /navigation-parser project=dhero
  dhero-restaurant-details.toml # → /details-parser project=dhero
  dhero-menu-parser.toml        # → /menu-parser project=dhero
```

### 4.3 Profile File Format

#### `profiles/dmart-dloc.toml`

```toml
[project]
name = "dmart-dloc"
display_name = "D-Mart D-LOC"

[template]
boilerplate_dir = "templates/dmart_dloc_boilerplate"
copy_command_windows = 'xcopy /E /I /Y templates\dmart_dloc_boilerplate generated_scraper\{scraper}'
copy_command_unix    = "cp -r templates/dmart_dloc_boilerplate generated_scraper/{scraper}"

[boilerplate]
seeder_rb    = "seeder/seeder.rb"
headers_rb   = "lib/headers.rb"
config_yaml  = "config.yaml"
parsers      = ["parsers/categories.rb", "parsers/listings.rb", "parsers/details.rb"]

[pipeline]
# Ordered phase sequence for this project
# phase = the /command name to invoke
# workflow = the workflow doc the agent reads
# label = human-readable name for completion messages
phases = [
  { phase = "scrape",              workflow = "docs/workflows/phases/01-site-discovery.md",    label = "Phase 1: Site Discovery"       },
  { phase = "navigation-parser",   workflow = "docs/workflows/phases/02-navigation-parser.md", label = "Phase 2: Navigation Parser"    },
  { phase = "details-parser",      workflow = "docs/workflows/phases/03-details-parser.md",    label = "Phase 3: Details Parser"       },
]

[defaults]
field_spec = "spec_full.json"
output_dir = "./generated_scraper"
```

#### `profiles/dhero.toml`

```toml
[project]
name = "dhero"
display_name = "DHero Restaurants"

[template]
boilerplate_dir = "templates/dhero_boilerplate"
copy_command_windows = 'xcopy /E /I /Y templates\dhero_boilerplate generated_scraper\{scraper}'
copy_command_unix    = "cp -r templates/dhero_boilerplate generated_scraper/{scraper}"

[boilerplate]
seeder_rb    = "seeder/seeder.rb"
headers_rb   = "lib/headers.rb"
config_yaml  = "config.yaml"
# Note: details.rb → restaurant_details.rb; extra menu.rb phase
parsers      = ["parsers/listings.rb", "parsers/restaurant_details.rb", "parsers/menu.rb"]

[pipeline]
phases = [
  { phase = "scrape",                    workflow = "docs/workflows/phases/01-site-discovery.md",       label = "Phase 1: Site Discovery"            },
  { phase = "navigation-parser",         workflow = "docs/workflows/phases/02-navigation-parser.md",    label = "Phase 2: Navigation Parser"         },
  { phase = "restaurant-details-parser", workflow = "docs/workflows/phases/03-restaurant-details.md",   label = "Phase 3: Restaurant Details Parser" },
  { phase = "menu-parser",               workflow = "docs/workflows/phases/04-menu-parser.md",           label = "Phase 4: Menu Parser"               },
]

[defaults]
field_spec = "spec_full.json"
output_dir = "./generated_scraper"
```

### 4.4 How Generic TOML Commands Work

Each generic TOML command:
1. Reads `docs/shared/agent-rules-gemini.md` (preamble — one source of truth)
2. Determines the project from `project=` arg (default: `dmart-dloc`)
3. Reads `profiles/<project>.toml` to get: boilerplate paths, pipeline definition, field spec
4. Finds its own phase in the pipeline array (by matching `phase` field to this command's name)
5. Reads the corresponding `workflow` doc and executes it
6. On completion: reads pipeline to find `phase[i+1]` — uses that as the auto_next target

**Key insight:** auto-chaining doesn't hardcode `/dmart-navigation-parser`. It looks up `pipeline[current_index + 1].phase` from the profile. This works for any project with any pipeline depth.

#### Skeleton for `scrape.toml`

```toml
description = "Phase 1: Site discovery and boilerplate initialization (any project)."

prompt = """
{{content of docs/shared/agent-rules-gemini.md}}

## Your Task

You are executing a scraper pipeline phase.

**Step 1 — Load inputs**
Parse {{args}}:
  - url=<site_url>    (REQUIRED)
  - name=<scraper>    (REQUIRED)
  - project=<profile> (OPTIONAL, default: dmart-dloc)
  - spec=<path>       (OPTIONAL)
  - out=<dir>         (OPTIONAL)
  - auto_next=true|false (OPTIONAL, default: false)

**Step 2 — Load profile**
Read file: `profiles/<project>.toml`
Extract: boilerplate paths, pipeline array, defaults.

**Step 3 — Find this phase in the pipeline**
This command is phase `scrape`.
Locate `{ phase = "scrape", workflow = "...", label = "..." }` in the pipeline.
Note the workflow doc path and the NEXT phase (pipeline index + 1).

**Step 4 — Execute workflow**
Read the workflow doc identified in Step 3.
Follow every step in that doc exactly, substituting:
  - {boilerplate_dir}  from profile
  - {scraper}          from args
  - {parsers}          from profile boilerplate.parsers list
  - {field_spec}       from args or profile default
  - {output_dir}       from args or profile default

**Step 5 — Auto-chain (if auto_next=true)**
After completion, read the pipeline again.
Find the phase AFTER `scrape` (pipeline[current_index + 1]).
Spawn: `/<next_phase> project=<project> name=<scraper> auto_next=true`
"""
```

The same pattern applies to `navigation-parser.toml`, `details-parser.toml`, `menu-parser.toml`, etc.

### 4.5 Phase Workflow Docs

`docs/workflows/phases/04-menu-parser.md` — dhero-specific phase — would contain:

```markdown
# Phase 4: Menu Parser

## Context
You are parsing per-restaurant menu item listings.
State: restaurant URLs were saved in discovery-state.json by Phase 3.

## Inputs from state
- Read `generated_scraper/{scraper}/.scraper-state/restaurant-details-state.json`
- Extract: array of restaurant detail page URLs

## What this phase builds
- `parsers/menu.rb`: extracts menu item fields per restaurant
  Fields: name, description, price, currency, category_name, img_url, is_available

## Steps
1. Read restaurant-details-state.json for sample restaurant URLs
2. Navigate to 3 sample restaurant pages
3. Discover menu item container selectors using browser_grep_html
4. Determine pagination: infinite scroll vs "load more" vs paginated API
5. Check for JSON-LD or embedded JSON (window.__NEXT_DATA__, etc.) before CSS
6. Write parsers/menu.rb following DataHen V3 conventions
7. Test with parser_tester against 3 restaurant pages
8. Write menu-knowledge.md summary
```

### 4.6 Shared Agent Rules (Single Source of Truth)

`docs/shared/agent-rules-gemini.md` contains the entire CRITICAL preamble currently copy-pasted across all 8 TOMLs. Every TOML embeds it once by reference (or by explicit copy at build time).

When the preamble needs updating, edit one file. All TOMLs get the fix.

### 4.7 Project Alias TOMLs

Thin wrappers for ergonomics:

```toml
# .gemini/commands/dhero-menu-parser.toml
description = "DHero Phase 4: Menu parser. Alias for /menu-parser project=dhero."

prompt = """
This is an alias. You are running /menu-parser with project=dhero.

Load profile: profiles/dhero.toml
Read this phase's workflow: docs/workflows/phases/04-menu-parser.md
Apply all args passed: {{args}}

Follow the generic menu-parser workflow exactly.
"""
```

Aliases let users type `/dhero-menu-parser` as a shortcut. They also serve as the backward-compat bridge for existing `/dmart-*` users during migration.

### 4.8 Auto-Chaining Across Variable-Length Pipelines

The key rule in every TOML's auto-chain section:

```
DO NOT hardcode the next command name.
Read profiles/<project>.toml → find pipeline array → find current phase by name →
next_phase = pipeline[current_index + 1].phase
Spawn: /<next_phase> project=<project> name=<scraper> auto_next=true

If current phase is the LAST in the pipeline: display completion summary only, no chaining.
```

This means dhero's Phase 3 (`restaurant-details-parser`) automatically chains to Phase 4 (`menu-parser`) without any hardcoding. dmart's Phase 3 (`details-parser`) terminates the pipeline (it's last).

---

## 5. Implementation Order

| Step | Action | Effort | Risk |
|------|--------|--------|------|
| 1 | Extract `docs/shared/agent-rules-gemini.md` from any existing TOML | Low | None |
| 2 | Extract `docs/shared/datahen-conventions.md` + `selector-discovery.md` | Low | None |
| 3 | Write `profiles/dmart-dloc.toml` with current hardcoded values | Low | None |
| 4 | Rewrite `dmart-scrape.toml` → `scrape.toml` (reads profile + workflow) | Medium | Medium |
| 5 | Extract `docs/workflows/phases/01-site-discovery.md` from dmart-scrape.toml | Medium | Medium |
| 6 | Test: run `/scrape project=dmart-dloc` against a live site | Medium | Medium |
| 7 | Rewrite `navigation-parser.toml` + extract workflow doc | Medium | Medium |
| 8 | Rewrite `details-parser.toml` + extract workflow doc | Medium | Medium |
| 9 | Test full dmart pipeline end-to-end before touching dhero | Medium | Low |
| 10 | Write `profiles/dhero.toml` | Low | None |
| 11 | Write `templates/dhero_boilerplate/` (listings, restaurant_details, menu stubs) | Medium | Low |
| 12 | Write `docs/workflows/phases/03-restaurant-details.md` | Medium | Low |
| 13 | Write `docs/workflows/phases/04-menu-parser.md` | Medium | Low |
| 14 | Write `menu-parser.toml` (generic) + `dhero-menu-parser.toml` (alias) | Low | Low |
| 15 | Add `dmart-*.toml` aliases (thin wrappers for backward compat) | Low | None |
| 16 | API pipeline: same pattern, `profiles/<project>.toml` adds `[api_pipeline]` section | Medium | Low |

**Recommended starting point:** Steps 1–3 (zero risk, pure extraction) → Steps 4–6 (validate the profile-loading pattern on a real run) → then proceed.

---

## 6. Key Design Decisions

### Q: Should generic commands live at `/scrape` or `/run phase=scrape`?
**Separate commands per phase type** (`/scrape`, `/navigation-parser`, etc.). More discoverable, easier to invoke manually, and matches the existing command-per-phase mental model.

### Q: Does dhero need entirely new TOML commands, or reuse existing ones?
**Reuse generic commands, add phase-specific command only for new phase types.** `/scrape` and `/navigation-parser` work for dhero unchanged — only `menu-parser` is new. The alias `/dhero-menu-parser` is a thin wrapper.

### Q: Where does the API pipeline live in the profile?
Add an `[api_pipeline]` section alongside `[pipeline]` in each profile. The commands `/api-scrape`, `/api-navigation-parser`, `/api-details-parser` load `api_pipeline` instead of `pipeline`.

### Q: What if a project only has 2 phases (listing + details, no navigation)?
The pipeline array can have any length. A 2-phase project just omits navigation-parser. The auto-chain logic handles it automatically.

### Q: How does the agent know which profile to load when none is specified?
Default to `dmart-dloc` unless the command is a project alias (in which case the alias hardcodes the project). This preserves backward compatibility.
