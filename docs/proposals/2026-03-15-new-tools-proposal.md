# Proposal: New and Improved MCP Tools

**Created:** 2026-03-15
**Status:** Draft
**Scope:** `D:\DataHen\projects\playwright-mcp-mod\src\tools\mod\`, TOML instruction updates

---

## 1. Background

The AI agent relies on a fixed set of MCP tools. Several current workflows require 2–4 sequential tool calls to accomplish what a single purpose-built tool could do. The audit also found two existing capabilities (`batch` parameter on both `browser_inspect_element` and `browser_verify_selector`, and the `attribute` parameter on `browser_verify_selector`) that are already implemented but never documented in the TOMLs — meaning the agent never uses them.

---

## 2. Zero-Effort Wins — Undocumented Existing Features

These are already in the codebase (`inspector.ts`). The only fix needed is updating the TOML instructions.

### Z1 — `browser_verify_selector` already supports attribute verification

The TOML currently says:
> "Use `browser_verify_selector()` for text fields only; use `browser_evaluate()` for images, URLs, data attributes"

**But `browser_verify_selector` already has an `attribute` parameter:**
```json
{ "selector": "img.product-image", "expected": "https://", "attribute": "src" }
```

This means the agent can verify `img src`, `href`, `data-*` values directly — no raw JavaScript needed. The split between text → `browser_verify_selector` and attributes → `browser_evaluate` is a documentation problem, not a tool gap.

**Fix:** Update `system.md` and the relevant TOMLs to document the `attribute` parameter. Remove the "text-only" limitation note.

### Z2 — Both inspector tools already support `batch` mode

`browser_inspect_element` and `browser_verify_selector` both accept a `batch` array parameter, letting the agent inspect or verify multiple elements in a single call. The TOMLs never mention this, so the agent always calls them one at a time.

**Example of what's already possible:**
```json
{
  "element": "product name",
  "ref": "e42",
  "batch": [
    { "element": "price", "ref": "e67" },
    { "element": "brand", "ref": "e91" },
    { "element": "sku", "ref": "e103" }
  ]
}
```

**Fix:** Update Phase 2 and Phase 3 TOML field discovery steps to use batch mode. Instead of one `browser_inspect_element` call per field, inspect the full set of a page area in one call.

---

## 3. New Tool Proposals

### Tool 1 — `browser_extract_json_ld` (HIGH PRIORITY)

**Problem it solves:**
Currently detecting JSON-LD requires a 3-step sequence:
1. `browser_grep_html(query: "@type")` — check if it exists, get raw HTML snippet
2. Agent manually reads snippet to find `<script>` tag boundaries
3. Agent writes Ruby code that re-parses JSON-LD at runtime

A dedicated tool collapses this to one call and returns the parsed object directly to the agent — no Ruby parsing code needed at discovery time, and the agent can immediately map fields from the result.

**Proposed signature:**
```typescript
browser_extract_json_ld({
  type?: string   // Filter by @type value, e.g. "Product". Default: return all.
})
```

**Returns:**
```json
{
  "found": true,
  "type": "Product",
  "data": {
    "name": "Samsung Galaxy S24",
    "offers": { "price": "89999", "priceCurrency": "KES" },
    "brand": { "name": "Samsung" },
    "image": ["https://..."],
    "description": "...",
    "sku": "SM-S921B",
    "gtin13": "8806095..."
  },
  "fields_available": ["name", "offers.price", "brand.name", "image", "description", "sku", "gtin13"],
  "script_tag_selector": "script[type='application/ld+json']:nth-of-type(2)"
}
```

**Impact:** Replaces 3 tool calls with 1. Immediately tells the agent which of the 53 fields are available in JSON-LD, so it can skip CSS discovery for those fields entirely. Directly enables the T3 field batching improvement from the previous proposal.

**Implementation:** Read all `<script type="application/ld+json">` tags from page HTML, parse each with `JSON.parse`, handle `@graph` arrays, filter by `type` if provided, return flattened field list.

---

### Tool 2 — `browser_count_selector` (HIGH PRIORITY)

**Problem it solves:**
The agent frequently needs to know "how many elements does this selector match?" — for pagination count extraction, for multi-page selector validation (does this selector work on 3 different pages?), and for confirming a gallery selector finds the right number of images. Currently requires `browser_evaluate(() => document.querySelectorAll(selector).length)` with raw JavaScript.

**Proposed signature:**
```typescript
browser_count_selector({
  selector: string,           // CSS selector to count
  expected_min?: number,      // Optional: warn if count < this
  expected_max?: number       // Optional: warn if count > this
})
```

**Returns:**
```json
{
  "selector": ".product-item a",
  "count": 24,
  "valid": true,
  "warning": null
}
```

**Impact:**
- Replaces `browser_evaluate` for count checks — no JS needed
- Enables the A6 multi-page selector validation (call once per page, verify count ≥ 1 across all)
- Enables pagination sanity check (count > 500 → log warning)
- Cheap operation — no content extraction, just DOM query

**Implementation:** `document.querySelectorAll(selector).length` via page evaluate, wrapped in structured output with optional validation.

---

### Tool 3 — `parser_tester` multi-file support (HIGH PRIORITY)

**Problem it solves:**
Phase 3 calls `parser_tester` 3 times sequentially against 3 different product files. This is 3 separate tool invocations, 3 Ruby process launches, 3 sets of output to read. A `test_files` array parameter would run all 3 in one call and return a combined report.

**Proposed addition to existing `parser_tester` schema:**
```typescript
test_files?: Array<{
  content_file: string,   // absolute path to JSON/HTML file
  vars?: string,          // JSON vars for this file
  label?: string          // human label e.g. "product with discount"
}>
```

**Returns:** Combined report with per-file results + a cross-file summary:
```
✅ detail-product1.json — all 53 fields extracted
⚠️  detail-product2.json — missing: description, img_url_2
✅ detail-product3.json — all 53 fields extracted

Cross-file issues: description nil on 1/3 products, img_url_2 nil on 1/3
```

**Impact:** Reduces 3 `parser_tester` calls to 1. Adds cross-file comparison that currently requires the agent to manually compare 3 separate outputs.

---

### Tool 4 — `browser_detect_pagination` (MEDIUM PRIORITY)

**Problem it solves:**
Phase 2 navigation discovery requires the agent to manually probe 4–5 pagination strategies to find which one the site uses. This involves multiple `browser_grep_html` calls, conditional logic, and fallback chains — all in natural language instructions that the agent may not follow precisely.

**Proposed signature:**
```typescript
browser_detect_pagination({
  current_url: string    // Current listing page URL (used to test URL patterns)
})
```

**Returns:**
```json
{
  "strategy": "count_based",
  "confidence": 0.92,
  "details": {
    "count_selector": "span.results-count",
    "count_text": "Showing 1-24 of 347 products",
    "total_count": 347,
    "products_per_page": 24,
    "total_pages": 15,
    "url_pattern": "?page={n}",
    "next_button_selector": null
  },
  "alternatives_checked": [
    { "strategy": "next_button", "found": false },
    { "strategy": "query_param", "pattern": "?page=2", "would_work": true }
  ]
}
```

**What it checks internally (without the agent having to orchestrate):**
1. Common count element selectors — 12 patterns
2. Next button selectors — 8 patterns
3. URL structure analysis (does current URL have `?page=` or `/page/`?)
4. Returns best match with confidence score

**Impact:** Replaces the entire Strategy 1–5 discovery sequence with one call. Directly implements the A1 pagination fallback chain from the previous proposal as a tool rather than a TOML instruction.

---

### Tool 5 — `browser_network_replay` (MEDIUM PRIORITY)

**Problem it solves:**
For API scraping, the agent always does `browser_network_search` followed by `browser_network_download` — two calls that are always paired. `browser_network_replay` combines them: find a matching request in the network log and re-issue it using the browser's session context, saving the response.

**Proposed signature:**
```typescript
browser_network_replay({
  url_pattern: string,         // URL substring or regex to match in network log
  output_path: string,         // Absolute path to save response body
  method?: string,             // Filter by HTTP method (default: any)
  use_captured_headers?: boolean  // Re-use headers from captured request (default: true)
})
```

**Returns:**
```json
{
  "matched_url": "https://api.example.com/v2/products?page=1&category=123",
  "status": 200,
  "content_type": "application/json",
  "saved_to": "D:/path/to/cache/listings-api.json",
  "response_size_bytes": 48291
}
```

**Impact:** Replaces the `browser_network_search` → `browser_network_download` pair with one call. Reduces API Phase 1 from ~6 tool calls (search + download × 3 endpoints) to ~3.

---

### Tool 6 — `browser_extract_images` (MEDIUM PRIORITY)

**Problem it solves:**
Image extraction is one of the hardest fields because modern e-commerce sites use many lazy-loading patterns: `src`, `data-src`, `srcset`, `data-lazy`, `data-original`, CSS `background-image`. The agent currently writes one `browser_evaluate` call per pattern variant and often misses some.

**Proposed signature:**
```typescript
browser_extract_images({
  container_selector: string,    // CSS selector for image gallery container
  limit?: number                 // Max images to return (default: 10)
})
```

**Returns:**
```json
{
  "images": [
    { "url": "https://cdn.example.com/product-1-large.jpg", "source_attr": "src", "index": 0 },
    { "url": "https://cdn.example.com/product-2-large.jpg", "source_attr": "data-src", "index": 1 },
    { "url": "https://cdn.example.com/product-3-large.jpg", "source_attr": "srcset", "index": 2 }
  ],
  "count": 3,
  "primary_url": "https://cdn.example.com/product-1-large.jpg",
  "lazy_load_pattern": "data-src"
}
```

**What it checks internally:** `src`, `data-src`, `srcset` (largest), `data-lazy`, `data-original`, `data-zoom-image`, `background-image` — in priority order, deduplicating results.

**Impact:** Replaces 4–6 `browser_evaluate` calls with one. Returns all gallery images reliably including lazy-loaded ones. The agent just takes `primary_url` for `img_url` and the rest for `additional_images`.

---

### Tool 7 — `scraper_output_validator` (LOW PRIORITY)

**Problem it solves:**
After each `parser_tester` run, the agent has to manually inspect 53 output fields to check all are present and match `config.yaml` exporter field names. This is error-prone and relies on the agent's attention.

**Proposed signature:**
```typescript
scraper_output_validator({
  scraper_dir: string,     // Absolute path — reads config.yaml from here
  outputs_json: string     // JSON string of the outputs array from parser_tester
})
```

**Returns:**
```json
{
  "valid": false,
  "total_fields_expected": 53,
  "fields_present": 51,
  "missing_fields": ["allergens", "nutrition_facts"],
  "wrong_type_fields": [{ "field": "customer_price_lc", "expected": "string", "got": "float" }],
  "nil_required_fields": ["img_url"],
  "summary": "2 fields missing from output hash, 1 type mismatch, 1 nil required field"
}
```

**Impact:** Automates the post-test field coverage check. Catches missing fields without the agent having to visually scan 53 fields.

---

## 4. Summary

### Zero-effort (TOML instruction changes only)

| # | Fix | Impact |
|---|---|---|
| Z1 | Document `attribute` param on `browser_verify_selector` | Eliminates `browser_evaluate` for all attribute fields |
| Z2 | Document `batch` param on both inspector tools | ~4× fewer inspector tool calls per session |

### New tools

| # | Tool | Replaces | Tool calls saved |
|---|---|---|---|
| 1 | `browser_extract_json_ld` | grep → manual parse → runtime parse | 3 calls → 1 |
| 2 | `browser_count_selector` | `browser_evaluate` count JS | 1 call each, cleaner |
| 3 | `parser_tester` multi-file | 3× sequential parser_tester | 3 calls → 1 |
| 4 | `browser_detect_pagination` | Full Strategy 1–5 probe sequence | ~8 calls → 1 |
| 5 | `browser_network_replay` | `network_search` + `network_download` | 2 calls → 1 per endpoint |
| 6 | `browser_extract_images` | 4–6 `browser_evaluate` variants | 5 calls → 1 |
| 7 | `scraper_output_validator` | Manual agent inspection | 0 calls, automated accuracy |

### Recommended build order

1. **Z1 + Z2** — TOML fixes only, zero dev time, immediate gain
2. **Tool 3** (`parser_tester` multi-file) — modify existing tool, low risk, high frequency gain
3. **Tool 1** (`browser_extract_json_ld`) — new tool in `html.ts`, medium effort, eliminates biggest multi-step sequence
4. **Tool 2** (`browser_count_selector`) — small new tool, enables multi-page validation
5. **Tool 5** (`browser_network_replay`) — new tool, helps API workflow
6. **Tool 6** (`browser_extract_images`) — new tool, eliminates lazy-load guessing
7. **Tool 4** (`browser_detect_pagination`) — most complex, high value for accuracy
8. **Tool 7** (`scraper_output_validator`) — validation automation, nice to have
