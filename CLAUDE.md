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
| Adding a new TOML command or phase | Yes |
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

### Gemini CLI Commands

**Generic commands (project= param selects profile from `profiles/`):**
- HTML pipeline: `/scrape` → `/navigation-parser` → `/details-parser`
- Greenfield (prompt/schema in thread): `/greenfield-scrape` → `/navigation-parser` → `/details-parser` with **`project=greenfield`**
- API pipeline: `/api-scrape` → `/api-navigation-parser` → `/api-details-parser`
- Extra phases: `/restaurant-details-parser` → `/menu-parser` (dhero)

**Project aliases (shorthand — project is hardcoded):**
- dmart: `/dmart-scrape` → `/dmart-navigation-parser` → `/dmart-details-parser`
- dhero: `/dhero-scrape` → `/dhero-navigation-parser` → `/dhero-restaurant-details` → `/dhero-menu-parser`
- API: `/dmart-api-scrape` → `/dmart-api-navigation-parser` → `/dmart-api-details-parser`

**Pipeline configuration:** `profiles/<project>.toml` defines the pipeline array.
**Workflow docs:** `docs/workflows/phases/` — one file per phase type.
**Shared rules:** `docs/shared/` — agent-rules-gemini.md, datahen-conventions.md, selector-discovery.md, output-hash-rules.md

### Playwright MCP Mod

Gemini CLI uses **Playwright MCP Mod** as its browser automation tool — a custom fork of Microsoft's Playwright MCP with additional tools for scraping workflows.

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

The agent runs `browser_grep_html(query: "@type")` first in Phase 3 to detect JSON-LD before spending time on CSS selector discovery. This is codified in `dmart-details-parser.toml` step 9.a0.

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
- Add a validation block before `outputs <<` to warn on nil required fields (name, customer_price_lc, img_url)

---

## Memory Pointer

Full project memory (stack, patterns, known issues) lives in:
`C:\Users\Raihan\.claude\projects\D--DataHen-projects-gemini-cli-testbed\memory\MEMORY.md`
