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
   - [1. Clone](#1-clone-this-repo) · [2. Playwright MCP Mod](#2-install-playwright-mcp-mod) · [3. Cursor](#3-cursor--recommended) · [4. Antigravity CLI](#4-antigravity-cli-agy) · [5. Claude Code](#5-claude-code) · [6. Windsurf](#6-windsurf) · [7. Verify](#7-verify)
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
13. [Local quality checks](#local-quality-checks)
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

**Pick one AI client** (or more):

| Client | Notes | Check |
|---|---|---|
| **[Cursor](https://cursor.com)** ⭐ recommended | Best out-of-the-box experience. Skills sync as slash commands; MCP connects automatically. | — |
| **[Antigravity CLI](https://antigravity.google/docs/gcli-migration)** (`agy`) | Free tier available; subscription-based (Google account auth — no API key needed). | `agy --version` |
| **[Claude Code](https://claude.ai/code)** | Skills sync to `.claude/commands/` via the included script. | `claude --version` |
| **[Windsurf](https://windsurf.com)** | MCP supported; skills usable via custom instructions. | — |

**All clients require:**

| Tool | Purpose | Check |
|---|---|---|
| **Node.js 18+** | Playwright MCP Mod | `node --version` |
| **npm 9+** | Playwright MCP Mod | `npm --version` |
| **Ruby 3.x** | QA report script + CI syntax checks | `ruby --version` |
| **Git** | Clone repos | `git --version` |
| **PowerShell 7+** (`pwsh`) | Setup scripts (Windows) | `pwsh --version` |

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

### 3. Cursor — recommended

Cursor is the recommended client. Open the project folder in Cursor (`File → Open Folder`) and the MCP server and slash commands are almost ready to go.

#### 3a. Update the MCP path

`.cursor/mcp.json` in the repo root pre-configures the MCP server. If you cloned `playwright-mcp-mod` to a different location, update the path:

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

Replace `D:\\DataHen\\projects\\playwright-mcp-mod` with your actual absolute path. On Windows, use `\\` in JSON (or forward slashes — both work). `--caps vision` enables coordinate-based click tools; do not remove it.

#### 3b. Connect the MCP server

1. Go to **Cursor → Settings → MCP**
2. `playwright-mod` should appear — click **Restart** if the status isn't green
3. If still disconnected: **View → Output → MCP** to read the launch error. Common causes: wrong path, missing `lib/index.js` (rebuild), Node.js not on PATH

#### 3c. Sync skills (slash commands)

Run once from the repo root (Windows PowerShell):

```powershell
pwsh -NoProfile -File scripts/setup-agy.ps1
```

```bash
# macOS / Linux
bash scripts/sync-to-claude.sh   # Claude Code path; for Cursor the setup-agy.ps1 equivalent is needed
```

> On Windows, `setup-agy.ps1` syncs skills to `~/.cursor/skills/` (among other paths). Re-run after adding or editing any skill. Restart Cursor after running.

#### 3d. Verify slash commands

In any Cursor chat, type `/` — you should see:

```
/scrape            /navigation-parser    /details-parser
/qa                /run-pipeline         /kb
/greenfield-scrape /api-scrape           ...
```

If nothing appears: re-run `setup-agy.ps1` and restart Cursor.

#### 3e. Verify browser tools

In a Cursor chat:

```
List available MCP tools
```

You should see `browser_grep_html`, `browser_snapshot`, `parser_tester`, `browser_network_requests_simplified`, etc.

#### 3f. Cursor rules vs skills (context layers)

| Layer | File(s) | Loaded when |
|---|---|---|
| Cursor rules | `.cursor/rules/*.mdc` | Automatically, scoped to matching files |
| Agent firmware | `AGENTS.md` | Readable by Cursor as project context |
| Skills | `~/.cursor/skills/<name>/SKILL.md` | On `/<name>` invocation |
| Knowledge base | `docs/shared/` | On demand via `read_file` from inside a skill |

---

### 4. Antigravity CLI (`agy`)

AGY is subscription-based — **no API key required**. Sign in with your Google account. A free tier is available.

#### 4a. Install and sign in

Follow the [Antigravity CLI install guide](https://antigravity.google/docs/gcli-migration). After install, run `agy` once to complete the Google sign-in flow.

#### 4b. Set model (optional)

If you want a specific model, create `.agents/.env` in the repo root:

```env
AGY_MODEL="gemini-2.5-pro"
```

> `.agents/.env` is gitignored. Without it, AGY uses its default model.

#### 4c. Register skills and MCP plugin

```powershell
# Windows
pwsh -NoProfile -File scripts/setup-agy.ps1
```

What it does:

| Step | Where |
|---|---|
| Syncs skills → `~/.gemini/antigravity-cli/skills/` | AGY global — available from any cwd |
| Syncs skills → `~/.cursor/skills/` | Cursor slash commands (same files) |
| Syncs skills → `.claude/commands/` | Claude Code slash commands |
| Runs `agy plugin install` | Registers `playwright-mod` MCP server |

Then start `agy` **from the repo root** (it also auto-discovers workspace skills):

```powershell
agy
```

#### 4d. Update the MCP path

`.agents/mcp_config.json` tells AGY where the MCP server is. If you cloned elsewhere, update the absolute path:

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

Re-run `setup-agy.ps1` (and `agy plugin install`) after changing this file.

---

### 5. Claude Code

Claude Code's project-level slash commands live in `.claude/commands/`. The sync script generates them from the skill files.

#### 5a. Install Claude Code

Download from [claude.ai/code](https://claude.ai/code) or install the VS Code extension. The CLI is `claude`.

#### 5b. Add the MCP server

Create or edit `.mcp.json` in the repo root:

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

Update the path to match your playwright-mcp-mod clone location.

#### 5c. Sync skills → `.claude/commands/`

The `.claude/commands/` directory is already populated (committed to the repo). To refresh it after editing skills:

```powershell
# Windows
pwsh -NoProfile -File scripts/sync-to-claude.ps1
```

```bash
# macOS / Linux
bash scripts/sync-to-claude.sh
```

This strips the YAML frontmatter from each `SKILL.md` and writes the body to `.claude/commands/<name>.md`. Restart Claude Code to pick up changes.

#### 5d. Verify

Type `/scrape` in a Claude Code chat — the slash command should autocomplete. Check MCP with:

```
/mcp
```

`playwright-mod` should appear as connected.

---

### 6. Windsurf

MCP support is available; skills require a manual step.

**MCP:** Edit `~/.windsurf/mcp.json`:

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

**Skills:** Windsurf doesn't natively load `~/.cursor/skills/`. Copy the relevant content from `.agents/skills/<name>/SKILL.md` into Windsurf custom instructions, or keep the phase playbooks (`docs/workflows/phases/`) open as reference.

**Firmware:** Copy the relevant sections of `AGENTS.md` into `.windsurfrules` at the repo root.

Restart Windsurf after saving config.

---

### 7. Verify

```bash
# Deterministic checks — no agent needed
bash scripts/ci-check.sh
```

In Cursor or `agy`:

```
/mcp    → playwright-mod shows connected
/       → skills list appears (/scrape, /qa, /kb, ...)
/kb     → loads docs/shared/KB_HUB.md
```

---

## Compatible clients

Quick compatibility matrix:

| Client | Skills (slash commands) | Firmware (`AGENTS.md`) | MCP (browser/parser tools) | Setup |
|---|---|---|---|---|
| **Cursor** ⭐ | Native — `~/.cursor/skills/` via `setup-agy.ps1` | `.cursor/rules/*.mdc` (included) | `.cursor/mcp.json` (included) | [Step 3](#3-cursor--recommended) |
| **Antigravity CLI** | Native — auto-discovered + global skills | `AGENTS.md` auto-loaded | `.agents/mcp_config.json` | [Step 4](#4-antigravity-cli-agy) |
| **Claude Code** | `.claude/commands/` via `sync-to-claude` script | `CLAUDE.md` (included) | `.mcp.json` | [Step 5](#5-claude-code) |
| **Windsurf** | Manual — copy skill content to custom instructions | `.windsurfrules` (manual) | `~/.windsurf/mcp.json` | [Step 6](#6-windsurf) |
| **GitHub Copilot** | Not natively — use phase docs as reference | `.github/copilot-instructions.md` (manual) | `settings.json → "github.copilot.mcp"` | — |
| **Any MCP client** | — | — | stdio transport, same config | see below |

### Notes per client

**Cursor** — The easiest path. `.cursor/mcp.json` and `.cursor/rules/` are already in the repo. One script run to sync skills; restart to activate.

**Antigravity CLI** — Subscription-based (Google account, free tier available). No API key per call. `AGENTS.md` is auto-loaded as firmware on every `agy` session start. Native plugin system registers the MCP server. Run `setup-agy.ps1`, then start `agy` from the repo root.

**Claude Code** — `CLAUDE.md` (in this repo) is the primary instruction file and is auto-loaded. Skills sync to `.claude/commands/` via `sync-to-claude.ps1` / `sync-to-claude.sh` — these files are committed so slash commands work for anyone who clones the repo. MCP config goes in `.mcp.json` at the repo root.

**Windsurf** — MCP is supported; skills need manual adaptation. Copy relevant content from `AGENTS.md` into `.windsurfrules` for the firmware layer.

**GitHub Copilot (VS Code)** — MCP support added in early 2026 via `settings.json`. Skills don't register natively; use the phase playbooks in `docs/workflows/phases/` as step-by-step references.

**Any MCP-compatible client** — The playwright-mod tools work with any client supporting the MCP stdio transport:

```json
{
  "command": "npx",
  "args": ["<absolute-path-to-playwright-mcp-mod>", "--caps", "vision"]
}
```

The knowledge base (`docs/shared/`) can be read by any agent with filesystem access.

---

## Usage

Run commands from the **repository root** in a fresh session per phase — each phase hands off to the next via state files, so **start a new chat for each phase** to avoid context exhaustion.

### Recommended model per client

| Client | Recommended model | Notes |
|---|---|---|
| **Cursor** | `claude-3.5-sonnet` (Composer) or Auto | Auto mode picks the right model per step; Composer for long phases |
| **Antigravity CLI** | `Gemini 2.5 Flash` | Good balance of speed and quality for scraping workflows |
| **Claude Code** | `claude-sonnet-4-6` or `claude-haiku-4-5` | Sonnet for complex sites; Haiku for simple or API-only pipelines |

You don't need the most expensive model. Flash/Haiku handles most scraping phases well.

### Start here: API first, HTML fallback

**Always try the API approach first.** Most modern sites serve data via a JSON API — the network tab reveals it in seconds, and API scrapers are more reliable and cheaper to run than HTML parsers.

```
# Step 1: try API discovery first
/api-scrape url=https://shop.example.com name=my-shop project=dmart-dloc

# If the agent finds a clean JSON API → continue the API pipeline:
/api-navigation-parser scraper=my-shop project=dmart-dloc
/api-details-parser    scraper=my-shop project=dmart-dloc
/qa                    scraper=my-shop project=dmart-dloc

# If no usable API found → fall back to HTML:
/scrape            url=https://shop.example.com name=my-shop project=dmart-dloc
/navigation-parser scraper=my-shop project=dmart-dloc
/details-parser    scraper=my-shop project=dmart-dloc
/qa                scraper=my-shop project=dmart-dloc
```

Phase 1 (`/api-scrape` or `/scrape`) scans the network log first — if a JSON API is found, it records it in `discovery-state.json` and the HTML path is skipped automatically.

---

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

Continue in separate sessions:

```
/navigation-parser scraper=example-scraper project=greenfield
/details-parser    scraper=example-scraper project=greenfield
/qa                scraper=example-scraper project=greenfield
```

### Retail pipeline (dmart-dloc)

Uses the canonical e-commerce field spec (`field-spec.json`). Try `/api-scrape` first (see above); fall back to `/scrape` if no API found.

```
/scrape            url=https://target-retail-site.com name=my-retail project=dmart-dloc
/navigation-parser scraper=my-retail project=dmart-dloc
/details-parser    scraper=my-retail project=dmart-dloc
/qa                scraper=my-retail project=dmart-dloc
```

### Restaurant pipeline (dhero)

Five phases producing `locations` (restaurants) + `items` (menu). dhero is **API-first by default** — Phase 1 picks a [seeding strategy](docs/workflows/phases/dhero-seeding-strategies.md) (geo grid / H3 hexagon / city list / session bootstrap / URL listings).

```
/scrape                    url=https://food-delivery-site.com name=my-food project=dhero
/navigation-parser         scraper=my-food project=dhero
/restaurant-details-parser scraper=my-food project=dhero
/menu-listings-parser      scraper=my-food project=dhero
/menu-parser               scraper=my-food project=dhero
/dhero-qa                  scraper=my-food
```

### `/run-pipeline` — not recommended

`/run-pipeline` chains all phases in a single session. **Context accumulates across phases and the model loses track of earlier decisions.** Run phases individually instead — each picks up from the state files written by the previous phase.

If you do use it:

```
/run-pipeline project=dmart-dloc url=https://shop.example.com name=my-shop kind=api
```

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
| `/api-scrape`, `/api-navigation-parser`, `/api-details-parser` | 1–3 | API variants — **try these first** |
| `/run-pipeline` | all | All phases in one session — **not recommended** (context loss across phases) |

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

## Local quality checks

Run before committing to catch syntax errors and structural issues early:

```bash
bash scripts/ci-check.sh
```

Checks: `ruby -c` on all boilerplate parsers/libs, required-file existence, `profiles/*.toml` parse, field-spec JSON validity, SKILL frontmatter present.

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
.claude/commands/            # Claude Code slash commands (generated by sync-to-claude)
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
