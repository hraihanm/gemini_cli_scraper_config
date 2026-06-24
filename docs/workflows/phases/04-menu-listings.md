# Phase 4: Menu Listings Parser

**version:** 1.0.0

**Used by:** dhero
**Reads:** `restaurant-details-state.json`, `discovery-state.json`
**Writes:** `menu-listings-state.json` (includes human **`_notes`**)
**Edits:** `parsers/menu_listings.rb`
**Next phase:** `menu-parser` (Phase 5)

---

## Context

This is the navigation phase for menus. The restaurant details parser (Phase 3) queued each restaurant's menu root URL as `page_type: "menu_listings"`. This parser navigates to that URL, discovers the menu's structure (single page / tabbed categories / paginated / API), and queues individual category/page URLs as `page_type: "menu"` for the Menu Details parser (Phase 5).

For most structures this phase does NOT extract item data — that is Phase 5's job.
**Exception — Strategy E (listings-only):** when the menu root URL already contains complete item data (e.g. `__NEXT_DATA__`), this phase outputs items directly and Phase 5 is skipped entirely.

---

## Inputs (from args)

- `scraper=<scraper_name>` — REQUIRED
- `project=dhero` — REQUIRED (or set by alias)
- `url=<menu_root_url>` — OPTIONAL — uses sample from `restaurant-details-state.json` if not provided
- `resume-url=<url>` — OPTIONAL
- `out=<base_dir>` — OPTIONAL, defaults to `./generated_scraper`
- `auto_next=true|false` — OPTIONAL, default: false

---

## STEP 1: Load State Files and Profile

Load `profiles/dhero.toml`.

Load state files:
1. `restaurant-details-state.json` — get `restaurant_urls_sampled`, `menu_url_pattern`, `menu_url_template`, `vars_passed_to_menu`, `_notes`
2. `discovery-state.json` — popup_handling strategy
3. `menu-listings-state.json` (if resuming)

Load `parsers/menu_listings.rb` from boilerplate.

**Validate Phase 3 output contract** — before proceeding, verify `restaurant-details-state.json` contains:
- `restaurant_urls_sampled` — array with ≥ 1 URL
- `menu_url_pattern` — non-null (`"separate_url"` or `"inline_same_page"`)
- `vars_passed_to_menu` — array with ≥ 1 var name

If missing: **STOP** — display: `"Phase 3 output is incomplete. Re-run: /restaurant-details-parser scraper=<scraper> project=dhero"`

---

## STEP 2: Determine Menu Root URL

Build the URL to navigate to based on `menu_url_pattern`:

| `menu_url_pattern` | URL |
|---|---|
| `"separate_url"` | `restaurant_url.sub(/\.html$/, '') + "/menu"` |
| `"inline_same_page"` | restaurant URL unchanged |

`url=` / `resume-url=` params override. If param ends with `/menu`, treat as `separate_url`.

---

## STEP 3: Test Existing Parser

```javascript
parser_tester({
  scraper_dir: "<absolute_path>/generated_scraper/<scraper>",
  parser_path: "parsers/menu_listings.rb",
  page_type:   "menu_listings",
  auto_download: true,
  vars: '{"loc_id":"<id>","restaurant_name":"<name>","restaurant_url":"<url>","cuisine":"<cuisine>"}',
  quiet: false
})
```

The boilerplate defaults to Strategy B (single-page pass-through). If it produces ≥ 1 queued `menu` page, the parser is working — determine whether multi-category pages exist before selecting a strategy.

---

## STEP 4: Navigate and Detect Menu Structure

Navigate to the menu root URL. Handle popups.

**Pre-check for embedded JSON / API** (often the most reliable source of menu structure):
```javascript
browser_evaluate(() => {
  if (window.__NEXT_DATA__) return { found: true, type: 'NEXT_DATA' };
  if (window.__INITIAL_STATE__) return { found: true, type: 'INITIAL_STATE' };
  return { found: false };
})
browser_extract_json_ld({ type: "Menu" })
browser_network_requests_simplified()
// Look for /api/menu, /menu/categories, /items — JSON responses
```

**Mandatory: Scroll + Interaction + Network Exhaustion Probe** — run BEFORE classifying structure.

Full protocol: `docs/shared/pagination-network-exhaustion.md`. Required steps:

1. **Scroll** — `browser_evaluate(() => window.scrollTo(0, document.body.scrollHeight))` × 3; run `browser_network_requests_simplified()` after each scroll
2. **Tab/category clicks** — click each visible menu category chip/tab/section link one by one; after each click run:
   ```javascript
   browser_network_search({ query: "category|menu|items", searchIn: ["requestUrl", "responseBody"] })
   ```
   Record any new JSON endpoints (URL, params, method) — these are per-category API calls
3. **Classify API** — if tab clicks trigger XHR, run `browser_get_request_context` on the discovered URL to separate stable vs ephemeral headers; record in `menu-listings-state.json.menu_api`

Do **not** classify as Structure B or E until this probe is complete. A tab-click that triggers `/api/menu?categoryId=X` means Structure D (API) or Strategy A (queue per-category URL), never B.

Add a `_log` entry per probe:
```json
{ "action": "pagination_probe", "surface": "menu_categories", "strategy": "<result>", "evidence": "<what triggered>" }
```

**Detect menu structure — classify into one of:**

### Structure A: Multi-category / tabbed
- Visible category tabs or section links that load different items
- Each category has its own URL or anchor
- Probe: `browser_grep_html(query: "categoria")` or `browser_grep_html(query: "tab")`
- Confirm with `browser_count_selector` on the tab container

### Structure B: Single page
- All menu items visible on this one page, no separate category URLs
- Probe: `browser_count_selector` on the item container — expect > 0 items
- No tabs, no load-more, no separate category links

### Structure C: Paginated
- Items split across multiple pages (page param or load-more button)
- Probe: `browser_detect_pagination()` — check for count-based or next-button strategy
- Detect total item count or page count

### Structure D: API-driven
- Items loaded via XHR/fetch after page load
- Probe: `browser_network_requests_simplified()` — look for JSON responses with item arrays
- Use `browser_request` to fetch the API directly

### Structure E: Listings-only (full item data already on this page)
- The menu root URL already delivers complete enough item records — without needing a second fetch per page
- Source can be anything: embedded JSON (`__NEXT_DATA__`, `__INITIAL_STATE__`, inline `<script>` blocks), a single API call, or even dense HTML — the source does not matter
- **Completeness check** (run this on 3 sample restaurants before deciding):
  - Required fields present on ≥ 90% of items: `item_name`, `item_price`
  - Desirable fields present on ≥ 50% of items: `item_description`, `img_url`, `category_name`
  - If both conditions met → Structure E
  - If `item_price` is consistently nil or `item_name` is missing → do NOT use Structure E; fall back to B/C/D and let Phase 5 extract
- **Phase 5 is skipped when this structure is used** — items are output from `menu_listings.rb` directly

Document the detected structure in `menu-listings-state.json`.

---

## STEP 5: Discover Category / Page URLs

### For Structure A (multi-category):
Discovery order:
1. `browser_grep_html(query: "<visible category name>")` — find the tab/link container HTML
2. `browser_inspect_element(ref)` — get exact CSS selector for a tab link
3. `browser_verify_selector` — confirm selector matches expected text
4. Extract all category URLs: `html.css('<tab_selector>').map { |t| [t.text.strip, t['href']] }`
5. Confirm each URL is unique and reachable

### For Structure C (paginated):
1. `browser_detect_pagination()` — get strategy (count-based or next-button)
2. For count-based: find total count element, calculate total pages, build URL pattern
3. For next-button: confirm selector; in the parser, queue page 1 and each subsequent page

### For Structure B or D:
No URL discovery needed — Strategy B queues current URL; API strategy queues the API endpoint.

### For Structure E (listings-only):
No URL discovery needed. Run the completeness check (defined in STEP 4 Structure E) on 3 sample restaurants before committing to this strategy. Proceed to Strategy E in STEP 6 only if the check passes.

---

## STEP 6: Edit parsers/menu_listings.rb

Select the correct strategy and uncomment/implement it. Remove inapplicable strategies.

**Strategy A example (multi-category tabs):**
```ruby
html.css('.CATEGORY_TAB_SELECTOR').each do |tab|
  category_name = tab.text.strip
  next if category_name.empty?

  href = tab['href'] || tab.at_css('a')&.[]('href')
  next unless href

  category_url = href.start_with?('http') ? href : Addressable::URI.join(page['url'], href).to_s

  pages << {
    url:       category_url,
    page_type: 'menu',
    headers:   ReqHeaders::MINIMAL_HEADERS,
    vars:      base_vars.merge(category_name: category_name),
  }
  queued += 1
end
```

**Strategy B (single-page, no change needed):** the boilerplate fallback handles this correctly.

**Strategy C example (count-based pagination):**
```ruby
total_text = html.at_css('PLACEHOLDER_TOTAL_SELECTOR')&.text
total_items = total_text.match(/(\d[\d,]*)/)[1].gsub(',', '').to_i
items_per_page = 20  # verify on site
(1..(total_items.to_f / items_per_page).ceil).each do |n|
  pages << {
    url:       "#{page['url']}?page=#{n}",
    page_type: 'menu',
    headers:   ReqHeaders::MINIMAL_HEADERS,
    vars:      base_vars.merge(category_name: nil, page_number: n),
  }
  queued += 1
end
```

**Strategy E (listings-only — output items directly, skip Phase 5):**

The agent discovers where item data lives (embedded JSON, API response, or HTML) and writes extraction code for that source. The output structure is always the same: dhero item fields.

CRITICAL — use **dhero item fields** (`dhero-field-spec.json`, collection `items`). Do NOT use dmart product fields (`customer_price_lc`, `base_price_lc`, `has_discount`, `brand`, `upc`, etc.).

```ruby
# Agent fills in the actual extraction — source varies per site.
# Examples:
#   Embedded JSON:  JSON.parse(html.at_css('script#__NEXT_DATA__')&.text || '{}')
#   Inline script:  html.at_css('script').text.match(/window\.__DATA__\s*=\s*(\{.*?\});/m)[1]
#   API response:   JSON.parse(content)  # when page fetched as fetch_type: 'standard'
#   HTML:           html.css('PLACEHOLDER_ITEM_SELECTOR').each { ... }
#
# Whatever the source, map to dhero item fields:

raw_items = []  # PLACEHOLDER — agent replaces with actual extraction

item_id_base = page['vars']&.dig('loc_id')

raw_items.each_with_index do |item, idx|
  item_name = item['PLACEHOLDER_NAME_FIELD']&.strip
  next if item_name.nil? || item_name.empty?

  item_price = item['PLACEHOLDER_PRICE_FIELD']&.to_f
  item_price = nil if item_price == 0.0

  item_id = Digest::MD5.hexdigest("#{item_id_base}_#{item_name}_#{item['PLACEHOLDER_ID_FIELD'] || idx}")

  outputs << {
    _collection: 'items',
    _id:         item_id,

    date:           Time.parse(page['fetched_at']).strftime('%Y%m%d %H:%M:%S'),
    url:            page['url'],
    crawled_source: 'WEB',
    free_field:     nil,

    currency: 'PLACEHOLDER_CURRENCY_CODE',

    lead_id:         item_id_base,
    restaurant_id:   item_id_base,
    restaurant_name: restaurant_name,
    restaurant_url:  restaurant_url,
    cuisine:         cuisine,

    item_id:          item_id,
    menu_category:    item['PLACEHOLDER_CATEGORY_FIELD'],
    item_name:        item_name,
    item_description: item['PLACEHOLDER_DESCRIPTION_FIELD']&.strip,
    item_price:       item_price,
    item_is_promoted: false,
    original_price:   nil,
    menu_item_image_url: item['PLACEHOLDER_IMAGE_FIELD'],
    is_available:     true,  # agent replaces with actual availability field
    item_attributes:  nil,   # agent populates if options/modifiers exist
    barcode:          nil,
    sku:              item['PLACEHOLDER_ID_FIELD']&.to_s,
  }
end

warn "[MENU_LISTINGS] url=#{page['url']} strategy=E items=#{outputs.length}"
# Do NOT queue any 'menu' pages — Phase 5 is skipped
save_outputs(outputs) if outputs.length > 99
```

After implementing Strategy E:
- Set `details_parser_needed: false` in `menu-listings-state.json`
- Set `disabled: true` for the `menu` page type in `config.yaml`

---

## STEP 7: Test Parser

Test on 3 different restaurant menu root URLs. Fix and re-test if any fail.

**Pass criteria by strategy:**
- Strategy A/B/C/D: each URL must produce ≥ 1 queued `menu` page
- Strategy E (listings-only): each URL must produce ≥ 1 item in `outputs` AND 0 queued `menu` pages

---

## STEP 7b: Eval Gate

```javascript
scraper_run_evals({ scraper_dir: "<absolute_path>/generated_scraper/<scraper>" })
```

**Case A — Fixtures exist**: Score ≥ 80% → proceed.
**Case B — No fixtures yet**: Create fixture pair:
- `evals/<scraper_slug>_menu_listings_sample/input.html`
- `evals/<scraper_slug>_menu_listings_sample/expected.json` (expected `pages` queue entries)

---

## STEP 8: Write menu-listings-state.json (USE ABSOLUTE PATH)

```json
{
  "scraper_name": "<scraper>",
  "menu_structure": {
    "type": "multi_category | single_page | paginated | api_driven | listings_only",
    "strategy": "A | B | C | D | E",
    "category_count": 5,
    "has_separate_category_urls": true
  },
  "details_parser_needed": true,
  "menu_api": {
    "found": false,
    "endpoint": null,
    "method": "GET | POST",
    "params": [],
    "stable_headers": {},
    "triggered_by": "tab_click | scroll | page_load | none"
  },
  "pagination_surfaces": [
    {
      "surface": "menu_categories",
      "strategy": "page_number | offset | cursor | infinite_scroll | next_button | none",
      "endpoint": null,
      "probe_log": ["static_detect", "scroll", "tab_click", "network_capture"],
      "evidence": "<what triggered / what was absent>",
      "pagination_warning": null
    }
  ],
  "selectors_summary": {
    "category_tab": "<selector>",
    "category_url_attr": "href"
  },
  "test_urls": ["<menu_url1>", "<menu_url2>", "<menu_url3>"],
  "completed_at": "<timestamp>",
  "_notes": "## Menu Listings phase\n\n- Structure detected\n- Strategy used\n- Selectors\n- Category count\n- menu_api found: yes/no\n"
}
```

Set `"details_parser_needed": false` when Strategy E is used.

---

## STEP 9: Update Phase Status, Auto-Chain

`phase-status.json` — set `menu_listings_discovery.status = "completed"`.

Auto-chain: next phase = `menu-parser` (Phase 5, index 4 in dhero pipeline).

If `auto_next=true` AND `details_parser_needed: true`: spawn `/menu-parser scraper=<scraper> project=dhero auto_next=true`.

If `details_parser_needed: false` (Strategy E): Phase 5 is skipped. Report pipeline complete.

---

## Completion Checklist

- ✅ Menu root URL correctly determined from `restaurant-details-state.json`
- ✅ Scroll + tab-click + network probe completed before classifying structure (STEP 4 mandatory probe)
- ✅ `menu_api` and `pagination_surfaces` recorded in state file
- ✅ Menu structure classified (A/B/C/D/E)
- ✅ `menu_listings.rb` implements the correct strategy
- ✅ Tested on 3 restaurant menu URLs — each produces ≥ 1 `menu` page queued (A/B/C/D) OR ≥ 1 item output (E)
- ✅ If Strategy E: `config.yaml` `menu` page type set to `disabled: true`; `details_parser_needed: false` in state file
- ✅ Eval gate passed (STEP 7b)
- ✅ `menu-listings-state.json` written (includes `_notes`)
- ✅ `phase-status.json` updated
- ✅ IF `auto_next=true`: `/menu-parser` spawned
