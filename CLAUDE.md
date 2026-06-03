# CLAUDE.md — Project Instructions for Claude Code

This file is read automatically by Claude Code at the start of every session.
Rules here override default behavior.

---

## Documentation Rule — Proposals & Plans

**Every planning discussion or non-trivial implementation must be documented before code is written.**

- File location: `docs/proposals/YYYY-MM-DD-<slug>.md`
- Use today's date from the system (available in context as `currentDate`)
- One file per topic/feature/fix

### When to create a proposal file

| Situation | Required? |
|---|---|
| Debugging a single-line bug | No |
| Adding a new Skill (`.agents/skills/`) or phase | Yes |
| Modifying boilerplate templates | Yes |
| Changing field-spec.json schema | Yes |
| Refactoring more than one file | Yes |
| Any task the user asks to "plan" or "consult about" | Yes |

### Required sections in every proposal

```markdown
# Proposal: <title>

**Created:** YYYY-MM-DD
**Status:** Draft | In Progress | Done
**Scope:** which files / features are affected

## 1. Background
Why this work is needed.

## 2. Current State
What exists today. Quote specific file:line where relevant.

## 3. Problem(s)
What is wrong or missing. Be specific.

## 4. Proposal
Concrete implementation plan with code samples.

## 5. Implementation Order
Prioritized steps with effort + risk estimates.
```

### Status lifecycle

| Status | Meaning |
|---|---|
| `Draft` | Written but not yet approved or started |
| `In Progress` | Actively being implemented |
| `Done` | All steps completed and verified |
| `Cancelled` | Decided not to implement |

### Lifecycle enforcement (mandatory)

Follow this sequence for every non-trivial task:

1. **Create proposal** (`Draft`) — before writing any code
2. **Update to `In Progress`** — when the first file is edited
3. **Implement** — write code, edit files, run tests
4. **Update to `Done`** — after implementation is complete, before or alongside the final commit

The proposal file and the implementation commit should land in the **same git commit** or adjacent commits. Never close a session with code committed but the proposal still at `Draft` or `In Progress`.

### Retroactive fallback

If the user directs implementation before planning (e.g. "just do it", "execute now"):

1. **Still create the proposal file first** — set status `In Progress`, sections can be brief
2. **Implement**
3. **Fill in full proposal detail** (Background, Current State, Problems, code samples) and update status to `Done`
4. **Commit** proposal alongside or immediately after the implementation commit

Never skip the proposal entirely — a retroactive `Done` proposal is acceptable; no proposal is not.

---

## General Rules

### DataHen V3 Parser Conventions (CRITICAL)

- Parsers are **top-level scripts** — never wrap in `def parse` or any method
- **Never redeclare** `pages`, `outputs`, `page`, `content` — pre-defined by DataHen runtime
- Use `pages <<` and `outputs <<` directly
- Call `save_pages(pages)` and `save_outputs(outputs)` when arrays exceed 99 items
- Ruby gems: `nokogiri` (HTML), `addressable` (URLs), `chronic` (dates)

### Parser Testing

- Test parsers ONLY via `parser_tester` MCP tool — `hen parser try` is not available
- Use `quiet: true` for routine validation, `quiet: false` when debugging
- Always test against 3 sample pages/files before marking a field as verified

### File Path Rules

- **`write_file` operations require absolute paths** — relative paths will fail
- State files, parser files, and knowledge files must all use absolute paths

### Antigravity CLI — Agent Configuration Layers

`AGENTS.md` is the **single context file** — merges the old `GEMINI.md` (persona, PARSE methodology) and `.gemini/system.md` (firmware rules). Antigravity CLI (`agy`) prepends it to every prompt automatically; no env var needed.

**Config:** `.agents/mcp_config.json` (MCP servers). **Env:** `.agents/.env` (`AGY_API_KEY`, `AGY_MODEL`). **Plugin manifest:** `.agents/plugin.json` (required — without it agy ignores all skills and MCP servers in `.agents/`). **One-time setup:** run `agy plugin install .agents` from the repo root to register the plugin with agy (only needed once per machine; persists across sessions). **Skill file format:** two coexisting formats — native workspace skills are flat `skills/name.md` files (appear in TUI and as slash commands automatically); plugin marketplace skills use `skills/name/SKILL.md` subdirectories (require `plugin install`).

The old `.gemini/` directory is retained as a reference but is inert — `gemini` binary was deprecated June 18, 2026.

---

### Antigravity CLI Commands

**Generic commands (project= param selects profile from `profiles/`):**
- HTML pipeline: `/scrape` → `/navigation-parser` → `/details-parser`
- Greenfield (URLs + schema in same message, **`project=greenfield`**): `/greenfield-scrape` → `/navigation-parser` → `/details-parser` — no default spec file unless `spec=` is passed
- API pipeline: `/api-scrape` → `/api-navigation-parser` → `/api-details-parser`
- Extra phases: `/restaurant-details-parser` → `/menu-listings-parser` → `/menu-parser` (dhero)

**Project aliases (shorthand — project is hardcoded):**
- dhero: `/scrape project=dhero` → `/navigation-parser project=dhero` → `/restaurant-details-parser` → `/menu-listings-parser project=dhero` → `/menu-parser`

**Skills location:** `.agents/skills/` — one `.md` file per slash command.
**Pipeline configuration:** `profiles/<project>.toml` defines the pipeline array.
**Workflow docs:** `docs/workflows/phases/` — one file per phase type.
**Shared rules:** `docs/shared/` — agent-rules-gemini.md, datahen-conventions.md, selector-discovery.md, output-hash-rules.md

### Playwright MCP Mod

Antigravity CLI uses **Playwright MCP Mod** as its browser automation tool — a custom fork of Microsoft's Playwright MCP with additional tools for scraping workflows.

- **Location:** `../playwright-mcp-mod` (sibling repo — `D:\DataHen\projects\playwright-mcp-mod`)
- **Setup reference:** `README - Playwrgiht MCP Mod.md` (in this repo)
- **Build command:** `cd ../playwright-mcp-mod && npm run build`

Custom tools added on top of standard Playwright MCP (source: `../playwright-mcp-mod/src/tools/mod/`):

| Tool | Source file | Purpose |
|---|---|---|
| `browser_grep_html` | `html.ts` | Grep page HTML for text/regex, return context snippets — preferred for selector discovery |
| `browser_view_html` | `html.ts` | Full sanitized page HTML — last resort, high token cost |
| `browser_inspect_element` | `inspector.ts` | Exact CSS selector from a snapshot ref; supports `batch` array |
| `browser_verify_selector` | `inspector.ts` | Confirm selector matches text; supports `attribute` param + `batch` |
| `browser_count_selector` | `inspector.ts` | Count DOM matches with min/max assertions |
| `browser_extract_images` | `inspector.ts` | Extract all image URLs from a container (handles lazy-load) |
| `browser_extract_json_ld` | `json_ld.ts` | Extract JSON-LD blocks, filter by `@type`, return fields list |
| `browser_detect_pagination` | `dom_utils.ts` | Auto-detect pagination strategy (count/next-button/url-pattern) |
| `browser_network_search` | `network_search.ts` | Grep network request URLs, headers, and response bodies |
| `browser_network_download` | `network_download.ts` | Save a network response body to a file |
| `browser_network_requests_simplified` | `network_simplified.ts` | Filtered network request list |
| `browser_request` | `network_request.ts` | Make HTTP requests from browser context (inherits cookies) |
| `browser_network_replay` | `network_replay.ts` | Find captured request by URL pattern and replay it |
| `browser_get_request_context` | `network_context.ts` | Full request context (headers, cookies, body) for a URL pattern — headers pre-classified as stable vs ephemeral |
| `parser_tester` | `parser_tester.ts` | Test DataHen parsers against HTML/JSON/XML; supports `test_files` array |
| `scraper_output_validator` | `scraper_validator.ts` | Validate parser output against config.yaml field list |
| `scraper_run_evals` | `eval.ts` | Run eval fixtures, return score + nil-rate report |
| `datahen_run` | `datahen_run.ts` | Run DataHen scraper commands (seed, step, reset, pages) |

To add a new tool: create a `.ts` file in `src/tools/mod/`, export a tool array, import and spread it in `index.ts`, then run `npm run build`. Run `npm run check-drift` from this repo to verify docs stay in sync.

### Browser Tool Protocols (HTML scraping)

- Selector discovery order: `browser_grep_html()` → `browser_inspect_element()` → `browser_verify_selector()` or `browser_evaluate()`
- **Never use Playwright refs** (e.g., `ref=e62`) as CSS selectors in Ruby code
- `browser_verify_selector` is text-only; use `browser_evaluate` for images, URLs, data attributes
- Before calling expensive tools (`browser_view_html`, `browser_network_download`, `browser_request`, `parser_tester`), write one justification line: `💭 [tool]: [what I expect] → [why not cheaper]`

### HTML Detail Parser — Extraction Priority Order (Agent Instruction)

When the AI agent writes `details.rb` field extraction code, instruct it to try in this order:

1. **JSON-LD** (`<script type="application/ld+json">` with `@type: Product`) — most reliable across redesigns
2. **Meta tags** (`og:title`, `og:image`, `og:description`) — reliable fallback for key fields
3. **CSS selectors** — site-specific, discovered via browser tools

The agent runs `browser_grep_html(query: "@type")` first in Phase 3 to detect JSON-LD before spending time on CSS selector discovery. This is codified in the details-parser workflow docs.

**Templates stay clean:** `details.rb` boilerplate contains only PLACEHOLDER CSS selectors. The agent generates the appropriate json_ld / og_image code when it finds structured data.

### API Detail Parser — JSON-LD as Last Resort

For API scrapers, the agent should exhaust all JSON API fields first. Only fall back to fetching the HTML product page and parsing JSON-LD if critical fields (description, brand, images) are consistently nil across all test products. This is high-cost (second HTTP fetch per product) so use sparingly.

### API Scraping Rules

- API endpoints **must use `fetch_type: "standard"`** — browser fetch returns XML/HTML-wrapped content, not raw JSON
- Use `data.dig('field', 'nested')` for safe JSON traversal — never chain `[]` calls
- Check for GraphQL: search for POST requests to `/graphql` — document query, variables, and cursor pagination
- Capture auth tokens via `browser_network_search({query: "Authorization", searchIn: ["requestHeaders"]})`
- Cursor pagination: detect `pageInfo.endCursor` / `pageInfo.hasNextPage` — chain pages, do not queue upfront
- Add deduplication in listings parser when API may return overlapping product IDs across pages
- **Listings-only mode:** if `fieldset=maximal` (or equivalent) makes the listings API return complete product data, set `details_parser_needed: false` in the API state file and `disabled: true` on the details parser in `config.yaml`. The listings parser then emits the final output and MUST still include all 53 fields in canonical order — fields unavailable from the API set to `nil` explicitly, never omitted

### Output Hash Rules

- All 53 fields in field-spec.json MUST appear in the output hash
- Fields that cannot be extracted must be set to `nil` explicitly — never omit them
- Canonical field names: `currency_code_lc`, `rank_in_listing`, `scraped_at_timestamp`, `crawled_source: 'WEB'`
- All boilerplate `details.rb` templates include a nil-field summary warn before `outputs <<` — do not remove it:
  `warn "[DETAILS] url=... nil=X/N fields: ..."` — emitted only when any field is nil

### Parser Error Handling (boilerplate)

All template parsers include built-in error logging — preserve these patterns when editing generated parsers:

- **Details parsers**: nil-field summary `warn "[DETAILS] url=... nil=X/N fields: ...]"` before every `outputs <<`. `greenfield` and `dhero/restaurant_details` also wrap the output section in `begin/rescue` emitting `[DETAILS ERROR]` on unexpected exceptions.
- **Listings parsers**: per-item `begin/rescue` in the product/restaurant loop emitting `[LISTINGS ERROR] url=... idx=N error=...`; count log `[LISTINGS] url=... queued=N products` at end of each page run.
- Reference implementations: `templates/*/parsers/`

### State File Logging (`_log`)

Every state file that carries `_notes` MUST also include a `_log` array of structured decision entries. See `docs/shared/datahen-conventions.md` → "Agent Decision Log" for entry schema and required entry points (json_ld_probe, selector_verify, parser_test, pagination_strategy, fallback, structural_error).

### Error Taxonomy

Classify failures before responding — see `docs/shared/agent-rules-gemini.md` → "Error Taxonomy":
- **Transient** (network timeout, popup) → retry once, then treat as Structural
- **Structural** (0-match selector, required field nil on 3+ URLs) → STOP, write `_log` entry, surface to user
- **Data gap** (optional field nil on some SKUs) → log nil rate, continue

---

## Memory Pointer

Full project memory (stack, patterns, known issues) lives in:
`C:\Users\Raihan\.claude\projects\D--DataHen-projects-gemini-cli-testbed\memory\MEMORY.md`
