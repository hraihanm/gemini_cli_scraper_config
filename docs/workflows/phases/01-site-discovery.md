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

## STEP 7: Detect Browser Fetch Requirements

Check if category links (or the first page type for this project) are visible in DOM:

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
  return { found: false, message: "No category links found in DOM" };
})
```

If not found → look for reveal buttons using `browser_snapshot()` and `browser_evaluate()`.

If reveal button found: test click, verify content appears, document selector and puppeteer_code.

Document findings in `discovery-state.json` under `fetch_requirements`:
- `initial_page_needs_browser`: true/false
- `categories_need_browser`: true/false
- `button_to_reveal_categories`: selector, puppeteer_code, wait_time_ms, verified

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
  "_notes": "## Discovery summary (markdown)\\n\\n- Site structure, sample URLs, popups, fetch_type notes\\n- **Next:** `/<next_phase_from_profile> scraper=<scraper_slug> project=<project>`\\n"
}
```

🚨 **MANDATORY**: `discovery-state.json` MUST include a non-empty **`_notes`** string (markdown) covering the same topics the old `discovery-knowledge.md` had: site structure, sample URLs, popup summary, navigation hints, fetch configuration, and the exact next slash command from the profile pipeline (never hardcode `/dmart-navigation-parser`).

---

## STEP 10: Update Boilerplate Files

**Update `{boilerplate.headers_rb}`** (USE ABSOLUTE PATH):
- Read existing file
- Update `URLs::BASE_URL` constant with discovered base URL
- Preserve all other code

**Update `{boilerplate.seeder_rb}`** (USE ABSOLUTE PATH):
- Read existing file
- Update `url:` field with site URL
- Update `page_type:` based on site structure:
  - has_categories → `"categories"`
  - else has_listings → `"listings"`
- Update `fetch_type:` based on `fetch_requirements.initial_page_needs_browser`:
  - true → `"browser"`
  - false → `"standard"`
- If fetch_type = "browser" AND button_to_reveal exists: configure driver block with selector and puppeteer_code
- Preserve all other code

**Verify `config.yaml`** (USE ABSOLUTE PATH):
- Read existing file
- Verify parsers array includes all needed parsers from profile `boilerplate.parsers`
- Usually no changes needed — boilerplate config.yaml is already complete

---

## STEP 11: Update Phase Status

Update `phase-status.json` (USE ABSOLUTE PATH):
```json
"site_discovery": {
  "status": "completed",
  "completed_at": "<timestamp>",
  "discovered_patterns": ["hierarchical", "categories->listings->details"],
  "navigation_depth": 1
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
- ✅ `lib/headers.rb` updated with site URL
- ✅ `seeder/seeder.rb` updated with site URL, page_type, fetch_type
- ✅ `config.yaml` verified
- ✅ `discovery-state.json` written with non-empty `_notes` (REQUIRED for next phase)
- ✅ `session-audit-html_scrape.json` written with accurate `tool_call_counts` (or `tool_call_counts_incomplete`)
- ✅ `field-spec.json` copied to `.scraper-state/`
- ✅ `phase-status.json` updated
- ✅ `browser-context.json` saved
- ✅ Completion report displayed
- ✅ IF auto_next=true: browser closed, next command EXECUTED (not just displayed)
