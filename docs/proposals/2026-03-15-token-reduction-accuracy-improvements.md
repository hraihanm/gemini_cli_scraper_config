# Proposal: Token Reduction and Accuracy Improvements

**Created:** 2026-03-15
**Status:** Draft
**Scope:** `.gemini/commands/*.toml`, `.gemini/system.md`, `templates/dmart_dloc_boilerplate/parsers/listings.rb`

---

## 1. Background

The AI agent workflow generates scrapers through 3-phase Gemini CLI commands. Each command is a large TOML prompt (~40–75KB). As the system has grown, prompts have accumulated duplicate warnings, redundant state files, and per-field browser tool calls. This increases token cost per session and creates inconsistency from copy-paste drift between TOMLs.

Audit findings:
- **~14,000+ characters of repeated warnings** across 8 TOML files — the "CRITICAL: YOU ARE IN GEMINI CLI" block alone is 1,061 chars × 8 files
- **`system.md` already defines** 15+ rules that are restated verbatim in every TOML
- **Each scraper writes 9 state files**, including 4 JSON+MD pairs with 40–50% content overlap
- **6 accuracy gaps** in `listings.rb`: no deduplication, no pagination fallback, nil guards missing
- **Field discovery** runs one `browser_grep_html` call per field — 53 calls for a full spec when batching by page area would need ~8

---

## 2. Current State

| Metric | Value |
|---|---|
| Largest TOML (`dmart-details-parser.toml`) | 1,440 lines, ~75KB |
| Repeated "NEVER GENERATE CODE" warning | 8× across TOMLs (~8,500 chars waste) |
| Rules in system.md re-stated in TOMLs | 15+ rules |
| State files per scraper | 9 files |
| JSON+MD pairs with duplicate content | 4 pairs |
| browser_grep_html calls for 53 fields | ~53 sequential calls |
| listings.rb pagination fallback | None — Strategy 1 fails silently |
| listings.rb deduplication | None |

---

## 3. Problems

### Token waste
1. **Duplicate preamble blocks** — Every TOML opens with the same ~1,061-char "never generate code" warning, already covered by `system.md`. Reading 75KB of prompt context that's 20% repeated rules wastes input tokens on every session.
2. **JSON+MD state file pairs** — Each phase writes both a `.json` (machine-readable) and a `.md` (human-readable) with the same information. The next phase reads both. That's ~2× the write tokens and ~2× the read tokens for no new information.
3. **Per-field browser_grep_html** — With 53 fields, the agent makes ~53 sequential `browser_grep_html` calls. Most product pages have natural groupings (pricing block, identity block, imagery, availability row). Batching by area reduces this to ~8–10 calls with richer context per call.
4. **Verbose parser_tester output** — `quiet: false` by default produces full output every run. Most runs are confirmatory, not debugging.

### Accuracy gaps
5. **No pagination fallback** — If Strategy 1 (count-based) fails to find the product count element, pagination is silently skipped. No fallback to Strategy 2 (next button). The scraper captures only page 1.
6. **No URL deduplication in listings** — Sites that load the same product in multiple categories queue duplicate detail pages. Output has duplicate rows.
7. **Silent nil on required fields** — If `name` or `customer_price_lc` extraction returns nil, the parser succeeds with blank data. No runtime warning is generated.
8. **Price format not detected** — `number_from("1.299,00")` returns `1.299` (wrong). European sites (Czech, German, Spanish) use period as thousands separator. Agent is not instructed to detect and handle this.
9. **Category context lost at detail level** — `category` in output defaults to breadcrumb extraction which is fragile. If it fails, `vars['category_name']` from listings is available but often not used as fallback.
10. **Single-page selector validation** — Phase 2 verifies navigation selectors on one page only. A selector that works on the category page but fails on all others is marked verified.

---

## 4. Proposal

### T1 — Strip duplicate preamble from TOMLs (Token reduction, HIGH ROI)

The "CRITICAL: YOU ARE IN GEMINI CLI / NEVER GENERATE CODE" block appears identically in all 8 TOMLs. `system.md` is the firmware layer — move this rule there once and remove it from all TOMLs. Same for:
- `CRITICAL - ABSOLUTE PATHS REQUIRED`
- `DataHen v3 Parser Structure` (TOP-LEVEL SCRIPTS, never declare pages/outputs)
- `CRITICAL AUTO-CHAINING EXECUTION RULE`

Each TOML can replace these blocks with a single line:
```
(Rules enforced by system.md: no code generation, absolute paths, DataHen parser conventions, auto-chaining.)
```

**Estimated savings:** ~14,000 chars (~3,500 tokens) across the TOML set. Each session that loads a TOML saves ~1,700 input tokens.

---

### T2 — Merge JSON+MD state file pairs into one file (Token reduction, HIGH ROI)

Currently each phase writes two files with overlapping content:
- `discovery-state.json` + `discovery-knowledge.md`
- `navigation-selectors.json` + `navigation-knowledge.md`
- `detail-selectors.json` + `detail-knowledge.md`

**Replace with a single file per phase** using a JSON structure that includes a `_notes` string field for human commentary:

```json
{
  "_notes": "Phase 1 complete. Cloudflare site — browser fetch required. No popups detected.",
  "site_url": "https://example.com",
  "scraping_approach": "html",
  "fetch_requirements": { ... },
  "sample_urls": { ... }
}
```

Each phase appends its section to a **single** `scraper-state.json` (top-level keys: `discovery`, `navigation`, `detail`). The next phase reads one file instead of two.

New state file set per scraper (9 → 5):
| File | Replaces |
|---|---|
| `scraper-state.json` | `discovery-state.json` + `navigation-selectors.json` + `detail-selectors.json` |
| `scraper-knowledge.md` | `discovery-knowledge.md` + `navigation-knowledge.md` + `detail-knowledge.md` (appended) |
| `field-spec.json` | unchanged |
| `phase-status.json` | unchanged |
| `session-audit-<phase>.json` | unchanged (one per phase) |

**Estimated savings:** 4 fewer `write_file` calls per scraper, 4 fewer `read_file` calls per phase transition, ~8–12KB less total context loaded per session.

---

### T3 — Batch field discovery by page area (Token reduction, MEDIUM ROI)

Current approach: one `browser_grep_html` call per field × 53 fields = ~53 tool calls, each returning up to 200-char context snippets independently.

**New approach:** group fields by natural page area and run one grep per area:

| Group | Fields covered | One grep query |
|---|---|---|
| Price block | `customer_price_lc`, `base_price_lc`, `has_discount`, `discount_percentage` | `browser_grep_html(query: "price\|sale\|discount", isRegex: true, contextChars: 400)` |
| Identity | `name`, `sku`, `barcode`, `competitor_product_id` | `browser_grep_html(query: "<actual product name from snapshot>")` |
| Availability | `is_available` | `browser_grep_html(query: "stock\|available\|añadir", isRegex: true)` |
| Brand/category | `brand`, `category`, `sub_category` | `browser_grep_html(query: "<brand name from snapshot>")` |
| Imagery | `img_url`, additional images | `browser_evaluate(js: "document.querySelectorAll('img[src]').length")` then inspect gallery |
| Description | `description` | `browser_grep_html(query: "<first 20 chars of visible description>")` |
| Promo/badges | `type_of_promotion`, `promo_attributes` | `browser_grep_html(query: "badge\|promo\|offer\|sale", isRegex: true)` |
| Extended | `allergens`, `nutrition_facts`, `ingredients`, `dimensions` | One grep per group only if field is Priority ≤ 3 |

Add explicit instruction to `dmart-details-parser.toml` step 9: "Do NOT run one grep per field. Grep by area, read multiple selectors from the context snippet."

**Estimated savings:** ~45 fewer tool calls per Phase 3 session. Each `browser_grep_html` call = network round-trip + context tokens. Rough reduction: 53 → 10 calls.

---

### T4 — `parser_tester` quiet by default (Token reduction, LOW ROI)

Change all routine `parser_tester` calls in TOMLs to `quiet: true`. Only use `quiet: false` when the previous test failed (i.e. inside the "fix iteration" loop). Full output at `quiet: false` dumps all field values — useful for debugging, wasteful for confirmatory runs.

**Estimated savings:** ~500–800 tokens per confirmatory test run.

---

### A1 — Pagination fallback chain in listings TOML (Accuracy, HIGH IMPACT)

In `dmart-navigation-parser.toml` Step 5 (listings parser), add explicit fallback logic:

```
Pagination strategy selection (ordered):
1. Try Strategy 1 (count-based): run browser_grep_html(query: "results|showing|total", isRegex: true)
   - If product count found AND parseable → use Strategy 1, queue all pages upfront
   - If NOT found → proceed to step 2
2. Try Strategy 2 (next button): run browser_grep_html(query: "Next|Siguiente|Próxima", isRegex: true)
   - If next button found → use Strategy 2, uncomment next-button block in listings.rb
   - If NOT found → proceed to step 3
3. Try Strategy 4 (query param): test ?page=2 URL in browser — if it returns different products → use Strategy 4
4. Try Strategy 5 (path pattern): test /page/2 URL in browser
5. If all fail → document as single-page listing, log warning in scraper-knowledge.md
```

Currently the TOML presents all strategies as options without ordering or fallback triggers. The agent often picks Strategy 1, fails silently when count extraction breaks, and leaves listings.rb with a broken placeholder.

---

### A2 — URL deduplication in HTML listings boilerplate (Accuracy, MEDIUM IMPACT)

Add to `templates/dmart_dloc_boilerplate/parsers/listings.rb` after the products loop setup:

```ruby
# Deduplication — prevent re-queueing product URLs seen in previous pages
seen_urls = (vars['seen_urls'] || []).to_set
```

Then in the products loop, wrap queue logic:
```ruby
next if seen_urls.include?(product_url)
seen_urls.add(product_url)
```

And pass forward in pagination vars:
```ruby
vars: vars.merge({ page_number: page_num, seen_urls: seen_urls.to_a })
```

Note: `seen_urls` will grow across pages — cap at 10,000 entries (`seen_urls = seen_urls.first(10000)`) to avoid memory issues on large catalogues.

---

### A3 — Required field nil warning in details boilerplate (Accuracy, LOW EFFORT)

Add at the end of `details.rb`, before `outputs << output`:

```ruby
# Runtime nil check — visible in parser_tester output
_required = { name: name, customer_price_lc: customer_price_lc, img_url: img_url }
_missing = _required.select { |_, v| v.nil? || v.to_s.strip.empty? }.keys
puts "WARN missing: #{_missing.join(', ')}" unless _missing.empty?
```

Uses underscore-prefixed vars to avoid polluting the output hash namespace.

---

### A4 — Price format detection instruction in TOML (Accuracy, MEDIUM EFFORT)

Add to `dmart-details-parser.toml` step 9 field discovery, under the pricing group:

```
Price format detection (run BEFORE writing price extraction code):
- Run: browser_grep_html(query: "<raw price text visible on page>")
- Check if the raw price matches European format: digits + period + 3 digits + comma + 2 digits
  Pattern: /\d{1,3}\.\d{3},\d{2}/  → e.g., "1.299,00" or "23.450,00"
- If European format detected:
  Write: number_from(price_text.gsub('.','').gsub(',','.'))
  NOT: number_from(price_text)   ← this gives wrong result for European format
- If standard format: number_from(price_text) is correct
- Document detected format in scraper-knowledge.md
```

---

### A5 — Category context fallback in details TOML (Accuracy, LOW EFFORT)

Add to `dmart-details-parser.toml` in the category extraction section:

```
Category fallback chain (in order):
1. Breadcrumb CSS selector (site-specific)
2. vars['category_name'] from listings parser (always available)
3. nil

Write Ruby as:
  category = breadcrumb_extracted_category || vars['category_name']
```

Currently agents often overwrite category with nil when breadcrumb extraction fails, discarding the category_name that was already passed through vars.

---

### A6 — Multi-page selector validation in Phase 2 TOML (Accuracy, MEDIUM EFFORT)

In `dmart-navigation-parser.toml`, after discovering a selector, add:

```
Selector validation (required before marking as verified):
- Test selector on the primary page (already open)
- Navigate to a SECOND listing page (different category if possible)
- Re-run browser_verify_selector() with the same selector
- If match count ≥ 1 on both pages → mark verified: true, confidence: 0.9+
- If match count = 0 on any page → selector is fragile, try broader selector
- Record both test URLs in navigation-selectors.json under urls_accessed
```

---

## 5. Implementation Order

| # | Change | Files | Token impact | Accuracy impact | Effort |
|---|---|---|---|---|---|
| T1 | Strip duplicate preamble blocks | All 8 TOMLs + system.md | **−3,500 tokens/session** | None | Medium |
| T2 | Merge JSON+MD state file pairs | All 6 TOMLs (write/read steps) | **−2,000 tokens/session** | None | High |
| T3 | Batch field discovery by area | `dmart-details-parser.toml` | **−45 tool calls/Phase 3** | Higher selector quality | Medium |
| A1 | Pagination fallback chain | `dmart-navigation-parser.toml` | None | **Eliminates silent page-1-only** | Medium |
| A2 | URL deduplication in listings | `listings.rb` boilerplate | None | **Eliminates duplicate outputs** | Low |
| A3 | Required field nil warning | `details.rb` boilerplate | None | **Surfaces silent nil fields** | Low |
| A4 | Price format detection | `dmart-details-parser.toml` | None | **Fixes European price parsing** | Low |
| A5 | Category context fallback | `dmart-details-parser.toml` | None | Reduces nil category fields | Low |
| T4 | parser_tester quiet by default | All TOMLs | −500 tokens/run | None | Low |
| A6 | Multi-page selector validation | `dmart-navigation-parser.toml` | +1 tool call/selector | **Reduces broken selectors** | Medium |

**Recommended sequence:** A2 → A3 → T4 → A4 → A5 → T1 → A1 → T3 → T2 → A6

Start with the low-effort accuracy fixes (A2, A3, A4, A5) since they touch the boilerplate and TOML independently. Then tackle the token reduction items (T1, T4) which require editing multiple TOMLs. T2 and T3 last because they change the state file schema and field discovery workflow — higher coordination cost.
