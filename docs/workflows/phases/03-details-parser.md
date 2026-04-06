# Phase 3: Details Parser

**Used by:** dmart-dloc (and any project whose final details parser is for product-style pages)
**Reads:** `navigation-selectors.json`, `navigation-knowledge.md`, `discovery-state.json`, `field-spec.json`
**Writes:** `detail-selectors.json`, `detail-knowledge.md`
**Edits:** `parsers/details.rb`
**Next phase:** determined by profile — if this is the last phase, no chaining

---

## Inputs (from args)

- `scraper=<scraper_name>` — REQUIRED — scraper must exist with `navigation-selectors.json`
- `project=<profile_name>` — OPTIONAL, default: `dmart-dloc`
- `url=<details_page_url>` — OPTIONAL — uses sample URL from navigation-selectors.json if not provided
- `spec=<path>` — OPTIONAL — field specification override
- `collection=<collection_name>` — OPTIONAL, default: `"products"`
- `resume-url=<url>` — OPTIONAL
- `out=<base_dir>` — OPTIONAL, defaults to `./generated_scraper`
- `auto_next=true|false` — OPTIONAL, default: false

---

## BEFORE YOU START

Remember — USE TOOLS DIRECTLY, DO NOT WRITE CODE.

---

## STEP 1: Load State Files and Profile

**Load profile** (`profiles/<project>.toml`).

**Load state files** (one by one, handle missing gracefully):
1. `generated_scraper/<scraper>/.scraper-state/phase-status.json`
2. `generated_scraper/<scraper>/.scraper-state/navigation-selectors.json`
3. `generated_scraper/<scraper>/.scraper-state/navigation-knowledge.md`
4. `generated_scraper/<scraper>/.scraper-state/discovery-knowledge.md`
5. `generated_scraper/<scraper>/.scraper-state/discovery-state.json`
6. `generated_scraper/<scraper>/.scraper-state/field-spec.json`
   - NOTE: Fields with a `format_spec` key have mandatory output format rules — follow them exactly.
7. `generated_scraper/<scraper>/.scraper-state/detail-selectors.json` (if resuming)
8. `generated_scraper/<scraper>/.scraper-state/detail-knowledge.md` (if resuming)

**Load parser file**:
- Read `generated_scraper/<scraper>/parsers/details.rb` (must exist from boilerplate)
- Read `generated_scraper/<scraper>/config.yaml`

Parse:
- `navigation-selectors.json`: `listings.sample_detail_urls` for test URL, expected vars
- `discovery-state.json`: `popup_handling` strategy for reuse
- `field-spec.json`: all FIND fields requiring selector discovery

**Validate prerequisites**:
- `navigation-selectors.json` must exist → "Run `/navigation-parser scraper=<scraper> project=<project>` first"
- `details.rb` must exist from boilerplate → "Run `/scrape` first"

---

## STEP 2: Determine Detail URL

Priority order:
1. `resume-url` parameter (if provided)
2. `url` parameter (if provided)
3. `navigation-selectors.json['listings']['sample_detail_urls'][0]`
4. `discovery-state.json['sample_urls']['detail']`
5. Ask user if none available

---

## STEP 3: Test Existing Parser

Before editing, test existing parser:

```javascript
parser_tester({
  scraper_dir: "<absolute_path>/generated_scraper/<scraper>",
  parser_path: "parsers/details.rb",
  page_type: "details",
  auto_download: true,
  vars: '{"category_name":"Electronics","breadcrumb":"Electronics","rank":1,"page_number":1}',
  quiet: false
})
```

If parser passes → enhance with missing fields from field-spec.json
If parser fails → discover and replace PLACEHOLDER selectors

---

## STEP 4: Navigate to Detail Page

```javascript
browser_navigate(<detail_url>)
```

Handle popups — use `popup_handling` strategy from discovery-state.json.

`browser_snapshot()`

---

## STEP 5: JSON-LD Pre-Check (run FIRST, before any CSS discovery)

```javascript
browser_extract_json_ld({ type: "Product" })
```

If found:
- Mark JSON-LD fields as "discovered via JSON-LD" in field-spec.json
- Write Ruby extraction code using JSON-LD pattern (see `docs/shared/datahen-conventions.md`)
- For fields NOT in JSON-LD → proceed to CSS discovery

If not found → proceed to CSS discovery for all fields.

**Meta tag fallbacks** (always add, even with JSON-LD):
```ruby
og_image = html.at_css('meta[property="og:image"]')&.[]('content')
og_title = html.at_css('meta[property="og:title"]')&.[]('content')&.strip
img_url  ||= og_image
name     ||= og_title
```

---

## STEP 6: Systematic Field Discovery

Iterate through ALL FIND fields in field-spec.json (by priority order). For each:

1. Skip if `extraction_method != "FIND"` or `discovered == true`
2. Discover selector — follow `docs/shared/selector-discovery.md` protocol:
   - `browser_grep_html(query: "<visible value>")` → identify selector from snippet
   - `browser_inspect_element(ref)` → confirm exact selector
   - `browser_verify_selector()` → text fields; attribute param for img/href
3. Update `field-spec.json` immediately: `selectors`, `discovered: true`, `verified`, `confidence`, `extraction_notes`
4. Track progress: `discovery_status.discovered_fields`, `pending_fields`

After all FIND fields iterated — report: "Discovered X/Y FIND fields (Priority 1: A/B, Priority 2: C/D...)"

---

## STEP 7: Update field-spec.json

Update `discovery_status` section with final counts:
- `total_fields`, `find_fields`, `discovered_fields`, `verified_fields`, `pending_fields`
- `process_fields`, `determine_fields`, `infer_fields`, `hardcoded_fields`

Validate all counts sum to `total_fields`.

Save (USE ABSOLUTE PATH).

---

## STEP 8: Edit parsers/details.rb (USE ABSOLUTE PATH)

**CRITICAL**: Edit existing file — DO NOT create from scratch.

Follow `docs/shared/datahen-conventions.md` for:
- Parser structure (top-level script, no def parse)
- Field extraction priority order (JSON-LD → meta tags → CSS selectors)
- Struct fields special JSON-string format
- Required validation block before `outputs <<`
- All 53 fields in output hash (nil for unavailable fields)

Steps:
a) Read existing parser code (already loaded)
b) Map discovered fields from field-spec.json
c) Replace all PLACEHOLDER strings
d) Add JSON-LD extraction if found in Step 5
e) Add meta tag fallbacks for img_url and name
f) Add validation block
g) Ensure all 53 output fields present (nil for unavailable)
h) Write updated file (USE ABSOLUTE PATH)

---

## STEP 9: Test Parser

```javascript
parser_tester({
  scraper_dir: "<absolute_path>/generated_scraper/<scraper>",
  parser_path: "parsers/details.rb",
  page_type: "details",
  auto_download: true,
  vars: '{"category_name":"Electronics","breadcrumb":"Electronics","rank":1,"page_number":1}',
  quiet: false
})
```

Test on 3 different detail URLs. Fix and re-test if any fail.

---

## STEP 10: Write detail-selectors.json and detail-knowledge.md

`detail-selectors.json` (USE ABSOLUTE PATH):
```json
{
  "fields_discovered": { "name": ".product-title", "price": ".price-tag", ... },
  "json_ld_found": true,
  "json_ld_fields": ["name", "price", "brand", "description", "img_url"],
  "verified": true,
  "urls_accessed": { "discovery_urls": ["<url>"], "test_urls": ["<url1>", "<url2>", "<url3>"] }
}
```

`detail-knowledge.md` (USE ABSOLUTE PATH): includes fields discovered, extraction methods, confidence scores, popup handling notes.

---

## STEP 11: Update Phase Status

`phase-status.json` — set `detail_discovery.status = "completed"`.

`browser-context.json` — update with last URL, `"last_phase": "detail_discovery"`.

---

## STEP 12: Write Session Audit

Save `session-audit-html_details.json` (same structure as other audits, `"phase": "html_details"`).

---

## STEP 13: Completion Report

Display summary. Check if this is the LAST phase in the profile pipeline.

For dmart-dloc: this IS the last phase → no next command, display final completion message:
```
🎉 Scraper Generation Complete!

Scraper: <scraper_slug>
Project: <project>

All phases completed. The scraper is ready for testing.

To test the full pipeline:
  datahen_run reset → seed → step categories → step listings → step details
```

---

## STEP 14: Auto-Chaining (if auto_next=true)

Follow `docs/shared/agent-rules-gemini.md` auto-chain rules.

**IMPORTANT**: First check if this is the LAST phase in the profile pipeline.
- Load `profiles/<project>.toml`
- Find current phase index (look for `phase = "details-parser"` in pipeline array)
- If this is the last entry: DO NOT chain — display completion summary only
- If not last: chain to `pipeline.phases[current_index + 1].phase`

For dmart-dloc with default pipeline: `details-parser` is index 2 (last) → no chaining.

---

## Completion Checklist

- ✅ All FIND fields from field-spec.json discovered and verified
- ✅ `details.rb` parser edited with all field selectors
- ✅ JSON-LD extraction added where available
- ✅ Meta tag fallbacks added for img_url and name
- ✅ All 53 output fields present (nil for unavailable)
- ✅ Parser tested on 3 sample detail pages
- ✅ `field-spec.json` updated with discovery results
- ✅ `detail-selectors.json` written
- ✅ `detail-knowledge.md` written
- ✅ `phase-status.json` updated
- ✅ Completion report shown
- ✅ IF auto_next=true AND not last phase: next command EXECUTED
- ✅ IF last phase: final completion message shown
