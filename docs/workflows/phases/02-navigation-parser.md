# Phase 2: Navigation Parser

**version:** 2.0.0

**Used by:** all projects (dmart-dloc, dhero, etc.)
**Reads:** `discovery-state.json` (use `_notes` inside JSON; legacy `discovery-knowledge.md` optional for one-time merge)
**Writes:** `navigation-selectors.json` (includes human **`_notes`** — no separate `navigation-knowledge.md`)
**Edits:** parser files listed in `boilerplate.parsers` (excluding the final details/restaurant/menu parser)
**Next phase:** determined by project profile pipeline (phase at index 2)

---

## Inputs (from args)

- `scraper=<scraper_name>` — REQUIRED — scraper must exist with `discovery-state.json`
- `project=<profile_name>` — OPTIONAL, default: `dmart-dloc`
- `resume-url=<url>` — OPTIONAL — resume browser from this URL
- `out=<base_dir>` — OPTIONAL — defaults to `./generated_scraper`
- `auto_next=true|false` — OPTIONAL, default: false

---

## BEFORE YOU START

Remember — USE TOOLS DIRECTLY, DO NOT WRITE CODE.

---

## STEP 1: Load State Files and Profile

**Load profile** (`profiles/<project>.toml`) — extract `boilerplate.parsers`, pipeline, template info.

**Load state files** (one by one, handle missing gracefully):
1. `generated_scraper/<scraper>/.scraper-state/phase-status.json`
2. `generated_scraper/<scraper>/.scraper-state/discovery-state.json` (read `_notes` for human context)
3. (Legacy) `discovery-knowledge.md` only if present and `_notes` in discovery-state is empty — merge then prefer JSON
4. `generated_scraper/<scraper>/.scraper-state/navigation-selectors.json` (if resuming; may include `_notes`)
5. (Legacy) `navigation-knowledge.md` only if present — merge into `navigation-selectors.json._notes` when rewriting

Parse:
- `discovery-state.json`: `has_categories`, `has_subcategories`, `has_listings`, `navigation_depth`, `sample_urls`, `popup_handling` strategy, and `_notes` when present
- `phase-status.json`: check `navigation_discovery.status` — if "completed" display summary and stop

**Load existing parser files** (one by one):
- Read each file listed in profile `boilerplate.parsers` EXCEPT the last one (details/restaurant/menu — that's the next phase)
- Example for dmart-dloc: read `categories.rb`, `subcategories.rb`, `listings.rb`
- Example for dhero: read `listings.rb` only (restaurant_details and menu are handled by later phases)

If any navigation parser files are missing: report error — "Boilerplate not found. Run: /scrape url=<url> name=<scraper> project=<project>"

**Validate prerequisites**:
- `discovery-state.json` MUST exist
- Navigation parser files MUST exist from boilerplate
- If missing: stop with error

---

## STEP 2: Test Existing Parsers

Before editing any parser, test it to see if it already works.

For each navigation parser file (categories.rb, subcategories.rb, listings.rb — or project equivalent):

a) Navigate to the sample URL for that page type (from `discovery-state.json.sample_urls`)
b) Handle popups (use `popup_handling` strategy from discovery-state.json)
c) Test with parser_tester:
```javascript
parser_tester({
  scraper_dir: "<absolute_path>/generated_scraper/<scraper>",
  parser_path: "parsers/categories.rb",
  page_type: "categories",
  auto_download: true,
  vars: '{"base_url":"<site_url>"}',
  quiet: false
})
```

Decision:
- Parser passes → skip or enhance (keep working)
- Parser fails → discover new selectors and edit

---

## STEP 3: Categories Parser (if has_categories)

Skip if `discovery-state.json.site_structure.has_categories == false`.

a) Navigate to `sample_urls.category` if not already there
b) Handle popups using stored strategy
c) Run `browser_detect_pagination` shortcut first (skip manual discovery if it returns a clear strategy)
d) Discover category link selectors — follow `docs/shared/selector-discovery.md` protocol:
   - `browser_grep_html(query: "<visible_category_name>")`
   - `browser_inspect_element(ref)` on snapshot ref
   - `browser_verify_selector()` to confirm

e) Detect if categories need browser fetch (see `docs/shared/selector-discovery.md` "Browser Fetch Detection" section)
f) Edit `parsers/categories.rb` (USE ABSOLUTE PATH):
   - Replace category link selector
   - Update `fetch_type` based on `categories.needs_browser_fetch`
   - Configure driver block if browser fetch needed
   - Fix any incomplete conditional statements
   - Preserve require statements, base_url logic, vars passing, save_pages calls
   - **NEVER** redeclare `pages`, `outputs`, `page`, `content`

g) Test parser with parser_tester (auto_download: true)
h) Save checkpoint in `phase-status.json`

---

## STEP 4: Subcategories Parser (if has_subcategories)

Skip if `discovery-state.json.site_structure.has_subcategories == false`.

Same workflow as Step 3 but for subcategory links and `parsers/subcategories.rb`.

---

## STEP 5: Listings Parser

a) Navigate to `sample_urls.listings`
b) Handle popups
c) **PAGINATION DETECTION** — run shortcut first:
```javascript
browser_detect_pagination({ current_url: "<current listing page URL>" })
```
Use result directly if strategy is clear. Only fall back to manual strategies if `strategy: "unknown"`.

d) Discover product link selector using `browser_grep_html` then `browser_inspect_element`

e) **Manual pagination strategies** (only if `browser_detect_pagination` returned `"unknown"` OR its strategy fails in practice):

   **Mandatory fallback chain (never silently stay on page 1):**
   1. **Strategy 1 — Count-based (try first):** find product count / results text → `browser_count_selector` → derive pages → navigate to page 2 and confirm new products or URLs.
   2. **If Strategy 1 fails** (no count element, regex mismatch, or page 2 looks identical to page 1): immediately try **Strategy 2 — Next button** (`browser_grep_html` / snapshot for `rel=next`, "Next", chevrons) and validate href.
   3. **If Strategy 2 fails:** **Strategy 3 — Infinite scroll / load-more** (scroll + `browser_network_requests_simplified` or load-more button).
   4. **If Strategy 3 fails:** **Strategy 4/5 — URL patterns** (`?page=`, `/page/2`, offset params).

   **Page-1-only guard:** After implementing pagination, if the listings parser still only ever queues **page-1** detail URLs, set `navigation-selectors.json` → `listings.pagination_warning` to a **non-empty** string describing which strategies were tried and what failed. Include the same warning in `_notes` and echo it in **bold** in the completion report.

f) Edit `parsers/listings.rb` (USE ABSOLUTE PATH):
   - Replace product link selector
   - Update Strategy 1 with discovered `product_count_selector`, `product_count_regex`, `products_per_page`, pagination pattern
   - Keep Strategy 1 as primary — **activate fallbacks in code** when count-based pagination yields no second page
   - **URL deduplication:** when enqueueing detail URLs in `pages <<`, skip URLs already seen in this parser pass (normalize URL: strip fragment, optional trailing slash); use a `Set` / hash keys in Ruby to avoid duplicate detail jobs
   - **Multi-page selector verification:** before setting `verified: true` on `product_link_selector` in `navigation-selectors.json`, run `browser_verify_selector` (or equivalent) on **at least two** distinct listing surfaces (e.g. category A page 1 and category B page 1, or same category page 1 vs page 2). If the second surface fails, iterate selector until both pass **or** lower `confidence` below 0.9 and document in `_notes`
   - Update vars passing (rank, page_number, listing_position, category_name, breadcrumb)
   - Preserve save_pages calls

g) Test parser with parser_tester
h) Extract `sample_detail_urls` from test output for next phase

---

## STEP 6: Pipeline Smoke Test

After all navigation parsers tested individually, verify end-to-end chain:

a) Reset local state:
```javascript
datahen_run({ scraper_dir: "<abs_path>", command: "reset" })
```

b) Seed:
```javascript
datahen_run({ scraper_dir: "<abs_path>", command: "seed" })
```

c) Step through each navigation parser (count: 2, delay: 0):
```javascript
datahen_run({ scraper_dir: "<abs_path>", command: "step", page_type: "categories", count: 2, delay: 0 })
datahen_run({ scraper_dir: "<abs_path>", command: "step", page_type: "subcategories", count: 2, delay: 0 })
datahen_run({ scraper_dir: "<abs_path>", command: "step", page_type: "listings", count: 2, delay: 0 })
```
(Skip subcategories step if `has_subcategories == false`)

d) Check queue:
```javascript
datahen_run({ scraper_dir: "<abs_path>", command: "pages", status_filter: "to_fetch", limit: 5 })
```

e) PASS criteria:
- No `parsing_failed` pages for any navigation parser
- After listings step: next page_type pages appear in `to_fetch` queue (e.g., "details")
- Queued pages contain expected vars (category_name, breadcrumb, rank, page_number)

f) If FAIL: fix parser → reset → re-seed → re-step → re-check

---

## STEP 7: Write navigation-selectors.json (USE ABSOLUTE PATH)

Path: `{output_dir}/<scraper>/.scraper-state/navigation-selectors.json`

```json
{
  "categories": {
    "category_link_selector": [".category-item a"],
    "needs_browser_fetch": false,
    "button_to_reveal": { "exists": false },
    "verified": true,
    "confidence": 0.95,
    "test_urls": ["<url>"]
  },
  "subcategories": { ... },
  "listings": {
    "product_link_selector": [".product-card a"],
    "pagination_strategy": "count_based",
    "pagination_pattern": "query_param",
    "pagination_url_template": "?page={num}",
    "product_count_selector": ".result-count",
    "product_count_regex": "/(\\d+)\\s*(?:results?|products?)/i",
    "products_per_page": 24,
    "pagination_warning": "",
    "verified": true,
    "confidence": 0.95,
    "sample_detail_urls": ["<url1>", "<url2>"]
  },
  "_notes": "## Navigation phase (markdown)\\n\\n- Parsers touched, pagination strategy chain, smoke test result\\n- Vars flow categories → listings → details\\n- **Next:** `/<next_phase_from_profile> ...`\\n",
  "urls_accessed": {
    "categories_discovery": ["<url>"],
    "listings_discovery": ["<url>"],
    "last_tested_url": "<url>",
    "last_tested_at": "<timestamp>"
  }
}
```

🚨 **MANDATORY:** `navigation-selectors.json` MUST include a non-empty top-level **`_notes`** string (markdown) covering: parsers updated, selectors + confidence, **pagination strategy chain** (which strategy won; if `pagination_warning` set, explain), vars flow, sample detail URLs, smoke test outcome, and the exact next slash command from the profile (never hardcode `/dmart-details-parser`).

---

## STEP 8: Update Phase Status and Browser Context

`phase-status.json` — set `navigation_discovery.status = "completed"`, add `completed_at` and checkpoints.

`browser-context.json` — update with last URL, `"last_phase": "navigation_discovery"`.

---

## STEP 9: Write Session Audit

Save `session-audit-html_navigation.json` (same structure as Phase 1 audit, with `"phase": "html_navigation"`). **Tally real `tool_call_counts`** (same rules as Phase 1 — no silent all-zeros). If counts cannot be reconstructed, set `"tool_call_counts_incomplete": true` and document in `improvement_suggestions`.

---

## STEP 10: Completion Report

Display completion summary. The "Next Command" line MUST use the next phase from the project pipeline profile (NOT `/dmart-details-parser`).

---

## STEP 11: Auto-Chaining (if auto_next=true)

Follow `docs/shared/agent-rules-gemini.md` auto-chain rules.

**Determine next command**:
- This is phase at index 1 in the pipeline
- Next phase = `pipeline.phases[2].phase`
- Spawn: `/<next_phase> scraper=<scraper_slug> project=<project> auto_next=true`

---

## Completion Checklist

- ✅ Navigation parser files edited and tested (categories, subcategories if applicable, listings)
- ✅ `config.yaml` verified
- ✅ `navigation-selectors.json` written (includes `_notes` and `listings.pagination_warning` when applicable)
- ✅ `session-audit-html_navigation.json` with accurate tool counts
- ✅ Pipeline smoke test passed
- ✅ `phase-status.json` updated
- ✅ Sample detail URLs extracted and saved
- ✅ Completion report shown with correct next command from profile
- ✅ IF auto_next=true: browser closed, next command EXECUTED
