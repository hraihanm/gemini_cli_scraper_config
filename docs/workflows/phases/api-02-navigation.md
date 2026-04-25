# API Phase 2: Navigation / listings API parsers

**version:** 1.0.0

**Profile:** `[[api_pipeline.phases]]` — workflow for API navigation parser phase.

## Goal

Implement or fix parsers that consume **API JSON** for categories/listings (no HTML CSS for primary data). Ensure pagination via API params is detected and vars flow to detail API pages.

## Rules

- Top-level Ruby scripts only (`docs/shared/datahen-conventions.md`).
- **`parser_tester`** with saved JSON bodies or `auto_download` where applicable.
- Write `navigation-selectors.json` (or API-specific state file name your profile expects) including **`_notes`**, `pagination_warning` if only first page is reachable, and **URL deduplication** for queued detail URLs.

## Steps (summary)

1. Load discovery/API state + `field-spec.json` + existing parsers.
2. For each navigation parser file (except final detail parser): discover JSON paths or small CSS wrappers if responses are HTML-wrapped; test with `parser_tester`.
3. Pagination fallback chain for APIs: offset/limit → page param → cursor → next URL from response body. Never silently single-page.
4. **Listings-only assessment** (Step 4a) — after testing, evaluate whether the listings API already provides all required fields. See section below.
5. Smoke-test `datahen_run` steps if available.
6. Persist selector/path JSON + `_notes`; update `phase-status.json`; session audit with real tool counts.
7. Auto-chain to API details phase when `auto_next=true` — **skip chain if `details_parser_needed: false`** (no-op phase).

---

## Step 4a: Listings-Only Assessment

After `parser_tester` succeeds on ≥ 3 samples, inspect the output hash for field coverage.

**Trigger condition:** The listings API returns a "maximal" or "full" payload — e.g. `fieldset=maximal`, `include=all`, or similar enrichment parameter — and the output already contains:
- `name`, `sku`, `barcode`, `brand`
- `customer_price_lc`, `currency_code_lc`
- `img_url`
- `description` or `ingredients` / `nutrition_facts` (for DLOC)

**If coverage is sufficient → Listings-Only Mode:**

1. Set `details_parser_needed: false` in `navigation-selectors.json` (or API state file).
2. The listings parser becomes the **final output emitter** — it MUST follow the same 53-field output hash rule as a details parser (`docs/shared/output-hash-rules.md`). All fields not available from the listings API MUST be set to `nil` explicitly. Field order MUST match the canonical template.
3. Disable the details parser in `config.yaml`:
   ```yaml
   - page_type: details
     file: ./parsers/details.rb
     disabled: true
   ```
4. Document the decision in `_notes`: which API parameter unlocked full data, which fields are nil, and why details phase is skipped.
5. **Do not queue detail URLs** — listings outputs go directly to the DataHen output collection.

**If coverage is insufficient** (details page has required fields the listings API omits):
- Set `details_parser_needed: true` (default)
- Proceed with normal detail URL queuing

**Output hash completeness rule for listings-only mode:**

The listings parser output hash MUST include all 53 fields in canonical order. Example for fields unavailable from the listings API:

```ruby
outputs << {
  # --- fields extracted from listings API ---
  name:                  name,
  sku:                   sku,
  customer_price_lc:     customer_price_lc,
  # ...

  # --- fields not available from listings API (nil, not omitted) ---
  store_reviews:         nil,
  seller_rating:         nil,
  delivery_time:         nil,
  # ...
}
```

All 53 fields must be present. Never omit a field — a missing key is treated as an error.
