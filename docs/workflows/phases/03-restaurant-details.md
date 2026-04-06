# Phase 3: Restaurant Details Parser

**Used by:** dhero
**Reads:** `navigation-selectors.json`, `navigation-knowledge.md`, `discovery-state.json`
**Writes:** `restaurant-details-state.json`, `restaurant-details-knowledge.md`
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
1. `navigation-selectors.json` — get `listings.sample_detail_urls`
2. `navigation-knowledge.md`
3. `discovery-state.json` — popup_handling strategy
4. `restaurant-details-state.json` (if resuming)
5. `restaurant-details-knowledge.md` (if resuming)

Load `parsers/restaurant_details.rb` from boilerplate.

Validate prerequisites:
- `navigation-selectors.json` must exist
- `restaurant_details.rb` must exist from boilerplate

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
- Check if the restaurant detail page has a menu section inline or a separate menu URL
- Look for: menu tabs, "View Menu" links, menu API calls
- If menu is inline on the same page: Phase 4 will reuse the same URL
- If menu is on a separate URL: capture the pattern and queue it
- Document `menu_url_pattern` in `restaurant-details-state.json`

---

## STEP 5: Edit parsers/restaurant_details.rb

Follow `docs/shared/datahen-conventions.md` conventions (top-level script, no def parse, etc.).

The output hash for restaurants typically includes:
```ruby
outputs << {
  name:             name,
  cuisine:          cuisine,
  address:          address,
  phone:            phone,
  rating:           rating,
  rating_count:     rating_count,
  opening_hours:    opening_hours,
  img_url:          img_url,
  description:      description,
  is_open_now:      is_open_now,
  delivery_time:    delivery_time,
  min_order:        min_order,
  tags:             tags,
  url:              page[:url],
  scraped_at_timestamp: Time.now.utc.iso8601,
  crawled_source:   'WEB',
}
```

The parser should ALSO queue the menu page for each restaurant:
```ruby
# Queue menu page for this restaurant
menu_url = page[:url]  # if menu is inline
# OR
menu_url = html.at_css('a.menu-link')&.[]('href')  # if separate URL

pages << {
  url: menu_url,
  page_type: "menu",
  vars: {
    restaurant_name: name,
    restaurant_url:  page[:url],
    cuisine:         cuisine,
  }
}
```

---

## STEP 6: Test Parser

Test on 3 different restaurant URLs. Fix and re-test if any fail.

---

## STEP 7: Write restaurant-details-state.json

```json
{
  "scraper_name": "<scraper>",
  "restaurant_urls_sampled": ["<url1>", "<url2>", "<url3>"],
  "menu_url_pattern": "inline_same_page | separate_url",
  "menu_page_type": "menu",
  "vars_passed_to_menu": ["restaurant_name", "restaurant_url", "cuisine"],
  "completed_at": "<timestamp>"
}
```

---

## STEP 8: Write restaurant-details-knowledge.md

Include: fields discovered, selectors, menu URL strategy, vars flow to menu parser.

---

## STEP 9: Update Phase Status, Auto-Chain

Update `phase-status.json`.

Auto-chain check: This is phase index 2 in dhero pipeline. Next phase = `menu-parser` (index 3).

If `auto_next=true`: spawn `/<next_phase> scraper=<scraper> project=dhero auto_next=true`

---

## Completion Checklist

- ✅ `restaurant_details.rb` edited and tested on 3 restaurant URLs
- ✅ Parser queues menu pages for Phase 4
- ✅ `restaurant-details-state.json` written (includes menu URL pattern)
- ✅ `restaurant-details-knowledge.md` written
- ✅ `phase-status.json` updated
- ✅ IF auto_next=true: browser closed, `/menu-parser` EXECUTED
