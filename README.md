# Antigravity CLI Scraper Config

**AI-driven web scraper generation** using [Antigravity CLI](https://antigravity.google/docs/gcli-migration) (`agy`) + [DataHen V3](https://datahen.com).

GitHub: [hraihanm/gemini_cli_scraper_config](https://github.com/hraihanm/gemini_cli_scraper_config)

> Migrated from Gemini CLI (deprecated 2026-06-18). See `docs/antigravity-cli-setup.md` and `docs/proposals/2026-06-18-antigravity-native-architecture.md`.

---

## Overview

This repository bundles Antigravity CLI **workflows** (slash commands), **skills** (reusable knowledge), and boilerplate templates that let an AI agent autonomously build a working DataHen V3 scraper in three phases:

1. **Site Discovery** — Navigate the target site, understand structure, collect sample URLs, handle popups.
2. **Navigation Parser** — Generate category/listing parsers to enumerate product/detail URLs.
3. **Details Parser** — Generate the detail parser to extract every output field.

Three project profiles are included:

| Profile | Use case | Phases |
|---|---|---|
| `greenfield` | Any new site — you specify output fields in the message | 3 (HTML) |
| `dmart-dloc` | Retail product sites (predefined 53-field spec) | 3 (HTML) + 3 (API) |
| `dhero` | Restaurant / food delivery sites | 5 (HTML) + 3 (API) |

---

## Prerequisites

- **[Antigravity CLI](https://antigravity.google/docs/gcli-migration)** (`agy`) — installed and on PATH
- **[Playwright MCP Mod](https://github.com/hraihanm/playwright-mcp-mod/tree/experiment)** — custom browser automation server (see setup below)
- **Node.js 18+** and **npm**
- An **API key** set in `.agents/.env` (`AGY_API_KEY`, `AGY_MODEL`)

---

## Installation

### 1. Clone this repo

```powershell
git clone https://github.com/hraihanm/gemini_cli_scraper_config.git
cd gemini_cli_scraper_config
```

### 2. Set up Playwright MCP Mod

This project uses a custom fork of Microsoft's Playwright MCP with additional scraping tools.

```powershell
# Clone the mod (experiment branch) as a sibling directory
git clone -b experiment https://github.com/hraihanm/playwright-mcp-mod.git ..\playwright-mcp-mod

# Build it
cd ..\playwright-mcp-mod
npm install
npm run build

# Return to this repo
cd ..\gemini_cli_scraper_config
```

### 3. Configure the MCP server

Edit `.agents/mcp_config.json` to point to the built mod. Adjust the path if you cloned elsewhere:

```json
{
  "mcpServers": {
    "playwright-mod": {
      "command": "npx",
      "args": [
        "D:\\DataHen\\projects\\playwright-mcp-mod",
        "--caps",
        "vision"
      ]
    }
  }
}
```

The `--caps vision` flag enables coordinate-based clicks (required for popup handling and image verification).

### 4. Set up environment

```powershell
Copy-Item .agents\.env.example .agents\.env
```

Edit `.agents/.env`:

```env
AGY_MODEL=gemini-3.5-flash
AGY_API_KEY=your_api_key_here
```

> Never commit `.agents/.env` — it is gitignored.

### 5. Verify tool sync (optional)

```powershell
npm run check-drift
```

This checks that the tool list in `CLAUDE.md` matches what is actually implemented in `playwright-mcp-mod`.

---

## Quick Start

Run all commands from the **repository root** in a terminal. Antigravity CLI (`agy`) resolves paths relative to where it is launched and auto-discovers `.agents/workflows/` and `.agents/skills/`.

### Greenfield pipeline (any site)

Use this when you want to scrape a new site and define your own output fields inline.

```
/greenfield-scrape url=https://example.com/products name=example-scraper

I need to extract:
- product_name (str) — the product title
- price (float) — current selling price
- currency (str) — e.g. USD
- category (str) — breadcrumb category
- image_url (str) — main product image
- in_stock (boolean) — whether the item is available
```

Then continue:

```
/navigation-parser scraper=example-scraper project=greenfield
```

```
/details-parser scraper=example-scraper project=greenfield
```

### Retail pipeline (dmart-dloc)

Uses the predefined 53-field e-commerce spec (`spec_full.json`).

```
/scrape url=https://target-retail-site.com name=my-retail-scraper project=dmart-dloc
/navigation-parser scraper=my-retail-scraper project=dmart-dloc
/details-parser scraper=my-retail-scraper project=dmart-dloc
```

### Restaurant pipeline (dhero)

Five-phase pipeline for restaurant listing + menu scraping.

```
/scrape url=https://food-delivery-site.com name=my-food-scraper project=dhero
/navigation-parser scraper=my-food-scraper project=dhero
/restaurant-details-parser scraper=my-food-scraper project=dhero
/menu-listings-parser scraper=my-food-scraper project=dhero
/menu-parser scraper=my-food-scraper project=dhero
```

### API pipeline

For sites where data is served via a JSON API rather than HTML.

```
/api-scrape url=https://api.example.com name=my-api-scraper project=dmart-dloc
/api-navigation-parser scraper=my-api-scraper project=dmart-dloc
/api-details-parser scraper=my-api-scraper project=dmart-dloc
```

---

## Greenfield Pipeline (detailed)

### What is Greenfield?

The Greenfield pipeline is for scraping **any new site** where you have not yet defined a field specification. Instead of a CSV/JSON spec file, you describe what you want to extract in plain text below the `/greenfield-scrape` command — any format is accepted.

The agent:
1. Reads your brief (prose, bullets, tables, pasted ticket)
2. Derives `field-spec.json` from the message
3. Navigates the target site and discovers its structure
4. Generates all parsers aligned to your field list

### Accepted briefing formats

All of the following work — pick whichever is natural:

**Prose:**
```
/greenfield-scrape url=https://example.com name=my-scraper

Scrape all products from the site. I need the product title, selling price,
brand name, and the main product image URL. Also extract whether the item
is currently in stock. Currency is always AED.
```

**Labeled sections:**
```
/greenfield-scrape url=https://example.com/listings name=my-scraper

Source: Example Store (UAE)
Start URL: https://example.com/listings
Output:
  - name (str): product title
  - price (float): selling price
  - currency (str): always "AED"
  - brand (str): brand name, may be nil
  - img_url (str): main image src
  - available (boolean): in-stock status
Caveats: items without a price are drafts — skip them
```

**Markdown table:**
```
/greenfield-scrape url=https://directory.example.org name=company-dir

| Field          | Type    | Notes                          |
|----------------|---------|--------------------------------|
| company_name   | str     | required                       |
| registration   | str     | company registration number    |
| country        | str     | ISO 2-char code                |
| industry       | str     | from dropdown taxonomy         |
| founded_year   | int     | may be nil for older entries   |
| website        | str     | may be nil                     |
```

**Pasted ticket / Jira-style:**
```
/greenfield-scrape url=https://jobs.example.com name=job-board

TICKET: SCRAPE-142
Source: Example Job Board
Country: Singapore
URLs:
  - Listings: https://jobs.example.com/singapore/listings
  - Detail: click each job card

Required fields:
  job_title (str), company (str), location (str), salary_min (int),
  salary_max (int), posted_date (str), job_url (str)

Optional:
  description (str), remote_ok (boolean), skills (str)

Refresh: daily
Dedup key: job_url
```

### With a spec file

If you already have a field spec file (JSON or CSV), pass it as `spec=`:

```
/greenfield-scrape url=https://example.com name=my-scraper spec=my-spec.json
```

CSV format (columns: `column_name`, `column_type`, `dev_notes`):

```csv
column_name,column_type,dev_notes
product_name,str,Required - main title
price,float,Selling price
currency,str,ISO code e.g. USD
brand,str,Optional
img_url,str,Main product image
```

JSON format — see [field-spec.json reference](#field-specjson-reference) below.

### Auto-chain (run all 3 phases in sequence)

Add `auto_next=true` to run phases automatically:

```
/greenfield-scrape url=https://example.com name=my-scraper auto_next=true

Fields: title (str), price (float), currency (str), img_url (str)
```

This executes Phase 1 → Phase 2 → Phase 3 without manual intervention.

---

## field-spec.json Reference

The agent creates this file in `generated_scraper/<scraper>/.scraper-state/field-spec.json`. For Greenfield it is derived from your message; for other profiles it is copied from the profile's `defaults.field_spec`.

```json
{
  "source_file": "prompt",
  "parsed_at": "2026-05-16T10:00:00Z",
  "fields": [
    {
      "name": "product_name",
      "type": "str",
      "extraction_method": "FIND",
      "notes": "Main product title",
      "selectors": [],
      "verified": false
    },
    {
      "name": "price",
      "type": "float",
      "extraction_method": "FIND",
      "notes": "Selling price",
      "selectors": [],
      "verified": false
    },
    {
      "name": "currency",
      "type": "str",
      "extraction_method": "HARDCODED",
      "notes": "Always USD for this site",
      "hardcoded_value": "USD",
      "selectors": [],
      "verified": false
    },
    {
      "name": "scraped_at",
      "type": "str",
      "extraction_method": "PROCESS",
      "notes": "ISO timestamp, generated at scrape time",
      "selectors": [],
      "verified": false
    }
  ],
  "_notes": "Site: example.com — scrape all product listings. Missing values → nil (JSON null)."
}
```

**`extraction_method` values:**

| Value | Meaning |
|---|---|
| `FIND` | Extract from the page (CSS selector, JSON-LD, meta tag, API field) |
| `HARDCODED` | Same value for every record (competitor name, currency code, etc.) |
| `PROCESS` | Computed at scrape time (timestamp, derived URL, concatenated fields) |

---

## Greenfield Brief Template

A Markdown template you can copy and fill in:

```
/greenfield-scrape url=<TARGET_URL> name=<SCRAPER_SLUG> [auto_next=true]

## Source
- Site: <site name>
- Country / Region: <country>
- Start URL: <URL for the main listing or category page>

## Crawl Constraints
- Caveats: <any known issues — login walls, rate limits, JS-heavy pages>
- Refresh cadence: <daily / weekly / one-time>
- Dedup key: <field that uniquely identifies a record, e.g. product_id, url>

## Output Fields

| Field name     | Type    | Notes                            |
|----------------|---------|----------------------------------|
| <field_name>   | str     | <what it contains>               |
| <field_name>   | float   | <what it contains>               |
| <field_name>   | int     | <optional — may be nil>          |
| <field_name>   | boolean | <true/false condition>           |

## Optional
- spec=<path/to/spec.json>  — attach a pre-built spec file instead of the table above
```

This template is also available as a standalone file: [`docs/greenfield-brief-template.md`](docs/greenfield-brief-template.md)

---

## Command Reference

All commands are slash commands (workflows in `.agents/workflows/`) run inside an Antigravity CLI (`agy`) session. `auto_next=true` chains phases in-session; `/run-pipeline` runs the whole pipeline.

### HTML pipeline commands

| Command | Phase | Description |
|---|---|---|
| `/scrape` | 1 | Site discovery — any project |
| `/greenfield-scrape` | 1 | Site discovery — greenfield (spec from message) |
| `/navigation-parser` | 2 | Navigation/listings parsers |
| `/details-parser` | 3 | Detail parser |
| `/restaurant-details-parser` | 3 | Restaurant detail parser (dhero) |
| `/menu-listings-parser` | 4 | Menu section listings (dhero) |
| `/menu-parser` | 5 | Menu item parser (dhero) |

### API pipeline commands

| Command | Phase | Description |
|---|---|---|
| `/api-scrape` | 1 | API endpoint discovery |
| `/api-navigation-parser` | 2 | API navigation/listings parser |
| `/api-details-parser` | 3 | API detail parser |

### Common arguments

| Argument | Commands | Description |
|---|---|---|
| `url=<URL>` | Phase 1 only | Target site URL (required for scrape commands) |
| `name=<slug>` | Phase 1 only | Scraper folder name — lowercase, hyphens (required) |
| `scraper=<slug>` | Phase 2+ | Name of the scraper to continue (required) |
| `project=<profile>` | All | Profile to use: `greenfield`, `dmart-dloc`, `dhero` |
| `spec=<path>` | Phase 1 | Override field spec file path |
| `auto_next=true` | All | Automatically run the next phase on completion |
| `out=<dir>` | Phase 1 | Output directory (default: `./generated_scraper`) |

---

## Project Profiles

Profiles live in `profiles/<name>.toml` and control which boilerplate template is used, what the default field spec is, and which workflow files each phase executes.

### `greenfield` — Prompt-driven, any site

- **Boilerplate:** `templates/greenfield_boilerplate/`
- **Field spec:** Derived from the user message (no default file)
- **Pipeline:** `scrape` → `navigation-parser` → `details-parser`
- **Best for:** New sites, registries, directories, job boards, custom extraction

### `dmart-dloc` — Retail products

- **Boilerplate:** `templates/dmart_dloc_boilerplate/`
- **Field spec:** `spec_full.json` (53 canonical e-commerce fields)
- **HTML pipeline:** `scrape` → `navigation-parser` → `details-parser`
- **API pipeline:** `api-scrape` → `api-navigation-parser` → `api-details-parser`
- **Best for:** Retail stores, supermarkets, FMCG product catalogues

### `dhero` — Restaurants

- **Boilerplate:** `templates/dhero_boilerplate/`
- **Field spec:** `dhero-field-spec.json`
- **Pipeline:** `scrape` → `navigation-parser` → `restaurant-details-parser` → `menu-listings-parser` → `menu-parser`
- **Scope filter:** Only seeds categories matching `restaurant` keyword
- **Best for:** Food delivery platforms, restaurant directories

---

## Generated Scraper Structure

After Phase 1 completes, `generated_scraper/<name>/` contains:

```
generated_scraper/<scraper-name>/
├── config.yaml                  # DataHen scraper config (parser list, exporters)
├── seeder/
│   └── seeder.rb                # Seed URLs and page_type/fetch_type
├── lib/
│   ├── headers.rb               # BASE_URL and shared HTTP headers
│   ├── helpers.rb               # Shared extraction helpers
│   └── regex.rb                 # Shared regex patterns
├── parsers/
│   ├── categories.rb            # Category URL extraction
│   ├── subcategories.rb         # Subcategory URL extraction (if applicable)
│   ├── listings.rb              # Product/item URL + pagination
│   └── details.rb               # Field extraction (main output)
└── .scraper-state/
    ├── discovery-state.json     # Site structure, sample URLs, popup handling
    ├── field-spec.json          # Output field definitions
    ├── phase-status.json        # Phase completion status
    ├── browser-context.json     # Last browser state
    └── session-audit-*.json     # Tool usage audit per phase
```

---

## State Files Reference

The `.scraper-state/` directory lets each phase resume independently.

### `discovery-state.json`

Written by Phase 1. Contains site structure, sample URLs, popup handling strategy, and fetch requirements. The `_notes` field contains human-readable markdown summarising the discovery.

### `field-spec.json`

Output field definitions. For Greenfield: derived from your message. For other profiles: copied from `defaults.field_spec`. Each field has `extraction_method` (FIND / HARDCODED / PROCESS), `type`, and after Phase 3: `selectors` (discovered CSS selectors).

### `phase-status.json`

Tracks which phases are `pending`, `in_progress`, or `completed`. Each phase reads this to decide whether to resume or start fresh.

### `session-audit-*.json`

Tool call counts for each phase session. Used to track expensive tool usage and improve agent prompts.

---

## Playwright MCP Mod Tools

The [`playwright-mcp-mod`](https://github.com/hraihanm/playwright-mcp-mod/tree/experiment) extends standard Playwright MCP with scraping-specific tools:

| Tool | Purpose |
|---|---|
| `browser_grep_html` | Grep page HTML for text/regex — preferred for selector discovery |
| `browser_view_html` | Full sanitized page HTML (high token cost — last resort) |
| `browser_inspect_element` | Exact CSS selector from a snapshot ref |
| `browser_verify_selector` | Confirm a selector matches expected text |
| `browser_count_selector` | Count DOM matches with min/max assertions |
| `browser_extract_images` | Extract all image URLs from a container |
| `browser_extract_json_ld` | Extract JSON-LD blocks, filter by `@type` |
| `browser_detect_pagination` | Auto-detect pagination strategy |
| `browser_network_search` | Grep network request URLs, headers, response bodies |
| `browser_network_download` | Save a network response body to file |
| `browser_network_requests_simplified` | Filtered network request list |
| `browser_request` | Make HTTP requests from browser context (inherits cookies/auth) |
| `browser_network_replay` | Find a captured request by URL pattern and replay it |
| `browser_get_request_context` | Full request context (headers, cookies) with stable vs ephemeral classification |
| `parser_tester` | Test DataHen parsers against HTML/JSON/XML |
| `scraper_output_validator` | Validate parser output against `config.yaml` field list |
| `scraper_run_evals` | Run eval fixtures, return score + nil-rate report |
| `datahen_run` | Run DataHen scraper commands (seed, step, reset, pages) |

To rebuild after changes to the mod:

```powershell
cd ..\playwright-mcp-mod
npm run build
```

---

## DataHen V3 Parser Conventions

Generated parsers follow these rules enforced by the agent:

- Parsers are **top-level scripts** — no `def parse` wrapper
- Never redeclare `pages`, `outputs`, `page`, `content` — pre-defined by the DataHen runtime
- Use `pages <<` and `outputs <<` directly
- Call `save_pages(pages)` / `save_outputs(outputs)` when arrays exceed 99 items
- Missing fields are set to `nil` explicitly — never omitted or set to `""`
- All parsers include nil-field summary warnings before `outputs <<`

---

## Tips

- Run all commands from the **repository root** — relative path resolution depends on this.
- Use `auto_next=true` to chain phases without manual intervention.
- Coordinate tools (clicks by X/Y) require `--caps vision` in the MCP args — already configured in `.agents/mcp_config.json`.
- After editing `playwright-mcp-mod`, always run `npm run build` before using new tools.
- State files in `.scraper-state/` let you resume a phase mid-way — the agent reads them at startup.
- For Greenfield, be specific about field types (`str`, `int`, `float`, `boolean`) to get accurate `field-spec.json` entries.
- The `_notes` field in `discovery-state.json` contains the human-readable summary — check it after Phase 1 to confirm the agent understood the site correctly.
