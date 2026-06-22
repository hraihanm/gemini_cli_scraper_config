# Phase 3: Restaurant Details Parser

**version:** 2.0.0

**Used by:** dhero
**Reads:** `navigation-selectors.json` (`_notes` inside JSON; legacy `navigation-knowledge.md` optional), `discovery-state.json`
**Writes:** `restaurant-details-state.json` (add top-level **`_notes`** markdown; drop separate `restaurant-details-knowledge.md` for new runs — merge legacy `.md` into `_notes` if resuming)
**Edits:** `parsers/restaurant_details.rb`
**Next phase:** `menu-parser` (index 3 in dhero pipeline)

---

## Context

This phase handles restaurant detail pages — NOT product detail pages. The output is:
1. Parsed restaurant metadata (name, address, cuisine, rating, opening hours, etc.)
2. A list of restaurant detail URLs saved to `restaurant-details-state.json` for the Menu Parser (Phase 4)

The Menu Parser reads these URLs and visits each restaurant page to extract menu items.

---

## Inputs (from args)

- `scraper=<scraper_name>` — REQUIRED
- `project=dhero` — REQUIRED (or set by alias)
- `url=<restaurant_detail_url>` — OPTIONAL — uses sample URL from navigation-selectors.json if not provided
- `resume-url=<url>` — OPTIONAL
- `out=<base_dir>` — OPTIONAL, defaults to `./generated_scraper`
- `auto_next=true|false` — OPTIONAL, default: false

---

## STEP 1: Load State Files and Profile

Load `profiles/dhero.toml`.

Load state files:
1. `navigation-selectors.json` — get `listings.sample_detail_urls` and `_notes` if present
2. (Legacy) `navigation-knowledge.md` — only if needed for one-time merge
3. `discovery-state.json` — popup_handling strategy
4. `restaurant-details-state.json` (if resuming)
5. (Legacy) `restaurant-details-knowledge.md` (if resuming) — merge into `restaurant-details-state.json._notes`

Load `parsers/restaurant_details.rb` from boilerplate.

Validate prerequisites:
- `navigation-selectors.json` must exist
- `restaurant_details.rb` must exist from boilerplate

**Validate Phase 2 output contract** — before proceeding, verify `navigation-selectors.json` contains:
- `listings.product_link_selector` — non-null, non-empty
- `listings.sample_detail_urls` — array with ≥ 1 URL

If missing: **STOP** — display: `"Phase 2 output is incomplete. Re-run: /navigation-parser scraper=<scraper> project=dhero"`

---

## STEP 2: Determine Restaurant Detail URL

Priority: `resume-url` → `url` param → `navigation-selectors.json['listings']['sample_detail_urls'][0]`

---

## STEP 3: Test Existing Parser

```javascript
parser_tester({
  scraper_dir: "<absolute_path>/generated_scraper/<scraper>",
  parser_path: "parsers/restaurant_details.rb",
  page_type: "restaurant_details",
  auto_download: true,
  vars: '{"restaurant_name":"<name>","rank":1}',
  quiet: false
})
```

---

## STEP 4: Navigate and Discover Selectors

Navigate to restaurant detail page. Handle popups.

**Pre-check JSON-LD** (restaurants may use schema.org `Restaurant` or `LocalBusiness`):
```javascript
browser_extract_json_ld({ type: "Restaurant" })
// If not found, try:
browser_extract_json_ld({ type: "LocalBusiness" })
```

Discover selectors for restaurant fields using `docs/shared/selector-discovery.md` protocol:

### Key fields to extract
- `name` — restaurant name
- `cuisine` — cuisine type(s)
- `address` — full address
- `phone` — contact number
- `rating` — customer rating (average)
- `rating_count` — number of ratings/reviews
- `opening_hours` — hours of operation
- `img_url` — restaurant photo
- `description` — about text
- `is_open_now` — current status if available
- `delivery_time` — estimated delivery time (if food delivery site)
- `min_order` — minimum order amount (if applicable)
- `tags` — dietary tags, features (halal, vegan, etc.)
- `url` — canonical restaurant URL

### Menu URL Discovery (CRITICAL for Phase 4)

**Step 4.c — Probe `/menu` sub-URL first (do this before any other check)**

Many food directory sites expose a dedicated menu page at `{base_url}/menu`. Check this pattern before looking for inline content or "View Menu" links:

1. Build candidate: `menu_url = current_restaurant_url.sub(/\.html$/, '') + "/menu"`
2. Navigate to `menu_url` (or use `browser_request` to check status)
3. Run `browser_grep_html(query: "dish-holder")` or `browser_grep_html(query: "menu-item")` — look for any item-level elements
4. Decision:
   - **Items found** → set `menu_url_pattern = "separate_url"`, record `menu_url_template = "{restaurant_url_without_html}/menu"`. Skip remaining checks below.
   - **404 or no items** → fall through to Step 4.d

**Step 4.d — Inline / link scan (fallback)**

- Check if the restaurant detail page has a menu section inline or a separate menu URL
- Look for: menu tabs, "View Menu" links, menu API calls
- If menu is on a separate URL found via a link: capture the pattern → set `menu_url_pattern = "separate_url"`
- If menu is inline on the same page: **do NOT queue the same URL as `menu_listings`** — DataHen GID = hash(url), so re-queuing the same URL with a different page_type is silently ignored and the page will never be fetched again (see `docs/shared/datahen-conventions.md` → "Page GID and URL Deduplication"). Instead: set `menu_url_pattern = "inline_strategy_e"` and extract items directly in `restaurant_details.rb` (see STEP 5 Strategy E)
- Document both `menu_url_pattern` and `menu_url_template` in `restaurant-details-state.json`

---

## STEP 5: Edit parsers/restaurant_details.rb

Follow `docs/shared/datahen-conventions.md` conventions (top-level script, no def parse, etc.).

The output hash MUST use the **canonical `dhero-field-spec.json` `locations` field names** — not ad-hoc keys. Every field is always present (nil-explicit). The boilerplate `parsers/restaurant_details.rb` already encodes this exact hash; discover selectors and fill them rather than inventing field names. Canonical shape:
```ruby
outputs << {
  _collection:               'locations',
  _id:                       lead_id,                # Extraction.md5_id(name, city, address)
  date:                      Time.parse(page['fetched_at']).strftime('%Y%m%d %H:%M:%S'),
  url:                       page['url'],
  crawled_source:            'WEB',                  # internal
  restaurant_country:        'PLACEHOLDER_COUNTRY_ISO',  # INFER, 2-letter
  restaurant_position:       page['vars']&.dig('rank_in_listing'),  # FROM_VARS
  lead_id:                   lead_id,
  restaurant_name:           restaurant_name,        # required — never nil
  restaurant_address:        restaurant_address,
  restaurant_city:           restaurant_city,
  restaurant_area:           restaurant_area,
  restaurant_post_code:      restaurant_post_code,
  restaurant_lat:            restaurant_lat,
  restaurant_long:           restaurant_long,
  phone_number:              phone_number,
  main_cuisine:              main_cuisine,
  restaurant_rating:         restaurant_rating,
  number_of_ratings:         number_of_ratings,
  restaurant_delivers:       restaurant_delivers,
  is_permanently_closed:     is_permanently_closed,  # false for available restaurants
  input_lat:                 page['vars']&.dig('input_lat')&.to_f,   # geo-seed only
  input_long:                page['vars']&.dig('input_long')&.to_f,  # geo-seed only
  opening_hours:             opening_hours,          # A1+A2; {Mon:["HHMM-HHMM"]}
  restaurant_tags:           restaurant_tags,        # A1+A2
  restaurant_delivery_zones: restaurant_delivery_zones,  # A1+A2
  cuisine_name:              cuisine_name,           # A2; Extraction.cuisine_hash(...)
  free_field:                nil,                    # A2
  img_url:                   img_url,                # internal
  description:               description,            # internal
}
```
Use `require './lib/extraction'` and the shared normalizers (`Extraction.cuisine_hash`, `Extraction.opening_hours_*`, `Extraction.format_phone`, `Extraction.md5_id`) instead of re-deriving them. See `docs/shared/dhero-output-schema.md` for the A1/A2/A3 split.

The parser must either queue a `menu_listings` page (when the menu is at a different URL) or extract items inline (when the menu is on the same page). Choose based on `menu_url_pattern`:

**Pattern 1: `/menu` sub-URL (preferred — use when STEP 4.c found items)**
```ruby
menu_root_url = page['url'].sub(/\.html$/, '') + '/menu'

pages << {
  url:       menu_root_url,
  page_type: 'menu_listings',
  vars: {
    loc_id:          lead_id,
    restaurant_name: restaurant_name,
    restaurant_url:  page['url'],
    cuisine:         main_cuisine,
  }
}
```

**Pattern 2: explicit link found on the page**
```ruby
menu_root_url = html.at_css('a[href*="/menu"]')&.[]('href')
pages << { url: menu_root_url, page_type: 'menu_listings', vars: { ... } }
```

**Pattern 3 — Strategy E: menu is inline (same URL as restaurant detail)**
🚨 Do NOT queue `page['url']` again — GID collision, page will never be fetched (see `docs/shared/datahen-conventions.md`).
Extract items directly from the current `content` and add to `outputs`. Do not add any `pages <<` entry for menu.

```ruby
# Inline item extraction — add after the locations output block
# Source: __NEXT_DATA__, embedded JSON, or CSS — agent discovers during STEP 4
# Use dhero item fields (_collection: 'items'), NOT dmart product fields
raw_items = []  # agent replaces with actual extraction

raw_items.each_with_index do |item, idx|
  item_name = item['PLACEHOLDER_NAME_FIELD']&.strip
  next if item_name.nil? || item_name.empty?

  item_id = Digest::MD5.hexdigest("#{lead_id}_#{item_name}_#{idx}")
  outputs << {
    _collection:      'items',
    _id:              item_id,
    date:             Time.parse(page['fetched_at']).strftime('%Y%m%d %H:%M:%S'),
    url:              page['url'],
    crawled_source:   'WEB',
    free_field:       nil,
    currency:         'PLACEHOLDER_CURRENCY',
    lead_id:          lead_id,
    restaurant_id:    lead_id,
    restaurant_name:  restaurant_name,
    restaurant_url:   page['url'],
    cuisine:          main_cuisine,
    item_id:          item_id,
    menu_category:    item['PLACEHOLDER_CATEGORY'],
    item_name:        item_name,
    item_description: item['PLACEHOLDER_DESCRIPTION'],
    item_price:       item['PLACEHOLDER_PRICE']&.to_f,
    item_is_promoted: false,
    original_price:   nil,
    menu_item_image_url: item['PLACEHOLDER_IMAGE'],
    is_available:     true,
    item_attributes:  nil,
    barcode:          nil,
    sku:              item['PLACEHOLDER_ID']&.to_s,
  }
end
warn "[DETAILS] url=#{page['url']} items=#{outputs.count { |o| o[:_collection] == 'items' }}"
# No pages << for menu — items output inline, Phases 4 and 5 are skipped
```

Also set `disabled: true` for `menu_listings` and `menu` page types in `config.yaml` when Strategy E is used.

---

## STEP 6: Test Parser

Test on 3 different restaurant URLs. Fix and re-test if any fail.

---

## STEP 6b: Eval Gate (mandatory before marking phase complete)

```javascript
scraper_run_evals({
  scraper_dir: "<absolute_path>/generated_scraper/<scraper>"
})
```

**Case A — Fixtures exist**: Score ≥ 80% → proceed. Score < 80% → fix and repeat.

**Case B — No fixtures yet**: Create a fixture pair from your most recent parser_tester run:
- `generated_scraper/<scraper>/evals/<scraper_slug>_restaurant_sample/input.html`
- `generated_scraper/<scraper>/evals/<scraper_slug>_restaurant_sample/expected.json`
Then run `scraper_run_evals` to confirm it passes.

Update `phase-status.json` for this phase to include:
```json
"eval_score": 100,
"eval_fixtures": 1,
"validated_output": true
```

---

## STEP 7: Write restaurant-details-state.json

```json
{
  "scraper_name": "<scraper>",
  "restaurant_urls_sampled": ["<url1>", "<url2>", "<url3>"],
  "menu_url_pattern": "separate_url | inline_strategy_e",
  "menu_url_template": "{restaurant_url_without_html}/menu | null",
  "items_extracted_inline": false,
  "menu_page_type": "menu_listings",
  "vars_passed_to_menu": ["loc_id", "restaurant_name", "restaurant_url", "cuisine"],
  "completed_at": "<timestamp>",
  "_notes": "## Restaurant details phase\\n\\n- Selectors, menu URL strategy, vars for menu parser\\n"
}
```

🚨 **MANDATORY:** `restaurant-details-state.json` MUST include non-empty **`_notes`** (markdown) covering fields discovered, selectors, menu URL strategy, and vars flow to the menu parser.

---

## STEP 8: Human notes (in JSON only)

All prose from the old `restaurant-details-knowledge.md` belongs in **`restaurant-details-state.json` → `_notes`**. Do not create a separate `.md` file for new runs.

---

## STEP 9: Update Phase Status, Auto-Chain

Update `phase-status.json`.

Auto-chain check: This is phase index 2 in dhero pipeline. Next phase = `menu-parser` (index 3).

If `auto_next=true`: spawn `/<next_phase> scraper=<scraper> project=dhero auto_next=true`

---

## Completion Checklist

- ✅ `restaurant_details.rb` edited and tested on 3 restaurant URLs
- ✅ Phase 2 output contract validated (STEP 1) — `listings.sample_detail_urls` confirmed
- ✅ Eval gate passed (STEP 6b) — score ≥ 80% OR first fixture created and passing
- ✅ If `menu_url_pattern = "separate_url"`: parser queues `menu_listings` pages for Phase 4
- ✅ If `menu_url_pattern = "inline_strategy_e"`: items extracted inline; `menu_listings` + `menu` disabled in `config.yaml`
- ✅ `restaurant-details-state.json` written (includes `menu_url_pattern`, `items_extracted_inline`, and `_notes`)
- ✅ `phase-status.json` updated
- ✅ IF auto_next=true: browser closed, `/menu-parser` EXECUTED
