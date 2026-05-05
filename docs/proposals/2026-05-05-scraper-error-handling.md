# Proposal: Scraper Error Handling and Observability

**Created:** 2026-05-05
**Status:** Done
**Scope:** `templates/*/parsers/*.rb` (8 files), `docs/shared/datahen-conventions.md`, `docs/shared/agent-rules-gemini.md`, `docs/workflows/phases/03-details-parser.md`

---

## 1. Background

DataHen scrapers are expected to encounter failures — selectors change, sites add popups, optional fields are absent on some SKUs. The project does not aim for fail-proof parsers; it aims for failures that are **easy to diagnose and contain**.

Before this work, a failing detail page would either raise an unhandled exception (crashing the entire parser run) or silently emit an incomplete output hash with no indication of which fields were nil. A listings parser with a bad link at index 3 would abort before processing indexes 4–N. There was no structured record of what the AI agent tried, found, or decided during a phase — so reproducing or debugging a bad scraper required re-running the whole pipeline from scratch.

---

## 2. Current State (before this change)

### Parser boilerplates

- `raise 'name is nil'` was the only explicit error signal in `details.rb` — all other failures were silent.
- No field-level nil summary existed. To find which fields failed you had to read the full output hash manually.
- Listings parsers had no per-item rescue. A single `NoMethodError` on product link #3 would abort the loop, silently losing all products after it.
- `greenfield_boilerplate/parsers/details.rb` used an inline `outputs << { ... }` hash with no error boundary at all.

### Shared rules and conventions

- `docs/shared/datahen-conventions.md`: documented the `_notes` field in state files but had no structured log schema.
- `docs/shared/agent-rules-gemini.md`: had no failure classification. The agent had no guidance on when to retry vs. stop vs. continue.
- `docs/workflows/phases/03-details-parser.md`: had no instruction to record agent decisions (JSON-LD probe result, selector matches, nil rates) in a structured form.

---

## 3. Problem(s)

1. **Silent listing truncation** — a bad product link at index N kills all products after it with no warning.
2. **No nil-field visibility** — you cannot tell which fields failed without inspecting raw output records.
3. **No agent decision trail** — when a phase produces bad output, there is no record of what the agent tried (JSON-LD probe result, selectors attempted, nil rates per test URL).
4. **No failure classification** — the agent had no framework for deciding whether to retry a tool call, stop the phase, or log-and-continue.
5. **Hard crashes on optional-field errors** — unexpected exceptions in `details.rb` propagated uncaught, marking the page failed in DataHen and triggering unnecessary retries.

---

## 4. Proposal

Four independent layers, each adding a distinct kind of observability.

### 4.1 Parser nil-field summary and per-item rescue (Ruby)

**Details parsers** — add a nil-field summary `warn` before every `outputs <<`:

```ruby
nil_fields = output.select { |_, v| v.nil? }.keys
warn "[DETAILS] url=#{page['url']} nil=#{nil_fields.count}/#{output.length} fields: #{nil_fields.join(', ')}" unless nil_fields.empty?
outputs << output
```

`greenfield_boilerplate/details.rb` additionally wraps the output section in `begin/rescue` since it has no other error boundary:

```ruby
begin
  output = { ... }
  nil_fields = output.select { |_, v| v.nil? }.keys
  warn "[DETAILS] url=#{page['url']} nil=#{nil_fields.count}/#{output.length} fields: #{nil_fields.join(', ')}" unless nil_fields.empty?
  outputs << output
  save_outputs outputs if outputs.length > 99
rescue => e
  warn "[DETAILS ERROR] url=#{page['url']} error=#{e.message} (#{e.class})"
end
```

`dhero/restaurant_details.rb` excludes always-present fields (`scraped_at_timestamp`, `crawled_source`) from the nil count to reduce noise:

```ruby
nil_fields = output.reject { |k, _| %i[scraped_at_timestamp crawled_source].include?(k) }.select { |_, v| v.nil? }.keys
```

**Listings parsers** — wrap the product/restaurant link loop body in `begin/rescue` so one bad item logs and the loop continues. Add a count line at the end:

```ruby
products.each_with_index do |product_link, idx|
  begin
    # ... extraction ...
    pages << { ... }
  rescue => e
    warn "[LISTINGS ERROR] url=#{page['url']} idx=#{idx} error=#{e.message}"
  end
end
warn "[LISTINGS] url=#{page['url']} queued=#{pages.length} products"
```

**Files changed:**

| File | Change |
|---|---|
| `templates/production_scraper/parsers/details.rb` | nil-summary `warn` before `outputs <<` |
| `templates/production_scraper/parsers/listings.rb` | per-item rescue + count log |
| `templates/greenfield_boilerplate/parsers/details.rb` | refactor to variable + nil-summary + top-level rescue |
| `templates/greenfield_boilerplate/parsers/listings.rb` | per-item rescue + count log |
| `templates/dmart_dloc_boilerplate/parsers/details.rb` | nil-summary `warn` before `outputs <<` |
| `templates/dmart_dloc_boilerplate/parsers/listings.rb` | per-item rescue + count log |
| `templates/dhero_boilerplate/parsers/restaurant_details.rb` | refactor to variable + nil-summary (filtered) + rescue |
| `templates/dhero_boilerplate/parsers/listings.rb` | per-item rescue + count log |

### 4.2 Agent Decision Log (`_log`) schema in conventions

Added a new "Agent Decision Log (`_log`)" section to `docs/shared/datahen-conventions.md`.

**Rule:** Every state file that carries `_notes` MUST also include a `_log` array. Each element records one key decision or observation.

```json
"_log": [
  { "step": "5", "action": "json_ld_probe", "result": "found", "detail": "Product — fields: name, price, brand" },
  { "step": "6.pricing", "action": "selector_verify", "selector": ".price-tag", "result": "matched", "sample": "€12.99" },
  { "step": "9", "action": "parser_test", "url": "https://…/product/123", "nil_rate": "2/53", "fields_nil": ["brand"] },
  { "step": "6.pricing", "action": "structural_error", "detail": "Selector .price-tag — 0 matches on 3 pages" }
]
```

Six `action` types are defined with required fields:

| `action` | Required fields |
|---|---|
| `json_ld_probe` | `result`, `detail` (type + fields list) |
| `selector_verify` | `selector`, `result`, `sample` |
| `parser_test` | `url`, `nil_rate`, `fields_nil` |
| `pagination_strategy` | `strategy`, `detail` |
| `fallback` | `from`, `to`, `reason` |
| `structural_error` | `detail` (what failed, how many pages tested) |

`_notes` is for human narrative; `_log` is for structured, scannable events.

### 4.3 Agent logging instructions in phase 3 workflow

Added to `docs/workflows/phases/03-details-parser.md`:

- **After STEP 5** (JSON-LD probe): agent must accumulate a `json_ld_probe` `_log` entry.
- **After STEP 9b** (nil-guard check): agent must accumulate one `parser_test` `_log` entry per `parser_tester` run.
- **STEP 10** (`detail-selectors.json` schema): updated to include a populated `_log` example alongside `_notes`.
- **Completion checklist**: added `_log` populated check.

### 4.4 Error taxonomy in agent rules

Added an "Error Taxonomy" section to `docs/shared/agent-rules-gemini.md`:

| Category | Examples | Response |
|---|---|---|
| **Transient** | Network timeout, popup still visible, empty `browser_snapshot` | Retry once; if second attempt fails → treat as Structural |
| **Structural** | Selector 0 matches on 2+ pages, required field nil after 3 URLs, PLACEHOLDER not replaced | STOP — write `structural_error` `_log` entry, update `_notes`, surface to user in **bold** |
| **Data gap** | Optional field nil on some SKUs (tags, brand, sub_category) | Log nil rate in `parser_test` `_log` entry, continue |

**Transient retry rule:** retry once only. Do not loop.

**Structural stop rule:** echo the failure in bold before halting. Do not silently skip.

---

## 5. Implementation Order

All four steps were implemented in this session. Order of execution:

| Step | Files | Commit |
|---|---|---|
| 1. Parser logging | 8 `templates/*/parsers/*.rb` files | `b45d3d3` |
| 2. `_log` schema | `docs/shared/datahen-conventions.md` | `4a883c0` |
| 3. Agent phase instructions | `docs/workflows/phases/03-details-parser.md` | `4a883c0` |
| 4. Error taxonomy | `docs/shared/agent-rules-gemini.md` | `4a883c0` |

Steps 2–4 are documentation-only and have zero runtime risk. Step 1 is additive Ruby — the `rescue` blocks suppress exceptions that would previously crash pages; the `warn` blocks add stderr lines visible in DataHen parser logs. No existing extraction logic was changed.

### Follow-up work (not in scope here)

- Apply the same `_log` accumulation instructions to `02-navigation-parser.md`, `api-03-details.md`, `greenfield-03-details-parser.md`, and `03-restaurant-details.md`.
- Add `_log` to the `navigation-selectors.json` schema in `02-navigation-parser.md` STEP 7.
- Consider adding a top-level `begin/rescue` to `production_scraper/details.rb` and `dmart_dloc_boilerplate/details.rb` once the impact on DataHen page-failure retries is assessed.
