# Phase 5: Menu Details Parser

**version:** 1.0.0

**Used by:** dhero
**Reads:** `menu-listings-state.json`, `restaurant-details-state.json`
**Writes:** `menu-state.json` (includes human **`_notes`**)
**Edits:** `parsers/menu.rb`
**Next phase:** LAST phase in dhero pipeline — no chaining

---

## Context

This is the final phase of the dhero pipeline. The menu listings parser (Phase 4) queued individual category/page URLs as `page_type: "menu"`. This parser receives a single such page and extracts item-level data from it.

This parser does NOT decide which URL to visit or discover pagination — that is Phase 4's job. It receives exactly one page and extracts all items visible on it.

---

## Inputs (from args)

- `scraper=<scraper_name>` — REQUIRED
- `project=dhero` — REQUIRED (or set by alias)
- `url=<menu_category_url>` — OPTIONAL — uses a sample URL derived from `restaurant-details-state.json` if not provided
- `resume-url=<url>` — OPTIONAL
- `out=<base_dir>` — OPTIONAL, defaults to `./generated_scraper`
- `auto_next=true|false` — OPTIONAL, default: false (this is the last phase)

---

## STEP 1: Load State Files and Profile

Load `profiles/dhero.toml`.

Load state files:
1. `menu-listings-state.json` — get `menu_structure`, `strategy`, selectors context
2. `restaurant-details-state.json` — get `restaurant_urls_sampled` for sample URL fallback
3. `discovery-state.json` — popup_handling
4. `menu-state.json` (if resuming)

Load `parsers/menu.rb`.

**Validate Phase 4 output contract:**
- `menu-listings-state.json` must exist → "Run `/menu-listings-parser scraper=<scraper> project=dhero` first"

---

## STEP 2: Determine Sample Menu Page URL

If `url=` or `resume-url=` provided: use it directly.

Otherwise, build from `restaurant-details-state.json.restaurant_urls_sampled[0]`:
- Apply the same URL transformation as Phase 4 (based on `menu_url_pattern`)
- This gives the menu root URL — navigate there and follow one category link to get a real `menu` page sample, OR use the root URL directly if `menu_structure.type = "single_page"`

---

## STEP 3: Test Existing Parser

```javascript
parser_tester({
  scraper_dir: "<absolute_path>/generated_scraper/<scraper>",
  parser_path: "parsers/menu.rb",
  page_type:   "menu",
  auto_download: true,
  vars: '{"loc_id":"<id>","restaurant_name":"<name>","restaurant_url":"<url>","cuisine":"<cuisine>","category_name":"<category>"}',
  quiet: false
})
```

---

## STEP 4: Navigate to Menu Page

Navigate to the sample menu page URL. Handle popups.

This is a single category/page URL — not the menu root. Do not attempt to navigate to other categories here; Phase 4 handles that.

**Pre-check for embedded JSON** (menus often use embedded JSON):
```javascript
browser_evaluate(() => {
  if (window.__NEXT_DATA__) return { found: true, type: 'NEXT_DATA', size: JSON.stringify(window.__NEXT_DATA__).length };
  if (window.__INITIAL_STATE__) return { found: true, type: 'INITIAL_STATE' };
  return { found: false };
})
browser_extract_json_ld({ type: "Menu" })
```

Check for menu API calls:
```javascript
browser_network_requests_simplified()
// Look for requests to /api/menu, /items, /products with JSON responses
```

If API found: use `browser_request` to fetch menu JSON directly.

---

## STEP 5: Discover Menu Item Selectors

Using `docs/shared/selector-discovery.md` protocol.

**Read `category_name` from vars first:**
- If `page['vars']['category_name']` is non-nil: the listings parser already set it — use it directly, skip category selector discovery
- If nil (single-page menu): discover category section containers and extract `category_name` from the page

**Item selector discovery order:**
1. `browser_grep_html(query: "<visible item name>")` — find item container class
2. `browser_grep_html(query: "precio")` or `browser_grep_html(query: "$")` — find price element
3. `browser_extract_images` on one item container — confirm image selector
4. `browser_grep_html(query: "<visible description text>")` — find description element
5. `browser_verify_selector` on each selector before writing parser code

### Key fields to extract per menu item
- `item_name` — item name (never nil — skip item if nil)
- `item_description` — description text
- `item_price` — numeric price (nil if not shown, never 0)
- `currency` — ISO 4217 code (inferred from site/country)
- `category_name` — from vars OR discovered from page section header
- `img_url` — item photo URL
- `is_available` — true unless "sold out" marker present
- `item_is_promoted` — true if promo badge/section present, else false
- `item_attributes` — dietary/feature tags as JSON string, nil if none
- `sku` — item ID from `data-id`, `data-item-id`, or similar attribute

### Deduplication
Some sites render the same items twice (desktop + mobile). Detect via duplicate `data-id` or identical `item_name` within same category. Deduplicate using a `processed_ids` array.

---

## STEP 6: Edit parsers/menu.rb

Follow `docs/shared/datahen-conventions.md` conventions.

```ruby
html = Nokogiri::HTML(content)

# FROM_VARS
restaurant_id   = page['vars']&.dig('loc_id')
restaurant_name = page['vars']&.dig('restaurant_name')
restaurant_url  = page['vars']&.dig('restaurant_url')
cuisine         = page['vars']&.dig('cuisine')
category_name   = page['vars']&.dig('category_name')  # nil if single-page menu

processed_ids = []

# If single-page: iterate category sections; if multi-category: items are all visible
html.css('PLACEHOLDER_SECTION_SELECTOR').each do |section|
  # Only used when category_name is nil (single-page); otherwise use var
  section_name = category_name || section.at_css('PLACEHOLDER_SECTION_TITLE_SELECTOR')&.text&.strip

  section.css('PLACEHOLDER_ITEM_SELECTOR').each_with_index do |el, idx|
    begin
      item_id_attr = el['data-id'] || el['data-item-id']
      next if item_id_attr && processed_ids.include?(item_id_attr)
      processed_ids << item_id_attr if item_id_attr

      item_name = el.at_css('PLACEHOLDER_ITEM_NAME_SELECTOR')&.text&.strip
      next if item_name.nil? || item_name.empty?

      # ... extract remaining fields ...

      item_id = Digest::MD5.hexdigest("#{restaurant_id}_#{item_name}_#{item_id_attr || idx}")

      outputs << {
        _collection:      'items',
        _id:              item_id,
        date:             Time.parse(page['fetched_at']).strftime('%Y%m%d %H:%M:%S'),
        url:              page['url'],
        crawled_source:   'WEB',
        free_field:       nil,
        currency:         'PLACEHOLDER_CURRENCY',
        lead_id:          restaurant_id,
        restaurant_id:    restaurant_id,
        restaurant_name:  restaurant_name,
        restaurant_url:   restaurant_url,
        cuisine:          cuisine,
        item_id:          item_id,
        menu_category:    section_name,
        item_name:        item_name,
        item_description: item_description,
        item_price:       item_price,
        item_is_promoted: item_is_promoted,
        original_price:   original_price,
        menu_item_image_url: menu_item_image_url,
        is_available:     is_available,
        item_attributes:  item_attributes,
        barcode:          nil,
        sku:              item_id_attr,
      }
    rescue => e
      warn "[MENU ERROR] url=#{page['url']} idx=#{idx} error=#{e.message}"
    end
  end
end

warn "[LISTINGS] url=#{page['url']} queued=#{outputs.length} items"
save_outputs(outputs) if outputs.length > 99
```

---

## STEP 7: Test Parser

Test on 3 different menu page URLs (individual category pages, not root). Each should produce menu item outputs. Fix and re-test if any fail.

---

## STEP 7b: Eval Gate (mandatory before marking phase complete)

```javascript
scraper_run_evals({ scraper_dir: "<absolute_path>/generated_scraper/<scraper>" })
```

**Case A — Fixtures exist**: Score ≥ 80% → proceed. Score < 80% → fix and repeat.

**Case B — No fixtures yet**: Create fixture pair from most recent parser_tester run:
- `evals/<scraper_slug>_menu_sample/input.html`
- `evals/<scraper_slug>_menu_sample/expected.json`

---

## STEP 8: Write menu-state.json (USE ABSOLUTE PATH)

```json
{
  "scraper_name": "<scraper>",
  "menu_url_pattern": "separate_url | inline_same_page",
  "menu_url_template": "{restaurant_url_without_html}/menu | null",
  "menu_structure": {
    "type": "multi_category | single_page | paginated | api_driven",
    "has_prices": true,
    "has_images": true,
    "dedup_required": false
  },
  "selectors_summary": {
    "section_container": "<selector>",
    "section_title": "<selector>",
    "item_container": "<selector>",
    "item_name": "<selector>",
    "item_description": "<selector>",
    "item_price": "<selector>",
    "item_image": "<selector>",
    "sku_attr": "data-id"
  },
  "test_urls": ["<url1>", "<url2>", "<url3>"],
  "completed_at": "<timestamp>",
  "_notes": "## Menu Details phase\n\n- Selectors\n- Fields nil\n- Dedup strategy\n- Embedded JSON / API findings\n"
}
```

---

## STEP 9: Update Phase Status

`phase-status.json` — set `menu_discovery.status = "completed"`.

`browser-context.json` — update.

---

## STEP 10: Completion Report (FINAL PHASE)

```
🎉 DHero Scraper Generation Complete!

Scraper: <scraper_slug>
Project: dhero

All 5 phases completed:
  ✅ Phase 1: Site Discovery
  ✅ Phase 2: Navigation Parser (Restaurant Listings)
  ✅ Phase 3: Restaurant Details Parser
  ✅ Phase 4: Menu Listings Parser
  ✅ Phase 5: Menu Details Parser

Parser files ready:
  - parsers/listings.rb
  - parsers/restaurant_details.rb
  - parsers/menu_listings.rb
  - parsers/menu.rb

To test the full pipeline:
  datahen_run reset → seed → step listings → step restaurant_details → step menu_listings → step menu
```

---

## Completion Checklist

- ✅ `category_name` source determined (from vars or discovered from page CSS)
- ✅ Item selectors discovered and verified
- ✅ Deduplication handled if desktop + mobile renders detected
- ✅ `menu.rb` edited with item selectors
- ✅ Parser tested on 3 menu page URLs
- ✅ Each page produces menu item outputs
- ✅ Phase 4 output contract validated (STEP 1) — `menu-listings-state.json` confirmed
- ✅ Eval gate passed (STEP 7b) — score ≥ 80% OR first fixture created and passing
- ✅ `menu-state.json` written (includes `menu_url_pattern`, `_notes`)
- ✅ `phase-status.json` updated
- ✅ Final completion report shown
