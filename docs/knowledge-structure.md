# Knowledge Structure

This document explains where different types of knowledge live in this repo and which agents read each layer.

---

## The Two Agent Systems

| Agent | Entry point | Purpose |
|---|---|---|
| **Claude Code** (you) | `CLAUDE.md` | Planning, code review, boilerplate authoring, cross-session memory |
| **Gemini CLI** | `GEMINI.md` + TOML commands | Executing the scraping pipeline: discovery → parsers → testing |

Both agents share the same codebase and `docs/` folder. Knowledge placed in `docs/shared/` is accessible to both.

---

## Knowledge Layers

### 1. Agent Persona / Session Rules

| File | Read by | Purpose |
|---|---|---|
| `CLAUDE.md` | Claude Code only | Mandatory rules: proposal lifecycle, parser conventions, tool protocols, memory pointer |
| `GEMINI.md` | Gemini CLI only | Persona and competency frame: e-commerce expertise, PARSE methodology |

These are loaded automatically at session start. **CLAUDE.md overrides Claude's defaults; GEMINI.md sets Gemini's expertise frame.** Neither is imported by the other agent.

---

### 2. Shared Knowledge Base — `docs/shared/`

Factual, reusable rules loaded into the Gemini agent via TOML `@`-imports and referenced from `CLAUDE.md`. Authoritative for both agents.

| File | Content |
|---|---|
| `agent-rules-gemini.md` | Browser tool safety, popup handling, error taxonomy (Transient / Structural / Data gap) |
| `datahen-conventions.md` | V3 parser structure: top-level scripts, reserved variables (`pages`, `outputs`, `page`, `content`), state file logging, `_log` schema |
| `datahen-ruby-parsers.md` | Pre-loaded gems (nokogiri, json, digest — never `require`), error handling patterns, `save_pages`/`save_outputs` flush rules, variable passing via `vars` |
| `selector-discovery.md` | Browser tool ordering: `browser_grep_html` → `browser_inspect_element` → `browser_verify_selector` |
| `output-hash-rules.md` | All 53 fields must appear; canonical field names; nil-field `warn` block |
| `browser-mcp-tools.md` | Tool reference: discovery, network, expensive tools, cost justification line |
| `playwright-refs.md` | Refs vs CSS selectors: never use snapshot refs in Ruby code |
| `parser-testing.md` | `parser_tester` MCP tool usage, `test_files` array, quiet mode |
| `greenfield-prompt-spec.md` | Greenfield pipeline: message-only field-spec, accepting various briefing formats |

**When to add here:** Any factual rule about how the scraper runtime works, how tools behave, or how output should be structured — if it applies across projects and both agents need it.

---

### 3. Workflow Phase Instructions — `docs/workflows/phases/`

Step-by-step instructions for each pipeline phase. Linked from `profiles/*.toml` → `pipeline.phases[].workflow`. Loaded by the Gemini agent at the start of each phase command.

| File pattern | Pipeline |
|---|---|
| `01-site-discovery.md` | All projects — Phase 1 |
| `02-navigation-parser.md` | All projects — Phase 2 |
| `03-details-parser.md` | dmart-dloc — Phase 3 |
| `03-restaurant-details.md` | dhero — Phase 3 |
| `04-menu-parser.md` | dhero — Phase 4 |
| `api-0*.md` | API pipeline variants |
| `greenfield-0*.md` | Greenfield (message-driven) pipeline |

**When to add here:** When a pipeline phase gets new required steps, decision points, or output format changes that the agent must follow at execution time.

---

### 4. Project Pipeline Configuration — `profiles/*.toml`

Defines the pipeline for each project type. The Gemini agent reads the relevant profile when a command is invoked.

```
profiles/dhero.toml         → 4-phase restaurant pipeline
profiles/dmart-dloc.toml    → 3-phase product pipeline
profiles/greenfield.toml    → message-driven pipeline
```

Each profile specifies: boilerplate template location, default field spec path, and the ordered phase array with `workflow` file links.

**When to edit:** When adding a new project type, changing phase order, or pointing to a new boilerplate template.

---

### 5. Field Specifications — `spec_full.json` / `field-spec.json`

Canonical definition of what a scraper must output. Read by both agents.

| File | Project | Collections |
|---|---|---|
| `spec_full.json` | dhero | `locations` + `items` |
| `field-spec.json` | dmart-dloc | `products` |

Each field entry declares: `name`, `collection`, `type`, `extraction_method` (`HARDCODED`, `INFER`, `FROM_VARS`, `FIND`, `DETERMINE`), `priority`, and `notes`.

**When to edit:** When the client pipeline schema changes — add/remove fields, change types, or clarify extraction rules.

---

### 6. Planning & Decision Records — `docs/proposals/`

Dated proposal files capturing the *why* behind architecture decisions. Not enforced at runtime — for human and AI context only.

Format: `docs/proposals/YYYY-MM-DD-<slug>.md`  
Lifecycle: `Draft` → `In Progress` → `Done` (see CLAUDE.md for enforcement rules).

**When to add:** Before any non-trivial implementation (see CLAUDE.md proposal lifecycle table).

---

### 7. Claude Session Memory — `memory/` (Claude-only)

Stored at: `C:\Users\Raihan\.claude\projects\D--DataHen-projects-gemini-cli-testbed\memory\`

Claude Code's persistent cross-session memory. Types: `user`, `feedback`, `project`, `reference`. Indexed in `MEMORY.md`.

**This is NOT shared with the Gemini agent.** If a fact discovered here needs to persist for Gemini (e.g. a gem is pre-loaded in v3), it must also be written into `docs/shared/`.

---

### 8. Runtime State — `.scraper-state/` (Gemini runtime only)

Created by the Gemini agent during a scraping run. Lives inside `generated_scraper/<name>/.scraper-state/`.

| File | Content |
|---|---|
| `phase-status.json` | Which phases are complete |
| `discovery-state.json` | Site structure findings + human `_notes` + `_log` decisions |
| `browser-context.json` | Base URL, fetch type, auth headers |
| `field-spec.json` | Per-scraper copy of field spec, updated with discovered selectors |

**Not knowledge base files** — ephemeral per-run state. Not committed to the repo (covered by `.gitignore`).

---

## Decision Guide — Where Does New Knowledge Go?

| Type of knowledge | Goes in |
|---|---|
| "In v3, gem X is pre-loaded" | `docs/shared/datahen-ruby-parsers.md` |
| "Always use tool A before tool B" | `docs/shared/selector-discovery.md` or `agent-rules-gemini.md` |
| "Field Y must always be nil, not omitted" | `docs/shared/output-hash-rules.md` |
| "New phase Z requires step..." | `docs/workflows/phases/<new-phase>.md` |
| "Client pipeline now has field W" | `spec_full.json` or `field-spec.json` |
| "We decided not to use approach X because..." | `docs/proposals/YYYY-MM-DD-<slug>.md` |
| "Claude should remember user prefers X" | `memory/` (Claude only) |
| "Claude should remember user prefers X AND Gemini needs it too" | `memory/` **AND** `docs/shared/` |

---

## What Gemini Actually Reads (Load Order)

1. `GEMINI.md` — loaded as system prompt at CLI start
2. The TOML for the invoked command (e.g. `dhero-details-parser.toml`) — imports `@docs/shared/*.md` files
3. The `workflow` file linked from the active pipeline phase — step-by-step instructions
4. Runtime state files from `.scraper-state/` — what was found in prior phases
5. Field spec (`spec_full.json` or per-scraper `field-spec.json`) — what to extract
