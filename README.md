# Antigravity CLI Scraper Generator

**AI-driven web-scraper generation** for [DataHen V3](https://datahen.com), driven by agent **skills** that run inside [Antigravity CLI](https://antigravity.google/docs/gcli-migration) (`agy`) or [Cursor](https://cursor.com). An agent navigates a target site (or its API), discovers structure and selectors, writes the parsers, then **gates the result with a deploy-readiness check** — so a developer can continue the work or deploy directly.

GitHub: [hraihanm/gemini_cli_scraper_config](https://github.com/hraihanm/gemini_cli_scraper_config)

> Migrated from Gemini CLI (deprecated 2026-06-18). Knowledge moved from skills into a hub-and-spokes KB (2026-06-21). See `docs/antigravity-cli-setup.md` and `docs/proposals/`.

---

## Table of contents

1. [What it does](#what-it-does)
2. [Architecture at a glance](#architecture-at-a-glance)
3. [Prerequisites](#prerequisites)
4. [Installation](#installation)
   - [1. Clone](#1-clone-this-repo) · [2. Playwright MCP Mod](#2-install-playwright-mcp-mod) · [3. MCP config](#3-point-mcp-configs-at-the-build) · [4. Env](#4-set-environment-variables) · [5. AGY skills](#5-register-skills--mcp-antigravity-cli) · [6. Cursor](#6-cursor--full-setup) · [7. Verify](#7-verify-everything)
5. [Compatible clients](#compatible-clients)
6. [Usage](#usage)
   - [Greenfield](#greenfield-pipeline-any-site) · [Retail / dmart](#retail-pipeline-dmart-dloc) · [Restaurant / dhero](#restaurant-pipeline-dhero) · [API](#api-pipeline) · [Full pipeline](#full-pipeline-one-command)
6. [The QA gate & deploy-readiness](#the-qa-gate--deploy-readiness)
7. [Knowledge base (`/kb`)](#knowledge-base-kb)
8. [Command reference](#command-reference)
9. [Project profiles](#project-profiles)
10. [Greenfield briefing formats](#greenfield-briefing-formats)
11. [Generated scraper & state files](#generated-scraper--state-files)
12. [Playwright MCP Mod tools](#playwright-mcp-mod-tools)
13. [CI & quality checks](#ci--quality-checks)
14. [DataHen V3 conventions](#datahen-v3-parser-conventions)
15. [Repository layout](#repository-layout)
16. [Maintaining the system](#maintaining-the-system)
17. [Troubleshooting](#troubleshooting)

---

## What it does

The agent builds a working DataHen scraper in phases, then runs a QA gate:

1. **Site discovery** — navigate the site/API, understand structure, collect sample URLs, capture headers, handle popups.
2. **Navigation parser(s)** — enumerate category/listing → detail URLs (with pagination).
3. **Detail parser(s)** — extract every field in the spec.
4. **QA gate** — validate sampled output against the field spec and emit a deploy-readiness verdict + reports.

Three project profiles ship in the box:

| Profile | Use case | Pipeline | Output |
|---|---|---|---|
| `greenfield` | Any new site — you describe the fields in the chat message | discovery → navigation → details → **/qa** | `products` |
| `dmart-dloc` | Retail / FMCG product sites (canonical e-commerce field spec) | HTML or API: discovery → navigation → details → **/qa** | `products` |
| `dhero` | Restaurant / food-delivery sites (API-first) | discovery → navigation → restaurant-details → menu-listings → menu → **/qa** | `locations` + `items` |

---

## Architecture at a glance

Everything is driven by **stable files in this repo** — the LLM orchestrates, deterministic tools/scripts validate.

| Layer | Where | Role |
|---|---|---|
| **Firmware** | `AGENTS.md` (+ `docs/shared/agent-rules-gemini.md`) | Persona + always-on rules: popups, error taxonomy, auto-chaining, untrusted-content guardrail |
| **Command skills** | `.agents/skills/<name>/SKILL.md` | The slash commands (`/scrape`, `/qa`, `/run-pipeline`, …) plus the `/kb` bootstrap |
| **Knowledge base** | `docs/shared/` | Hub `KB_HUB.md` + focused spokes, loaded on demand by `read_file` (index via `/kb`) — **not** skills |
| **Phase playbooks** | `docs/workflows/phases/*.md` | Step-by-step per phase, referenced by the command skills |
| **Profiles** | `profiles/<project>.toml` | Pipeline phases, boilerplate dir, default field spec, `[qa]` gate |
| **Templates** | `templates/<project>_boilerplate/` | The scraper skeleton copied into each new scraper |
| **QA gate** | `scripts/scraper_qa_report.rb` + `/qa` | Deterministic schema/nil-rate/id/eval gates → `deploy-readiness.json` |
| **Browser/parser tools** | `playwright-mcp-mod` (sibling repo, MCP) | Selector discovery, network capture, parser testing, evals |

---

## Prerequisites

| Tool | Required for | Check |
|---|---|---|
| **[Antigravity CLI](https://antigravity.google/docs/gcli-migration)** (`agy`) | Primary AI client | `agy --version` |
| **[Cursor](https://cursor.com)** | Alternative AI client | — |
| **Node.js 18+** | Playwright MCP Mod | `node --version` |
| **npm 9+** | Playwright MCP Mod | `npm --version` |
| **Ruby 3.x** | QA report script + CI syntax checks | `ruby --version` |
| **Git** | Clone repos | `git --version` |
| **PowerShell 7+** (`pwsh`) | Setup script (Windows) | `pwsh --version` |
| **API key** | Model provider | Set in `.agents/.env` |

You need either `agy` or Cursor (or both). All other tools are required regardless.

---

## Installation

### 1. Clone this repo

```powershell
# Windows (PowerShell)
git clone https://github.com/hraihanm/gemini_cli_scraper_config.git
cd gemini_cli_scraper_config
```

```bash
# macOS / Linux
git clone https://github.com/hraihanm/gemini_cli_scraper_config.git
cd gemini_cli_scraper_config
```

---

### 2. Install Playwright MCP Mod

This project's browser and parser tools come from a custom fork of Microsoft's Playwright MCP. It must be cloned **as a sibling** to this repo and built before any agent session.

#### 2a. Clone and build

```powershell
# Windows — run from the parent of gemini_cli_scraper_config
git clone -b experiment https://github.com/hraihanm/playwright-mcp-mod.git ..\playwright-mcp-mod
cd ..\playwright-mcp-mod
npm install
npm run build
cd ..\gemini_cli_scraper_config
```

```bash
# macOS / Linux
git clone -b experiment https://github.com/hraihanm/playwright-mcp-mod.git ../playwright-mcp-mod
cd ../playwright-mcp-mod
npm install
npm run build
cd ../gemini_cli_scraper_config
```

Expected result: `lib/index.js` now exists inside `playwright-mcp-mod/`.

#### 2b. Install the Playwright browser

```bash
cd ..\playwright-mcp-mod   # or ../playwright-mcp-mod on Mac/Linux
npx playwright install chromium
cd ..\gemini_cli_scraper_config
```

This downloads the Chromium binary. Required once; skip on subsequent machines if already installed.

#### 2c. Verify the build

```bash
node ..\playwright-mcp-mod\lib\index.js --help
```

You should see the Playwright MCP CLI help output. If you get `Cannot find module`, the build didn't complete — re-run `npm run build`.

#### 2d. Rebuild after mod changes

Whenever you pull new changes to `playwright-mcp-mod` or add a new tool:

```bash
cd ..\playwright-mcp-mod
npm run build
cd ..\gemini_cli_scraper_config
```

Then **restart your client** (agy / Cursor / Claude Code). New tools are only available after a rebuild + restart. Run `npm run check-drift` to verify the README tool list matches the implementation.

---

### 3. Point MCP configs at the build

Two config files reference the mod by **absolute path**. If you cloned to a different location, update both:

| File | Used by |
|---|---|
| `.agents/mcp_config.json` | Antigravity CLI (`agy`) |
| `.cursor/mcp.json` | Cursor |

Both files use the same structure:

```json
{
  "mcpServers": {
    "playwright-mod": {
      "command": "npx",
      "args": ["D:\\DataHen\\projects\\playwright-mcp-mod", "--caps", "vision"]
    }
  }
}
```

Replace `D:\\DataHen\\projects\\playwright-mcp-mod` with your actual absolute path. On Windows, use `\\` in JSON strings (or forward slashes — both work).

`--caps vision` enables coordinate-based click tools (`browser_mouse_click_xy`, etc.) needed for popup handling. Do not remove it.

---

### 4. Set environment variables

```powershell
Copy-Item .agents\.env.example .agents\.env
```

Edit `.agents/.env`:

```env
AGY_MODEL="gemini-3.5-flash"
AGY_API_KEY="your_api_key_here"
```

> `.agents/.env` is gitignored — never commit it.

Available model IDs depend on your API provider. For Google AI: `gemini-2.0-flash`, `gemini-2.5-pro`, etc.

---

### 5. Register skills + MCP (Antigravity CLI)

From the repo root:

```powershell
pwsh -NoProfile -File scripts/setup-agy.ps1
```

What the script does:

| Step | Why |
|---|---|
| Syncs `.agents/skills/<name>/SKILL.md` → `~/.gemini/antigravity-cli/skills/` | AGY global skills, available from any working directory |
| Syncs the same skills → `~/.cursor/skills/` | Cursor gets the identical `/` commands |
| Runs `agy plugin install .agents/plugins/gemini_cli_testbed` | Registers the `playwright-mod` MCP server + plugin |

Re-run this script any time you add or edit a skill.

Then start agy **from the repo root**:

```powershell
agy
```

---

### 6. Cursor — full setup

Cursor is the recommended IDE for using this system. Skills work as slash commands; the browser tools are available via MCP.

#### 6a. Open the project

Open the `gemini_cli_scraper_config` folder in Cursor (`File → Open Folder`). Cursor reads `.cursor/mcp.json` from the project root automatically.

#### 6b. Connect the MCP server

1. Go to **Cursor → Settings → MCP** (or `Ctrl+Shift+P` → "Open MCP Settings")
2. You should see `playwright-mod` in the list
3. Status should be **connected** (green dot) — if not, click **Restart**
4. If still disconnected: open **View → Output**, select `MCP` from the dropdown, and read the launch error. Common causes:
   - Wrong path in `.cursor/mcp.json`
   - `npm run build` was not run (missing `lib/index.js`)
   - Node.js not on PATH

#### 6c. Sync skills (slash commands)

Skills are synced to `~/.cursor/skills/` by `setup-agy.ps1` (step 5). If you skipped it:

```powershell
pwsh -NoProfile -File scripts/setup-agy.ps1
```

Restart Cursor after running the script.

#### 6d. Verify slash commands

In any Cursor chat window, type `/` — you should see the command skills appear:

```
/scrape
/navigation-parser
/details-parser
/qa
/run-pipeline
/kb
/greenfield-scrape
/api-scrape
...
```

If no skills appear: re-run `setup-agy.ps1` and restart Cursor.

#### 6e. Verify browser tools

In a Cursor chat, ask:

```
List available MCP tools
```

You should see `browser_grep_html`, `browser_snapshot`, `parser_tester`, `browser_network_requests_simplified`, etc. in the response.

#### 6f. Run your first command

```
/scrape url=https://example.com name=test-scraper project=greenfield

Extract: product name, price, URL
```

Cursor will open a browser window, navigate to the site, and begin Phase 1 discovery.

#### 6g. How skills interact with Cursor rules

The project has `.cursor/rules/` files that act as scoped context (equivalent to AGENTS.md but Cursor-native). The agent skills (`.agents/skills/`) are the slash commands. They are separate layers:

| Layer | File(s) | Loaded |
|---|---|---|
| Cursor rules | `.cursor/rules/*.mdc` | Automatically, scoped to matching files |
| Agent firmware | `AGENTS.md` | When using `agy`; also readable by Cursor as context |
| Skills | `~/.cursor/skills/<name>/SKILL.md` | On `/<name>` invocation |
| Knowledge base | `docs/shared/` | On demand via `read_file` from inside a skill |

---

### 7. Verify everything

```bash
# Deterministic checks — no agent needed
bash scripts/ci-check.sh
```

In `agy` or Cursor:

```
/mcp                     → playwright-mod shows connected
/                        → skills list appears (scrape, qa, kb, ...)
/kb                      → loads docs/shared/KB_HUB.md
```

---

## Compatible clients

This system is designed around two native clients but the knowledge base and skills are accessible from any tool that can read files and/or supports MCP.

### Antigravity CLI (`agy`) — primary

**AGENTS.md support:** Native — `AGENTS.md` is auto-loaded as firmware at session start.
**Skills support:** Native — `.agents/skills/<name>/SKILL.md` files register as `/name` slash commands.
**MCP support:** Via `.agents/mcp_config.json`.

Full setup: steps 4–5 above.

### Cursor — secondary

**AGENTS.md support:** Indirect — `AGENTS.md` content is referenced by `.cursor/rules/` files. The setup script syncs these.
**Skills support:** Via `~/.cursor/skills/` (synced by `setup-agy.ps1`). Same skill files, same slash commands.
**MCP support:** Via `.cursor/mcp.json`.

Full setup: steps 3 + 6 above.

### Claude Code

**AGENTS.md support:** Claude Code reads `CLAUDE.md` as its primary instruction file (present in this repo). `AGENTS.md` is visible as a project file and Claude Code will respect it as additional context.
**Skills support:** Skills can be invoked by referencing the skill file path or by running `agy` in a terminal tab. No native slash command registration.
**MCP support:** Add to `.mcp.json` in the project root:

```json
{
  "mcpServers": {
    "playwright-mod": {
      "command": "npx",
      "args": ["D:\\DataHen\\projects\\playwright-mcp-mod", "--caps", "vision"]
    }
  }
}
```

Then restart Claude Code. The browser and parser tools will be available in Claude Code sessions.

**Knowledge base:** Claude Code can `read_file` any spoke in `docs/shared/` directly — the same KB the agent skills use.

### Windsurf

**AGENTS.md support:** Windsurf has `.windsurfrules` (analogous to `.cursorrules`). Copy the relevant sections of `AGENTS.md` into `.windsurfrules` to give Windsurf the same persona and constraints.
**Skills support:** Not natively. Adapt skills by copying relevant SKILL.md content into Windsurf custom instructions or system prompts.
**MCP support:** Edit `~/.windsurf/mcp.json`:

```json
{
  "mcpServers": {
    "playwright-mod": {
      "command": "npx",
      "args": ["D:\\DataHen\\projects\\playwright-mcp-mod", "--caps", "vision"]
    }
  }
}
```

Restart Windsurf after saving.

### GitHub Copilot (VS Code)

**AGENTS.md support:** Via `.github/copilot-instructions.md` — copy the relevant parts of `AGENTS.md` there.
**Skills support:** Not natively. The slash commands won't work; use the phase docs in `docs/workflows/phases/` as manual step-by-step references.
**MCP support:** GitHub Copilot in VS Code supports MCP as of early 2026. Add the playwright-mod config in VS Code's MCP settings (`settings.json → "github.copilot.mcp"`).

### Any MCP-compatible client

The playwright-mod tools work with any client that supports the MCP protocol (HTTP/SSE or stdio transport). Configure the server the same way:

```json
{
  "command": "npx",
  "args": ["<absolute-path-to-playwright-mcp-mod>", "--caps", "vision"]
}
```

The knowledge base (`docs/shared/`) can be read by any agent that can call `read_file` or access the local filesystem.

---

## Usage

Run commands from the **repository root**. `auto_next=true` chains phases in the same session; `/run-pipeline` runs the whole thing including the final QA gate.

### Greenfield pipeline (any site)

Describe the fields in plain text **below** the command — prose, bullets, a table, or a pasted ticket all work ([formats](#greenfield-briefing-formats)).

```
/greenfield-scrape url=https://example.com/products name=example-scraper

I need to extract:
- product_name (str) — the product title
- price (float) — current selling price
- currency (str) — e.g. USD
- category (str) — breadcrumb category
- img_url (str) — main product image
- is_available (boolean) — whether the item is in stock
```

Then:

```
/navigation-parser scraper=example-scraper project=greenfield
/details-parser    scraper=example-scraper project=greenfield
/qa                scraper=example-scraper project=greenfield
```

### Retail pipeline (dmart-dloc)

Uses the canonical e-commerce field spec (`field-spec.json`).

```
/scrape            url=https://target-retail-site.com name=my-retail project=dmart-dloc
/navigation-parser scraper=my-retail project=dmart-dloc
/details-parser    scraper=my-retail project=dmart-dloc
/qa                scraper=my-retail project=dmart-dloc
```

### Restaurant pipeline (dhero)

Five phases producing `locations` (restaurants) + `items` (menu). dhero is **API-first** — Phase 1 picks a [seeding strategy](docs/workflows/phases/dhero-seeding-strategies.md) (geo grid / H3 hexagon / city list / session bootstrap / URL listings).

```
/scrape                    url=https://food-delivery-site.com name=my-food project=dhero
/navigation-parser         scraper=my-food project=dhero
/restaurant-details-parser scraper=my-food project=dhero
/menu-listings-parser      scraper=my-food project=dhero
/menu-parser               scraper=my-food project=dhero
/dhero-qa                  scraper=my-food            # alias for /qa project=dhero
```

### API pipeline

For sites served by a JSON API. (For dhero this is the default — its `kind=api` pipeline reuses the same five phases.)

```
/api-scrape            url=https://api.example.com name=my-api project=dmart-dloc
/api-navigation-parser scraper=my-api project=dmart-dloc
/api-details-parser    scraper=my-api project=dmart-dloc
/qa                    scraper=my-api project=dmart-dloc
```

### Full pipeline (one command)

Runs every phase **and** the QA gate end-to-end in one session via state-file handoffs:

```
/run-pipeline project=dhero url=https://food-delivery-site.com name=my-food
/run-pipeline project=dmart-dloc url=https://shop.example.com name=my-shop kind=api
```

`/run-pipeline` treats `deployable:false` from the QA gate as a pipeline failure — it surfaces the blocking issues and stops rather than reporting success.

---

## The QA gate & deploy-readiness

After the parsers exist, **`/qa`** (or the final step of `/run-pipeline`) collects ≥3 sample records per collection, runs the eval fixtures, and invokes the deterministic reporter:

```
ruby scripts/scraper_qa_report.rb <scraper_dir> --project <p> --name <n> --require-eval --eval-score <N> --model <id>
```

It writes four artifacts into the scraper directory:

| Artifact | Purpose |
|---|---|
| `deploy-readiness.json` | Machine gates → `"deployable": true\|false` + `_blocking`/`_warnings` + `_meta` (versions, telemetry) |
| `GENERATION_REPORT.md` | Human report: gates, per-field availability, id integrity, sample records, decision trail, deploy commands |
| `spec.csv` | Field-availability matrix (`Yes`/`Partial`/`No`, nil %, type, export target) — the dev hand-off |
| `DATAHEN_PROJECT.txt` | Minimal project descriptor (`dht_type`, scraper name, page types) |

**Hard gates** (block deploy): `samples_ok` (≥3/collection), `schema_ok` (every spec field present, nil-explicit), `types_ok`, `required_fields_ok` (priority-1 fields non-nil), `ids_ok` (`_id` present + unique; dhero also checks `items.lead_id ⊆ locations.lead_id`), and `eval_ok` (with `--require-eval`, a missing or <80 % score blocks).
**Warnings** (non-blocking): priority-2 fields that are 100 % nil — confirm a genuine data gap vs. a broken selector.

Reproducibility/telemetry land in `deploy-readiness.json._meta`: `field_spec_version`, `git_commit`, `model`, plus any `tool_calls`/`elapsed_s`/`est_cost_usd` the skill passes.

---

## Knowledge base (`/kb`)

Knowledge is a **hub-and-spokes KB under `docs/shared/`**, not a set of skills.

- **`/kb`** — bootstrap: loads `docs/shared/KB_HUB.md` (the task→doc routing table), then the spoke(s) the task needs.
- **Spokes** (load by stable path): `agent-rules-gemini.md` (firmware), `datahen-conventions.md`, `datahen-ruby-parsers.md`, `selector-discovery.md`, `browser-mcp-tools.md`, `playwright-refs.md`, `output-hash-rules.md`, `dhero-output-schema.md`, `greenfield-prompt-spec.md`, `parser-testing.md`, `agent-best-practices.md`.

Command skills `read_file` the specific spoke they need; you rarely need `/kb` mid-pipeline. To add knowledge, add a spoke + a row in `KB_HUB.md` — **do not** create a knowledge skill.

---

## Command reference

All commands are skills in `.agents/skills/<name>/SKILL.md`. `project=` selects a profile.

### Pipeline

| Command | Phase | Description |
|---|---|---|
| `/scrape` | 1 | Site discovery — any project |
| `/greenfield-scrape` | 1 | Site discovery — greenfield (spec from the message) |
| `/navigation-parser` | 2 | Navigation / listings parsers |
| `/details-parser` | 3 | Product detail parser |
| `/restaurant-details-parser` | 3 | Restaurant detail parser (dhero) |
| `/menu-listings-parser` | 4 | Menu section listings (dhero) |
| `/menu-parser` | 5 | Menu item parser (dhero) |
| `/api-scrape`, `/api-navigation-parser`, `/api-details-parser` | 1–3 | API variants |
| `/run-pipeline` | all | Run every phase + QA gate in one session |

### QA & knowledge

| Command | Description |
|---|---|
| `/qa` | QA gate for any project → `spec.csv`, `GENERATION_REPORT.md`, `deploy-readiness.json` |
| `/dhero-qa` | Alias for `/qa project=dhero` |
| `/kb` | Load the knowledge-base hub + routing table |

### Common arguments

| Argument | Commands | Description |
|---|---|---|
| `url=<URL>` | Phase 1 | Target URL (required for scrape commands) |
| `name=<slug>` | Phase 1 | Scraper folder name (lowercase, hyphens) |
| `scraper=<slug>` | Phase 2+ / qa | Scraper to continue |
| `project=<profile>` | all | `greenfield` \| `dmart-dloc` \| `dhero` |
| `kind=html\|api` | `/run-pipeline` | Pipeline variant (dhero defaults to `api`) |
| `spec=<path>` | Phase 1 | Override the field-spec file |
| `auto_next=true` | all | Auto-run the next phase on completion |
| `out=<dir>` | Phase 1 | Output dir (default `./generated_scraper`) |

---

## Project profiles

Profiles live in `profiles/<name>.toml` (boilerplate dir, default field spec, pipeline phases, `[qa]` gate).

### `greenfield`
- Boilerplate `templates/greenfield_boilerplate/`; **no default spec** (built from the chat message, or pass `spec=`).
- `scrape → navigation-parser → details-parser → /qa`. Best for new sites, directories, job boards, custom extraction.

### `dmart-dloc`
- Boilerplate `templates/dmart_dloc_boilerplate/`; field spec `field-spec.json` (canonical e-commerce fields).
- HTML and API pipelines. Best for retail, supermarkets, FMCG catalogues.

### `dhero`
- Boilerplate `templates/dhero_boilerplate/` (with a shared `lib/` layer: `extraction`, `site_config`, `helpers`); field spec `dhero-field-spec.json` (`locations` 28 + `items` 22).
- **API-first** (`kind=api`); five fetch-agnostic phases. Seeding strategy chosen in Phase 1. Scope filter seeds only `restaurant` categories. Best for food delivery / restaurant directories.

---

## Greenfield briefing formats

Describe fields in any format below `/greenfield-scrape`. Examples:

**Bullets**
```
/greenfield-scrape url=https://example.com name=my-scraper

Scrape all products. I need: name (str), price (float), currency (str, always AED),
brand (str, may be nil), img_url (str), is_available (boolean). Skip items with no price.
```

**Markdown table**
```
/greenfield-scrape url=https://directory.example.org name=company-dir

| Field        | Type | Notes                       |
|--------------|------|-----------------------------|
| company_name | str  | required                    |
| country      | str  | ISO 2-char code             |
| founded_year | int  | may be nil for older entries|
| website      | str  | may be nil                  |
```

**Pasted ticket**
```
/greenfield-scrape url=https://jobs.example.com name=job-board

TICKET SCRAPE-142 — Singapore job board
Listings: https://jobs.example.com/singapore/listings
Required: job_title (str), company (str), location (str), salary_min (int), job_url (str)
Optional: description (str), remote_ok (boolean)
Dedup key: job_url ; Refresh: daily
```

**With a spec file** (`spec=` JSON, or CSV with columns `column_name,column_type,dev_notes`)
```
/greenfield-scrape url=https://example.com name=my-scraper spec=my-spec.json
```

See `docs/shared/greenfield-prompt-spec.md` for how the message becomes `field-spec.json`. `extraction_method` values: `FIND` (from the page), `HARDCODED` (same every record), `INFER`/`DETERMINE`/`PROCESS` (computed).

---

## Generated scraper & state files

After Phase 1, `generated_scraper/<name>/` looks like:

```
generated_scraper/<name>/
├── config.yaml                 # parsers, exporters, finisher, parse_failed_pages
├── seeder/seeder.rb            # seed URLs (or geo/city/hexagon grid for dhero)
├── lib/                        # headers + (dhero) extraction/site_config/helpers
├── parsers/                    # categories/listings/details (or dhero restaurant/menu)
├── finisher/finisher.rb        # post-job dedup (disabled by default)
└── .scraper-state/
    ├── discovery-state.json    # site structure, sample URLs, popups, seeding strategy, _log
    ├── field-spec.json         # output field definitions (copied or prompt-derived)
    ├── phase-status.json       # per-phase pending/in_progress/completed
    ├── qa-samples/             # sample output records collected by /qa
    └── session-audit-*.json    # tool-usage audit per phase
# After /qa, the scraper dir also gains:
#   deploy-readiness.json · GENERATION_REPORT.md · spec.csv · DATAHEN_PROJECT.txt
```

Each `*-state.json` carries a structured **`_log`** decision trail (json_ld_probe, selector_verify, seeding_strategy, parser_test, fallback, structural_error) that the QA report aggregates.

---

## Playwright MCP Mod tools

The sibling [`playwright-mcp-mod`](https://github.com/hraihanm/playwright-mcp-mod/tree/experiment) adds scraping-specific tools on top of standard Playwright MCP:

| Tool | Purpose |
|---|---|
| `browser_grep_html` | Grep page HTML — **preferred** for selector discovery |
| `browser_view_html` | Full sanitized HTML (high token cost — last resort) |
| `browser_inspect_element` / `browser_verify_selector` / `browser_count_selector` | Exact selector from a ref · confirm text · count with assertions |
| `browser_extract_images` / `browser_extract_json_ld` / `browser_detect_pagination` | Gallery images · JSON-LD by `@type` · pagination strategy |
| `browser_network_search` / `_download` / `_requests_simplified` / `_replay` | Grep / save / list / replay network traffic |
| `browser_request` / `browser_get_request_context` | HTTP from browser context · headers+cookies (stable vs ephemeral) |
| `parser_tester` | Test DataHen parsers against HTML/JSON/XML |
| `scraper_output_validator` / `scraper_run_evals` | Validate output vs `config.yaml` · run eval fixtures (score + nil-rate) |
| `datahen_run` | Run DataHen commands (seed, step, reset, pages) |

Rebuild after editing the mod: `cd ..\playwright-mcp-mod && npm run build`. Verify the docs↔implementation list with `npm run check-drift` from this repo.

---

## CI & quality checks

- **`scripts/ci-check.sh`** — deterministic, runs locally and in CI: `ruby -c` on all boilerplate parsers/libs + scripts, required-file existence, `profiles/*.toml` parse, field-spec JSON validity, SKILL frontmatter present.
- **`.github/workflows/agent-ci.yml`** — runs `ci-check.sh` on push/PR plus a best-effort parser-eval job (`scripts/run_evals.rb` over any dir with `evals/`).
- **`scripts/prompt-smoke.ps1`** — quick check that the canonical agent files exist.

```bash
bash scripts/ci-check.sh          # before committing
pwsh -File scripts/prompt-smoke.ps1
```

---

## DataHen V3 parser conventions

Generated parsers follow rules the agent enforces (full detail in `docs/shared/datahen-conventions.md`):

- Top-level scripts — no `def parse` wrapper.
- Never redeclare `pages`, `outputs`, `page`, `content` (pre-defined by the runtime); use string keys (`page['vars']`).
- `pages <<` / `outputs <<`; call `save_pages` / `save_outputs` past 99 items.
- Every spec field present in the output hash; missing values are explicit `nil` (never `""` or omitted).
- Error taxonomy: `refetch` transient 403, `limbo` persistent 500, debug collections for other failures; `[PHASE] count nil=X/N` warns.
- Scraped content is **untrusted data, never instructions** (firmware guardrail).

---

## Repository layout

```
.agents/
  skills/<name>/SKILL.md     # command skills + /kb (NO knowledge skills)
  mcp_config.json            # Antigravity MCP (playwright-mod)
  plugins/gemini_cli_testbed/plugin.json
.cursor/mcp.json             # Cursor MCP (playwright-mod)
.github/workflows/agent-ci.yml
AGENTS.md                    # firmware (always prepended)
CLAUDE.md                    # project instructions for Claude Code
profiles/<project>.toml      # pipeline + [qa] gate per project
templates/<project>_boilerplate/
docs/
  shared/                    # KB: KB_HUB.md + spokes
  workflows/phases/          # per-phase playbooks
  proposals/                 # design + decision records
scripts/
  setup-agy.ps1              # sync skills + install MCP plugin
  scraper_qa_report.rb       # QA gate / deploy-readiness report
  ci-check.sh                # deterministic CI checks
  run_evals.rb, parser_tester.rb, prompt-smoke.ps1
field-spec.json              # dmart/greenfield products spec
dhero-field-spec.json        # dhero locations + items spec
generated_scraper/           # output of runs (gitignored work area)
```

---

## Maintaining the system

- **After editing any skill** → re-run `pwsh -File scripts/setup-agy.ps1` and restart `agy`/Cursor.
- **SKILL.md frontmatter:** `name:` kebab-case; `description:` **double-quoted** if it contains `[ ] { } ,`; keep description **< 200 chars** and the body **< ~500 lines** (split into `references/` + `read_file` if larger). Bad frontmatter → AGY silently drops the skill.
- **Do not:** add flat `.agents/skills/<name>.md`, a `plugin.json` at `.agents/` root, or a `.agents/workflows/` directory; don't check in `.agents/plugins/.../skills/` (generated, gitignored).
- **Adding knowledge:** new spoke under `docs/shared/` + a row in `KB_HUB.md` (never a knowledge skill).
- **Non-trivial changes** get a proposal in `docs/proposals/YYYY-MM-DD-<slug>.md` (see `CLAUDE.md`).

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `/` shows 0 commands / skills | Bad SKILL frontmatter (unquoted `[...]`, >200-char description) — fix and re-run `setup-agy.ps1`. See `docs/antigravity-cli-setup.md`. |
| `playwright-mod` missing in `/mcp` | Build the mod (`npm run build`), check the absolute path in `.agents/mcp_config.json` / `.cursor/mcp.json`, re-run `setup-agy.ps1`. |
| Coordinate clicks fail | Ensure `--caps vision` in the MCP args (already set in both config files). |
| New mod tool not available | `cd ..\playwright-mcp-mod && npm run build`, restart the client. |
| `/qa` says NOT DEPLOYABLE | Read `_blocking` in `deploy-readiness.json` / `GENERATION_REPORT.md` — it names the field + fix. Re-run `/qa` after fixing. |
| Phase can't resume | Phases read `.scraper-state/*.json`; confirm `discovery-state.json` and `phase-status.json` exist for the scraper. |

---

## References

- [Gemini CLI → Antigravity migration](https://antigravity.google/docs/gcli-migration) · [Skills](https://antigravity.google/docs/skills) · [Plugins](https://antigravity.google/docs/plugins)
- `docs/antigravity-cli-setup.md` — setup + cross-tool details
- `docs/shared/KB_HUB.md` — knowledge index · `docs/shared/agent-best-practices.md` — production-agent principles
- `docs/proposals/` — design + decision records
- [DataHen docs](https://docs.datahen.com/en/latest/index.html)
