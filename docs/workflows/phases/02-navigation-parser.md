# Phase 2: Navigation Parser

**Used by:** all projects (dmart-dloc, dhero, etc.)
**Reads:** `discovery-state.json`, `discovery-knowledge.md`
**Writes:** `navigation-selectors.json`, `navigation-knowledge.md`
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
2. `generated_scraper/<scraper>/.scraper-state/discovery-state.json`
3. `generated_scraper/<scraper>/.scraper-state/discovery-knowledge.md`
4. `generated_scraper/<scraper>/.scraper-state/navigation-selectors.json` (if resuming)
5. `generated_scraper/<scraper>/.scraper-state/navigation-knowledge.md` (if resuming)

Parse:
- `discovery-state.json`: `has_categories`, `has_subcategories`, `has_listings`, `navigation_depth`, `sample_urls`, `popup_handling` strategy
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

e) **Manual pagination strategies** (only if browser_detect_pagination returned "unknown"):
   - **Strategy 1 (Count-Based — TOP PRIORITY)**:
     * Find product count element: `browser_grep_html(query: "results")` or `browser_grep_html(query: "products")`
     * Verify with `browser_count_selector({ selector: ".results-count", expected_min: 1 })`
     * Determine count regex pattern
     * Count products per page
     * Test pagination URL pattern (?page=2, /page/2, etc.)
   - **Strategy 2 (Next Button)**: find next button, extract href pattern
   - **Strategy 3 (Infinite Scroll)**: scroll detection + network request monitoring
   - **Strategy 4/5 (URL patterns)**: test query param and path patterns

f) Edit `parsers/listings.rb` (USE ABSOLUTE PATH):
   - Replace product link selector
   - Update Strategy 1 with discovered `product_count_selector`, `product_count_regex`, `products_per_page`, pagination pattern
   - Keep Strategy 1 as primary/active — only use fallbacks if count cannot be discovered
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
    "verified": true,
    "confidence": 0.95,
    "sample_detail_urls": ["<url1>", "<url2>"]
  },
  "urls_accessed": {
    "categories_discovery": ["<url>"],
    "listings_discovery": ["<url>"],
    "last_tested_url": "<url>",
    "last_tested_at": "<timestamp>"
  }
}
```

---

## STEP 8: Write navigation-knowledge.md (USE ABSOLUTE PATH)

Path: `{output_dir}/<scraper>/.scraper-state/navigation-knowledge.md`

Include:
- Parsers updated and tested (with selectors, strategy, confidence)
- Vars flow documentation (categories → listings → details, with what vars are passed)
- Pagination details (strategy used, selector, regex, products per page)
- Sample detail URLs for next phase
- Pipeline smoke test outcome (PASSED / FAILED + any fixes made)
- Next command using profile pipeline (NOT hardcoded):
  ```
  /<next_phase_from_profile> scraper=<scraper_slug> project=<project>
  ```

---

## STEP 9: Update Phase Status and Browser Context

`phase-status.json` — set `navigation_discovery.status = "completed"`, add `completed_at` and checkpoints.

`browser-context.json` — update with last URL, `"last_phase": "navigation_discovery"`.

---

## STEP 10: Write Session Audit

Save `session-audit-html_navigation.json` (same structure as scrape audit, `"phase": "html_navigation"`).

---

## STEP 11: Completion Report

Display completion summary. The "Next Command" line MUST use the next phase from the project pipeline profile (NOT `/dmart-details-parser`).

---

## STEP 12: Auto-Chaining (if auto_next=true)

Follow `docs/shared/agent-rules-gemini.md` auto-chain rules.

**Determine next command**:
- This is phase at index 1 in the pipeline
- Next phase = `pipeline.phases[2].phase`
- Spawn: `/<next_phase> scraper=<scraper_slug> project=<project> auto_next=true`

---

## Completion Checklist

- ✅ Navigation parser files edited and tested (categories, subcategories if applicable, listings)
- ✅ `config.yaml` verified
- ✅ `navigation-selectors.json` written
- ✅ `navigation-knowledge.md` written
- ✅ Pipeline smoke test passed
- ✅ `phase-status.json` updated
- ✅ Sample detail URLs extracted and saved
- ✅ Completion report shown with correct next command from profile
- ✅ IF auto_next=true: browser closed, next command EXECUTED
