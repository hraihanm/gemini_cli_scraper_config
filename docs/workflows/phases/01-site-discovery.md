# Phase 1: Site Discovery

**version:** 2.0.0

**Used by:** all projects (dmart-dloc, dhero, etc.)
**Output state files:** `discovery-state.json` (includes human **`_notes`** markdown — no separate `discovery-knowledge.md`), `phase-status.json`, `browser-context.json`
**Next phase:** determined by project profile pipeline (phase at index 1)

**Migration:** If `discovery-knowledge.md` exists from an older run, read it once, merge its text into `discovery-state.json._notes`, then you may delete the `.md` file.

---

## Inputs (from args)

- `url=<site_url>` — REQUIRED — target website URL. USE THIS EXACT URL ONLY.
- `name=<scraper_name>` — REQUIRED
- `project=<profile_name>` — OPTIONAL, default: `dmart-dloc`
- `spec=<path>` — OPTIONAL — field-spec file; default from profile
- `out=<base_dir>` — OPTIONAL — default from profile (`./generated_scraper`)
- `auto_next=true|false` — OPTIONAL, default: false

Parse `{{args}}` immediately. Extract the `url` parameter. Use ONLY that URL — ignore any other URLs in context.

---

## BEFORE YOU START

Remember — USE TOOLS DIRECTLY, DO NOT WRITE CODE. Call `read_file` tool for each file individually.

---

## STEP 1: Load State Files (if exist)

Read files one by one using `read_file` tool (CALL THE TOOL DIRECTLY for each — DO NOT write Python code):

1. Read `generated_scraper/<scraper>/.scraper-state/phase-status.json` (if exists)
2. Read `generated_scraper/<scraper>/.scraper-state/discovery-state.json` (if exists) — human notes live in `_notes` inside this JSON when present
3. (Legacy only) Read `generated_scraper/<scraper>/.scraper-state/discovery-knowledge.md` if it exists and `discovery-state.json` has no `_notes` yet — merge into JSON then prefer JSON-only going forward

If a file doesn't exist, `read_file` returns an error — handle gracefully and continue.

Handle results:
- **phase-status.json exists**: Check `site_discovery.status`
  - `"completed"`: Display summary, suggest next phase from profile pipeline
  - `"in_progress"`: Resume from checkpoint
  - Else: Start fresh
- **discovery-state.json exists**: Use for context
- **No files**: Start fresh (expected for first run)

---

## STEP 2: Load Profile

Read `profiles/<project>.toml` using `read_file` tool.

Extract:
- `template.boilerplate_dir` — path to boilerplate template
- `template.copy_command_windows` / `copy_command_unix` — copy command
- `boilerplate.parsers` — list of parser files that must exist after copy
- `boilerplate.seeder_rb`, `boilerplate.headers_rb` — files to update in Step 8
- `defaults.field_spec` — default field-spec filename
- `defaults.output_dir` — default output directory
- `pipeline.phases` — full pipeline array; find current phase index (0 = this phase), note next phase

---

## STEP 3: Copy Boilerplate Template

Check if scraper directory exists at `{output_dir}/<scraper_name>/`:

**If directory does NOT exist:**
- Run copy command from profile using `run_terminal_cmd`:
  - Windows: profile `template.copy_command_windows` (replace `{scraper}` with scraper name)
  - Linux/Mac: profile `template.copy_command_unix`
- Verify copy by reading a few key files

**If directory ALREADY exists:**
- Read existing files to preserve any customizations
- Only update files that need changes (URLs, fetch_type, etc.)
- Preserve any manual edits to `lib/regex.rb`, `lib/helpers.rb`, etc.

Verify boilerplate structure by reading each file listed in `boilerplate.parsers` plus `seeder_rb`, `headers_rb`, `config_yaml`. If any are missing, report error and stop.

---

## STEP 4: Copy Field Specification

🚨 **CRITICAL**: This MUST be a FILE COPY using `run_terminal_cmd` — NOT read_file + write_file (causes JSON reconstruction).

Determine source file:
- If `spec` parameter provided in args → use that path
- Otherwise → use `defaults.field_spec` from profile

Execute file copy using `run_terminal_cmd`:
- Windows: `copy "<source_absolute_path>" "<destination_absolute_path>"`
- Linux/Mac: `cp "<source_absolute_path>" "<destination_absolute_path>"`
- Destination: `{output_dir}/<scraper>/.scraper-state/field-spec.json` (absolute path)

Forbidden: DO NOT use read_file + write_file — just copy the file directly.

---

## STEP 5: Initialize State Directory

Create `.scraper-state/` directory if it doesn't exist:
- Windows: `mkdir {output_dir}\\<scraper>\\.scraper-state`
- Linux/Mac: `mkdir -p {output_dir}/<scraper>/.scraper-state`

Initialize `phase-status.json` (USE ABSOLUTE PATH):
```json
{
  "scraper_name": "<scraper_slug>",
  "version": "1.0.0",
  "created_at": "<timestamp>",
  "current_phase": "site_discovery",
  "completed_phases": [],
  "phase_status": {
    "site_discovery": {"status": "in_progress"},
    "navigation_discovery": {"status": "pending"},
    "detail_discovery": {"status": "pending"}
  }
}
```

---

## STEP 6: Navigate to Site and Handle Popups

Navigate: `browser_navigate(<url from args>)`

**🚨 CRITICAL PRIORITY: Handle popups FIRST — follow Standard Popup Handling Sequence from `docs/shared/agent-rules-gemini.md`**

After popups cleared: `browser_snapshot()` to understand page structure.

---

## STEP 7: Detect Fetch Strategy

**Priority order — stop at the first that works:**

| Priority | Method | When it applies |
|---|---|---|
| 1 | **Network API** | Site fires a JSON API call on page load (zero extra cost — requests already captured) |
| 2 | **Framework JSON** | Next.js / Nuxt / Redux hydration blob baked into initial HTML |
| 3 | **DOM links** | Category links already rendered in the DOM |
| 4 | **Reveal button** | Links hidden behind a click — `fetch_type: "browser"` last resort |

### 7a: Network scan (highest priority)

Immediately after navigate and popup handling, run:

```javascript
browser_network_requests_simplified()
```

Requests fired during page load are already captured — this is zero-overhead. Scan for API endpoints serving navigation or category data:
- URL contains: `/api/`, `/v1/`–`/v5/`, `/navigation`, `/categories`, `/menu`, `/graphql`, `/search`
- Content-type: `application/json`
- Response body: array or object containing category/navigation items

**If a navigation API is found:**
1. Note the full URL
2. Proceed to **STEP 7d** (API Header Verification)
3. Once verified: set `api_config.has_api: true`, `api_config.navigation_api_url: <url>`, `fetch_requirements.initial_page_needs_browser: false`
4. Seeder will use this URL with `fetch_type: "standard"` (STEP 10)
5. Skip 7b and 7c — proceed to STEP 8

**If no navigation API found → proceed to 7b.**

### 7b: Framework JSON (second priority)

Probe for framework hydration data baked into the initial HTML:

```javascript
browser_evaluate(() => {
  // Next.js
  const next = document.querySelector('#__NEXT_DATA__');
  if (next) return { framework: 'nextjs', found: true, preview: next.textContent.substring(0, 300) };
  // Nuxt
  const nuxt = document.querySelector('#__NUXT_DATA__') || document.querySelector('script[data-nuxt-data]');
  if (nuxt) return { framework: 'nuxt', found: true, preview: nuxt.textContent.substring(0, 300) };
  // Generic embedded state
  const scripts = [...document.querySelectorAll('script[type="application/json"]')];
  if (scripts.length) return { framework: 'generic', found: true, count: scripts.length, preview: scripts[0].textContent.substring(0, 300) };
  return { found: false };
})
```

**If framework JSON found:**
1. Extract the full blob: `browser_evaluate(() => JSON.parse(document.querySelector('#__NEXT_DATA__').textContent))`
2. Navigate the JSON tree for category/navigation data (keys: `categories`, `navigation`, `menu`, `nav`, `catalog`)
3. Two outcomes:
   - **Categories baked in** → extract URLs and names directly; seeder fetches the homepage with `fetch_type: "standard"` and the categories parser reads `#__NEXT_DATA__`; set `api_config.navigation_api_url: "__NEXT_DATA__"` (or `__NUXT_DATA__`) as the source marker
   - **API URL embedded in props/config** → note the URL, proceed to **STEP 7d** (API Header Verification), then treat as a network API
4. Skip 7c — proceed to STEP 8 (or 7d if an API URL was extracted)

**If no framework JSON found → proceed to 7c.**

### 7c: DOM inspection (third priority)

Check if category links are already rendered:

```javascript
browser_evaluate(() => {
  const categorySelectors = [
    '.category-item a', '.nav-menu a', '.category-link',
    '[class*="category"] a', 'nav a[href*="category"]',
    'a[href*="/category"]', 'a[href*="/categories"]'
  ];
  for (const selector of categorySelectors) {
    try {
      const elements = document.querySelectorAll(selector);
      if (elements.length > 0) {
        return {
          found: true, selector: selector, count: elements.length,
          sampleText: Array.from(elements).slice(0, 3).map(el => el.textContent.trim())
        };
      }
    } catch (e) {}
  }
  return { found: false };
})
```

If links visible → `fetch_type: "standard"`, no driver. Proceed to STEP 8.

If not visible → proceed to 7d reveal button.

### 7d: API Header Verification / Reveal button

- **If here from 7a or 7b (API found):** run the API Header Verification protocol from STEP 7b (below). Confirm the endpoint returns real data with stable headers.
- **If here from 7c (links hidden, last resort):** find the reveal button via `browser_snapshot()` and `browser_evaluate()`. Test click, verify content appears, document selector and puppeteer_code. Set `fetch_type: "browser"`. **Puppeteer driver code only — no Playwright pseudo-selectors (`:has-text()`, `:text()`, `locator()`). Use XPath `page.$x()` or `page.evaluate()` for text-based clicks (see `docs/shared/datahen-conventions.md` → "Browser Fetch").**

Document findings in `discovery-state.json` under `fetch_requirements`:
- `initial_page_needs_browser`: true/false
- `categories_need_browser`: true/false
- `button_to_reveal_categories`: selector, puppeteer_code, wait_time_ms, verified

---

## STEP 7b: API Header Verification

**Run this step whenever an API endpoint is discovered** (via `browser_network_requests_simplified` or `browser_network_search`) — regardless of project type.

### Step A — Test bare

```javascript
browser_request({ url: "<discovered_api_url>", method: "GET" })
```

If the response contains real data (non-empty array or object with items) → bare fetch works, no custom headers needed. Set `api_config.requires_custom_headers: false` and skip to STEP 8.

If response is empty, `{}`, `[]`, or an error status → proceed to Step B.

### Step B — Capture working headers from browser

```javascript
browser_get_request_context({ urlPattern: "<api_url_substring>" })
```

This returns the complete request headers pre-classified into `stable` (safe to hardcode) and `ephemeral` (session-bound) groups, plus cookies extracted separately. No need to search for individual header names — the full picture comes back in one call.

Example output:
```json
{
  "requestHeaders": {
    "stable": { "appversion": "2", "language": "en", "snoonu-app-platform": "Web" },
    "ephemeral": { "cookie": "session=abc...", "traceparent": "00-..." }
  },
  "cookies": { "session": "abc123", "_ga": "GA1.1..." }
}
```

### Step C — Test with stable headers only

Re-run `browser_request` with only the `stable` headers from Step B. Confirm response has real data.

- **Success** → record stable headers; set `requires_browser_session: false`
- **Still empty** → some ephemeral header is also required; set `requires_browser_session: true`; note in `_notes` that this API may need a live browser session or token refresh mechanism

Record all findings in `discovery-state.json.api_config` (see schema in STEP 9).

---

## STEP 8: Analyze Site Structure

Navigate through site to determine:
- Navigation patterns: main menu, breadcrumbs, product grid
- Page types present: categories, subcategories, listings, details (or for dhero: listings, restaurant_details, menu)
- Navigation depth: flat / one-level / two-level / three+

Discover sample URLs:
- Sample of each page type encountered
- **TRACK ALL URLs**: Record in `discovery-state.json` under `urls_accessed.discovery_urls`
- Update `urls_accessed.last_accessed_url` and `urls_accessed.last_accessed_at` after each navigation

---

## STEP 8b: Seeding Strategy (dhero only)

**Run this step when `project=dhero`.** Choosing how to seed is the single highest-leverage architectural decision for a dhero scraper — most dhero sources are **not** crawled from a URL listing page. Inspect the site/app and pick exactly one strategy, then record it.

| Strategy | When | How it seeds | Reference example |
|---|---|---|---|
| `geo_grid` | API takes lat/long; coverage needs many points | `input/geo.csv` of lat/long(/city) rows → one listings request per point | totersapp, mrsool |
| `h3_hexagon` | API takes an H3 cell / hexagon id | city→hexagon map → widgets/merchant-list per cell | lezzoo |
| `city_list` / `neighborhood_list` | API takes a city/neighborhood/zone id | iterate the id list → listings per id | talabatey, jahez |
| `url_listings` | Real website with a paginated restaurant list (HTML) | seed the listings URL, paginate | openrice (HTML) |
| `session_bootstrap` | API requires a user/token + set-location before listings | seed a bootstrap page that mints a token/sets location, then chains to listings | monchis |

Detection cues:
- Open the app/site, watch `browser_network_requests_simplified` while the restaurant list loads. If the listing request carries `lat`/`lng`, `hexagonId`, `city`/`zone`, or an `Authorization` token → it is API-driven (geo/h3/city/session), not `url_listings`.
- GraphQL (`POST /graphql`) is a transport, not a seeding strategy — combine with whichever geo/city model the query variables use (yummy = geo_grid + GraphQL).
- For `session_bootstrap`, capture the bootstrap request/response chain and note which header the token lands in (see STEP 7b).

Record the decision in `discovery-state.json.seeding` (schema in STEP 9) and add a `seeding_strategy` `_log` entry (`{ "action": "seeding_strategy", "strategy": "...", "detail": "..." }`). When a geo/city input file is needed, note its expected columns so the seeder and `input/<file>.csv` can be filled in STEP 10.

---

## STEP 8c: Pagination Surface Probe (all projects)

**Run this step after STEP 8 (and STEP 8b for dhero).** Load `docs/shared/pagination-network-exhaustion.md` for the full protocol. For every list surface identified in STEP 8 (product category listings, restaurant list, menu root, search results, etc.), run the three mandatory probes:

1. `browser_detect_pagination()` — static detection
2. Scroll + interaction — scroll to bottom 2–3 times; click each visible category/tab/filter; after each action run `browser_network_requests_simplified()` to capture newly triggered requests
3. Network capture — `browser_network_search({ query: "<api_keyword>", searchIn: ["requestUrl","responseBody"] })` on any promising endpoints; `browser_get_request_context` to classify stable vs ephemeral headers

Classify each surface (see protocol: `page_number | offset | cursor | infinite_scroll | geo_fanout | next_button | none`).

`none` is only valid when all three probes are logged with evidence. A `none` without evidence is a **structural error — STOP**.

Record in `discovery-state.json` under `pagination_surfaces` (schema in STEP 9). Add a `_log` entry:
```json
{ "action": "pagination_probe", "surface": "<surface>", "strategy": "<strategy>", "evidence": "<what triggered / what was absent>" }
```

---

## STEP 9: Write discovery-state.json (USE ABSOLUTE PATH)

Path: `{output_dir}/<scraper>/.scraper-state/discovery-state.json`

🚨 **MANDATORY**: This file MUST be written — required by the next phase.

```json
{
  "site_url": "<input_url>",
  "scraper_name": "<scraper_slug>",
  "project": "<project_name>",
  "discovered_at": "<timestamp>",
  "site_structure": {
    "has_categories": true,
    "has_subcategories": false,
    "has_listings": true,
    "navigation_depth": 1,
    "listing_pattern": "pagination"
  },
  "page_types_found": ["categories", "listings", "details"],
  "sample_urls": {
    "category": "https://example.com/categories",
    "listings": "https://example.com/categories/electronics",
    "detail": "https://example.com/p/123"
  },
  "navigation_notes": {
    "category_pattern": "Main menu uses dropdown",
    "pagination_pattern": "Query parameter ?page=2",
    "special_notes": ""
  },
  "urls_accessed": {
    "discovery_urls": ["<all urls visited>"],
    "last_accessed_url": "<last url>",
    "last_accessed_at": "<timestamp>"
  },
  "popup_handling": {
    "popups_encountered": false,
    "handling_method": "none",
    "successful_selectors": [],
    "coordinate_clicks": [],
    "notes": ""
  },
  "fetch_requirements": {
    "initial_page_needs_browser": false,
    "categories_need_browser": false,
    "button_to_reveal_categories": {
      "exists": false,
      "selector": null,
      "puppeteer_code": null,
      "wait_time_ms": null,
      "verified": false
    }
  },
  "api_config": {
    "has_api": false,
    "navigation_api_url": null,
    "endpoint_pattern": null,
    "requires_custom_headers": false,
    "stable_headers": {},
    "ephemeral_headers_noted": [],
    "requires_browser_session": false,
    "bare_test": "not_tested",
    "headers_test": "not_tested"
  },
  "seeding": {
    "strategy": "geo_grid | h3_hexagon | city_list | neighborhood_list | url_listings | session_bootstrap",
    "input_file": "input/geo.csv",
    "geo": { "lat_col": "lat", "long_col": "long", "city_col": "city" },
    "auth": { "required": false, "bootstrap_page_type": null, "token_header": null },
    "endpoints": { "listings": null, "merchant_list": null, "menu": null },
    "pagination": "page_number | offset | cursor | hexagon_fanout | next_button"
  },
  "pagination_surfaces": [
    {
      "surface": "restaurant_list | product_listings | category_listings",
      "strategy": "page_number | offset | cursor | infinite_scroll | geo_fanout | next_button | none",
      "endpoint": null,
      "params": [],
      "stable_headers": {},
      "probe_log": ["static_detect", "scroll", "tab_click", "network_capture"],
      "evidence": "<what triggered / what was absent>",
      "pagination_warning": null
    }
  ],
  "_notes": "## Discovery summary (markdown)\\n\\n- Site structure, sample URLs, popups, fetch_type notes\\n- (dhero) seeding strategy + input file\\n- **Next:** `/<next_phase_from_profile> scraper=<scraper_slug> project=<project>`\\n"
}
```

🚨 **MANDATORY**: `discovery-state.json` MUST include a non-empty **`_notes`** string (markdown) covering the same topics the old `discovery-knowledge.md` had: site structure, sample URLs, popup summary, navigation hints, fetch configuration, and the exact next slash command from the profile pipeline (never hardcode `/dmart-navigation-parser`).

---

## STEP 9b: Validate Output Contract

Re-read the just-written `discovery-state.json` and confirm every Required field is present and non-null **before** proceeding to STEP 10.

| Field | JSON path | Required |
|---|---|---|
| Scraper name | `.scraper_name` | Yes |
| Site URL | `.site_url` | Yes |
| has_categories | `.site_structure.has_categories` | Yes (boolean) |
| has_listings | `.site_structure.has_listings` | Yes (boolean) |
| navigation_depth | `.site_structure.navigation_depth` | Yes (integer) |
| Listings sample URL | `.sample_urls.listings` | Yes — non-null, non-empty |
| popup_handling | `.popup_handling` | Yes — object (may be `{popups_encountered: false}`) |
| fetch_type flag | `.fetch_requirements.initial_page_needs_browser` | Yes (boolean) |
| Navigation API URL | `.api_config.navigation_api_url` | Yes — string or null; non-null means seeder uses this URL |
| Human notes | `._notes` | Yes — non-empty string |
| Pagination surfaces | `.pagination_surfaces` | Yes — array, ≥1 entry per list surface found; `strategy:"none"` requires non-empty `evidence` |

**If any Required field is missing or null: STOP — do not proceed.**
Fix the gap (re-navigate the site if needed) and rewrite `discovery-state.json`. Only continue when all Required fields are confirmed.

---

## STEP 10: Update Boilerplate Files

**Update `{boilerplate.headers_rb}`** (USE ABSOLUTE PATH):
- Read existing file
- Update `URLs::BASE_URL` constant with discovered base URL
- If `api_config.requires_custom_headers: true`: add `API_HEADERS` constant to the `ReqHeaders` module — merge `MINIMAL_HEADERS` with each stable header from `api_config.stable_headers`:
  ```ruby
  API_HEADERS = MINIMAL_HEADERS.merge({
    "header-name" => "value",   # one entry per stable header discovered
    # ...
  })
  ```
- Preserve all other code

**Update `{boilerplate.seeder_rb}`** (USE ABSOLUTE PATH):
- Read existing file
- **dhero:** branch on `discovery-state.json.seeding.strategy` — uncomment the matching block in the boilerplate seeder (`geo_grid`/`h3_hexagon`/`city_list`/`session_bootstrap`/`url_listings`), delete the others, and fill PLACEHOLDERs. For geo/city strategies, also create `input/<file>.csv` with the columns noted in STEP 8b. See `docs/workflows/phases/dhero-seeding-strategies.md`. For non-dhero projects, continue below.
- **If `api_config.navigation_api_url` is non-null (API found in STEP 7a):**
  - Set `url:` to `api_config.navigation_api_url` (not the homepage)
  - Set `fetch_type: "standard"`
  - No driver block needed
- **Otherwise:** Update `url:` field with site URL
- Update `page_type:` based on site structure:
  - has_categories → `"categories"`
  - else has_listings → `"listings"`
- **Apply `[scope].categories` filter if present in profile**: when the profile defines `scope.categories`, only seed categories whose name contains one of those strings (case-insensitive). Skip all others and log each skipped category: `warn "SCOPE: skipping category '#{name}' — not in #{scope_categories.inspect}"`
- If `api_config.navigation_api_url` is null: update `fetch_type:` based on `fetch_requirements.initial_page_needs_browser`:
  - true → `"browser"`
  - false → `"standard"`
- If `api_config.requires_custom_headers: true`: add `headers: ReqHeaders::API_HEADERS` and `fetch_type: "standard"` to every `pages <<` entry that targets an API URL
- If fetch_type = "browser" AND button_to_reveal exists: configure driver block with selector and puppeteer_code
- Preserve all other code

**Verify `config.yaml`** (USE ABSOLUTE PATH):
- Read existing file
- Verify parsers array includes all needed parsers from profile `boilerplate.parsers`
- If `fetch_type: "browser"` is used anywhere: uncomment the `browser_fetcher_image` line:
  ```yaml
  browser_fetcher_image: gcr.io/answers-engine-cloud/fetch-browser-chrome1
  ```
- Otherwise no changes needed — boilerplate config.yaml is already complete

---

## STEP 11: Update Phase Status

Update `phase-status.json` (USE ABSOLUTE PATH):
```json
"site_discovery": {
  "status": "completed",
  "completed_at": "<timestamp>",
  "discovered_patterns": ["hierarchical", "categories->listings->details"],
  "navigation_depth": 1,
  "validated_output": true
}
```

Save `browser-context.json` (USE ABSOLUTE PATH):
```json
{
  "last_url_visited": "<last_url_analyzed>",
  "last_phase": "site_discovery",
  "last_activity": "<timestamp>",
  "scraper_name": "<scraper_slug>"
}
```

---

## STEP 12: Write Session Audit

Save `session-audit-html_scrape.json` (USE ABSOLUTE PATH):
Path: `{output_dir}/<scraper>/.scraper-state/session-audit-html_scrape.json`

🚨 **MANDATORY — counts must be real**: Before writing this file, tally **actual** tool calls made during this session (increment per call). **Do not** ship all zeros unless no browser/network/parser tools were used. If you cannot reconstruct counts, set `"tool_call_counts_incomplete": true` and explain in `improvement_suggestions` — all-zero counts without that flag is a **completion failure**.

```json
{
  "phase": "html_scrape",
  "scraper": "<scraper_slug>",
  "completed_at": "<ISO timestamp>",
  "tool_call_counts": {
    "browser_view_html": 0,
    "browser_network_download": 0,
    "browser_request": 0,
    "parser_tester": 0,
    "browser_grep_html": 0,
    "browser_network_search": 0,
    "browser_extract_json_ld": 0,
    "browser_count_selector": 0,
    "browser_extract_images": 0,
    "browser_detect_pagination": 0
  },
  "expensive_tool_log": [],
  "unexpected_situations": [],
  "popup_handling": "<description>",
  "parser_test_iterations": 0,
  "parser_errors": [],
  "improvement_suggestions": []
}
```

---

## STEP 13: Completion Report

Display:
```
✅ Site Discovery Complete

Scraper: <scraper_slug>
Site: <site_url>
Project: <project>

Boilerplate Copied:
- {boilerplate_dir}/ → generated_scraper/<scraper>/ ✅

Files Updated:
- lib/headers.rb ✅ (BASE_URL updated)
- seeder/seeder.rb ✅ (URL, page_type, fetch_type updated)
- config.yaml ✅ (verified)

Discovered:
- Navigation depth: <depth> levels
- Page types: <list>
- Sample URLs: <count> URLs documented

Browser Fetch Configuration:
- Initial page fetch_type: <standard|browser>
- Button to reveal categories: <selector or "none">

State Files Created:
- .scraper-state/discovery-state.json ✅ (includes `_notes`)
- .scraper-state/field-spec.json ✅
- .scraper-state/phase-status.json ✅
- .scraper-state/session-audit-html_scrape.json ✅

Next Command:
/<next_phase_from_profile> scraper=<scraper_slug> project=<project>
```

---

## STEP 14: Auto-Chaining (if auto_next=true)

Follow the auto-chain execution steps in `docs/shared/agent-rules-gemini.md`.

**Determine next command**:
1. Look up `pipeline.phases` from profile (already loaded)
2. This is phase at index 0 (`scrape`)
3. Next phase = `pipeline.phases[1].phase`
4. Spawn: `/<next_phase> scraper=<scraper_slug> project=<project> auto_next=true`

---

## Completion Checklist

- ✅ Boilerplate template copied to `generated_scraper/<scraper>/`
- ✅ Fetch strategy probe completed (STEP 7) — framework JSON → network scan → DOM → reveal button; `api_config.navigation_api_url` set or confirmed null
- ✅ `lib/headers.rb` updated with site URL
- ✅ `seeder/seeder.rb` updated — URL is navigation_api_url (if found) or homepage; fetch_type matches
- ✅ `config.yaml` verified — `browser_fetcher_image` uncommented if any page uses fetch_type: browser
- ✅ `discovery-state.json` written with non-empty `_notes` (REQUIRED for next phase)
- ✅ Pagination surfaces probed (STEP 8c) — static detect + scroll + interaction + network; `pagination_surfaces` array written
- ✅ Output contract validated (STEP 9b) — all Required fields confirmed non-null
- ✅ `session-audit-html_scrape.json` written with accurate `tool_call_counts` (or `tool_call_counts_incomplete`)
- ✅ `field-spec.json` copied to `.scraper-state/`
- ✅ `phase-status.json` updated
- ✅ `browser-context.json` saved
- ✅ Completion report displayed
- ✅ IF auto_next=true: browser closed, next command EXECUTED (not just displayed)
