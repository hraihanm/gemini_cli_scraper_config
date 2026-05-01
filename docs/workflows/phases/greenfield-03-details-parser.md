# Greenfield Phase 3: Details Parser

**version:** 1.0.0

**Used by:** `profiles/greenfield.toml`
**Reads:** `navigation-selectors.json`, `discovery-state.json`, `field-spec.json`
**Writes:** `detail-selectors.json`
**Edits:** `parsers/details.rb`
**Next phase:** none (last HTML phase for this profile)

---

## Inputs (from args)

- `scraper=<scraper_name>` — REQUIRED — scraper must exist with `navigation-selectors.json`
- `project=<profile_name>` — OPTIONAL, default: **`greenfield`**
- `url=<details_page_url>` — OPTIONAL — uses sample URL from navigation-selectors.json if not provided
- `spec=<path>` — OPTIONAL — field specification override
- `collection=<collection_name>` — OPTIONAL, default: `"products"`
- `resume-url=<url>` — OPTIONAL
- `out=<base_dir>` — OPTIONAL, defaults to `./generated_scraper`
- `auto_next=true|false` — OPTIONAL, default: false

---

## BEFORE YOU START

Remember — USE TOOLS DIRECTLY, DO NOT WRITE CODE.

## Greenfield — output contract

- **`parsers/details.rb`** MUST emit an output hash whose **keys match `field-spec.json`** (prompt-defined or CSV-derived). Use Ruby **`nil`** for missing values — not `""`.
- Extraction order: **JSON-LD** (if present) → **meta / Open Graph** → **CSS selectors** (`docs/shared/agent-rules-gemini.md`).
- After parser tests pass, **sync `config.yaml` exporters** (CSV headers/paths) with the final hash keys — greenfield boilerplate is a starting point only.

---

## STEP 1: Load State Files and Profile

**Load profile** (`profiles/<project>.toml`).

**Load state files** (one by one, handle missing gracefully):
1. `generated_scraper/<scraper>/.scraper-state/phase-status.json`
2. `generated_scraper/<scraper>/.scraper-state/navigation-selectors.json` (read `_notes` when present)
3. (Legacy) `navigation-knowledge.md` — only if `_notes` missing in navigation-selectors
4. `generated_scraper/<scraper>/.scraper-state/discovery-state.json` (includes `_notes` / popup strategy)
5. (Legacy) `discovery-knowledge.md` — only if needed for one-time merge into context
6. `generated_scraper/<scraper>/.scraper-state/field-spec.json`
   - NOTE: Fields with a `format_spec` key have mandatory output format rules — follow them exactly.
7. `generated_scraper/<scraper>/.scraper-state/detail-selectors.json` (if resuming)
8. (Legacy) `detail-knowledge.md` (if resuming) — merge into `detail-selectors.json._notes` when rewriting

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

**Validate Phase 2 output contract** — before proceeding, verify `navigation-selectors.json` contains:
- `listings.product_link_selector` — non-null, non-empty
- `listings.sample_detail_urls` — array with ≥ 1 URL
- `listings.pagination_strategy` — non-null

If any Required field is missing: **STOP** — display: `"Phase 2 output is incomplete. Re-run: /navigation-parser scraper=<scraper> project=<project>"`

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

## STEP 6: Systematic Field Discovery (batched by page region)

**Do not** run one isolated `browser_grep_html` per field when fields group naturally on the page.

1. Build groups from `field-spec.json` FIND fields (skip `discovered == true` or non-FIND):
   - **Identity** — name, brand, sku, breadcrumbs
   - **Pricing** — price, list_price, discount, currency, VAT
   - **Imagery** — images, gallery
   - **Availability** — stock, qty, delivery
   - **Spec / long text** — description, bullets, attributes tables
2. For **each group**, choose 1–3 high-signal `browser_grep_html` queries that pull **snippets covering multiple nearby fields** (e.g. one grep for a price block substring, one for title area).
3. From each snippet batch: `browser_inspect_element` / `browser_verify_selector` (or attribute mode) for **all** fields in that group before moving to the next group.
4. Update `field-spec.json` after each group: selectors, `discovered`, `verified`, `confidence`, `extraction_notes`.
5. Track `discovery_status` counts.

After all groups — report: `Discovered X/Y FIND fields` with per-priority breakdown.

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
f) **Locale-aware price parsing:** from the primary raw price string sample(s), detect **decimal vs thousands** separators (e.g. `1.299,00` EUR vs `1,299.00` US). Store the decision in `detail-selectors.json` under `price_locale` (`{ "decimal_sep": ",", "thousands_sep": "." }` or swapped). Implement `number_from` / string cleanup in `details.rb` so European formats do not parse as wrong floats.
g) **Category context fallback:** if breadcrumb/CSS `category` extraction is nil, use `vars['category_name']` (and related vars) passed from listings before falling back to empty string.
h) Add validation block
i) Ensure all 53 output fields present (nil for unavailable)
j) Write updated file (USE ABSOLUTE PATH)

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

## STEP 9b: Nil-guard check after `parser_tester`

After each successful `parser_tester` run on a detail page, inspect emitted outputs for **required** commercial fields (at minimum **`name`** and **primary price / `customer_price_lc`** per field-spec):

- If any required field is **nil** or empty string while HTML was present: **do not** treat the run as passing — log in `_notes`, adjust selectors or parsing, and re-test.
- If intentionally absent on this SKU type, document the exception in `field-spec.json` `extraction_notes` and `_notes`.

---

## STEP 9c: Eval Gate (mandatory before marking phase complete)

Run the eval suite. **This step is not optional** — do not mark the phase "completed" without it.

```javascript
scraper_run_evals({
  scraper_dir: "<absolute_path>/generated_scraper/<scraper>"
})
```

**Case A — Fixtures exist** (`evals/` has ≥ 1 subdirectory with `input.html` + `expected.json`):
- Score ≥ 80% → proceed to STEP 10
- Score < 80% → fix each failing field (`parser_tester` → edit → re-test), then re-run `scraper_run_evals`; repeat until ≥ 80%
- **Never mark phase "completed" with a failing eval score**

**Case B — No fixtures yet** (first run for this scraper):
1. The most recent `parser_tester` run downloaded an HTML file — locate it in `cache/` or re-download via `auto_download: true`
2. Create a fixture pair (USE ABSOLUTE PATHS):
   - `generated_scraper/<scraper>/evals/<scraper_slug>_sample/input.html` — the downloaded HTML
   - `generated_scraper/<scraper>/evals/<scraper_slug>_sample/expected.json` — the output hash from that `parser_tester` run (include all 53 fields; use `null` for genuinely absent fields)
3. Re-run `scraper_run_evals` to confirm the new fixture passes (score = 100%)

Record in `phase-status.json`:
```json
"detail_discovery": {
  "status": "completed",
  "completed_at": "<timestamp>",
  "eval_score": 100,
  "eval_fixtures": 1,
  "validated_output": true
}
```

---

## STEP 10: Write detail-selectors.json (USE ABSOLUTE PATH)

`detail-selectors.json` MUST include top-level **`_notes`** (markdown): fields discovered, JSON-LD usage, **price_locale** summary, category fallback behavior, confidence issues, popup notes, and test URLs.

```json
{
  "fields_discovered": { "name": ".product-title", "price": ".price-tag" },
  "json_ld_found": true,
  "json_ld_fields": ["name", "price", "brand", "description", "img_url"],
  "price_locale": { "decimal_sep": ".", "thousands_sep": "," },
  "verified": true,
  "urls_accessed": { "discovery_urls": ["<url>"], "test_urls": ["<url1>", "<url2>", "<url3>"] },
  "_notes": "## Details phase\\n\\n- Discovery summary, nil-guard outcomes, next steps\\n"
}
```

---

## STEP 11: Update Phase Status

`phase-status.json` — use the schema written in STEP 9c (includes `eval_score`, `eval_fixtures`, `validated_output: true`).

`browser-context.json` — update with last URL, `"last_phase": "detail_discovery"`.

---

## STEP 12: Write Session Audit

Save `session-audit-html_details.json` (same structure as other audits, `"phase": "html_details"`). **Tally real `tool_call_counts`** (same rules as Phase 1). Use `tool_call_counts_incomplete` if needed.

---

## STEP 13: Completion Report

Display summary. Check if this is the LAST phase in the profile pipeline.

For greenfield (`profiles/greenfield.toml`): this IS the last phase → no next command, display final completion message:
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

For greenfield with default pipeline: `details-parser` is index 2 (last) → no chaining.

---

## Completion Checklist

- ✅ All FIND fields from field-spec.json discovered and verified
- ✅ `details.rb` parser edited with all field selectors
- ✅ JSON-LD extraction added where available
- ✅ Meta tag fallbacks added for img_url and name
- ✅ All 53 output fields present (nil for unavailable)
- ✅ Parser tested on 3 sample detail pages
- ✅ Phase 2 output contract validated (STEP 1) — `listings.sample_detail_urls` confirmed
- ✅ Eval gate passed (STEP 9c) — score ≥ 80% OR first fixture created and passing
- ✅ `field-spec.json` updated with discovery results
- ✅ `detail-selectors.json` written (includes `_notes`, `price_locale` when applicable)
- ✅ `phase-status.json` updated
- ✅ Completion report shown
- ✅ IF auto_next=true AND not last phase: next command EXECUTED
- ✅ IF last phase: final completion message shown
