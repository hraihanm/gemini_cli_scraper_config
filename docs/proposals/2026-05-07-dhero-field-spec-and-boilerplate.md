# Proposal: DHero Field Spec and Boilerplate Alignment

**Created:** 2026-05-07
**Status:** Done
**Scope:** `spec_full.json` (new), `templates/dhero_boilerplate/parsers/*.rb`, `templates/dhero_boilerplate/config.yaml`, `spec/sample-dhero-spec.md`

---

## 1. Background

The dhero pipeline (`profiles/dhero.toml`) is a 4-phase HTML scraping pipeline for restaurant data:

```
listings → restaurant_details → menu
```

It references `spec_full.json` under `[defaults]` but that file does not exist yet. The boilerplate parsers in `templates/dhero_boilerplate/` use a simplified field schema (`name`, `address`, `cuisine`) that diverges from the legacy field names already in client pipelines (`restaurant_name`, `restaurant_address`, `main_cuisine`). The `spec/sample-dhero-spec.md` file is empty (0 bytes).

Reference implementations for field names: `original_scraper/degusta_pa` and `original_scraper/opentable_ae`.

---

## 2. Current State

- `profiles/dhero.toml` → `[defaults] field_spec = "spec_full.json"` — **file missing**
- `templates/dhero_boilerplate/parsers/restaurant_details.rb` — uses simplified names: `name`, `address`, `cuisine`, `rating`, etc.
- `templates/dhero_boilerplate/parsers/menu.rb` — uses `name`, `description`, `customer_price_lc`, `currency_code_lc`
- `templates/dhero_boilerplate/config.yaml` — exporters reflect the simplified names; does not align with client pipeline
- `spec/sample-dhero-spec.md` — empty placeholder

The dmart equivalent (`field-spec.json` at repo root) uses `extraction_method` to classify fields: `HARDCODED`, `INFER`, `FIND`, `DETERMINE`, `PROCESS`.

---

## 3. Problems

1. **No canonical field spec** — the Gemini agent has no authoritative reference for what dhero scrapers must produce. Each new scraper risks field name drift.
2. **Boilerplate uses wrong field names** — client pipelines consume `restaurant_name`, `restaurant_address`, `main_cuisine`, etc. Scrapers generated from the current boilerplate would deliver the wrong schema.
3. **No FROM_VARS classification** — dmart is a 2-phase flow so vars handoffs are minor. DHero is 4-phase with explicit data handoffs (`restaurant_id`, `restaurant_name`, `cuisine`, `restaurant_position` all flow between phases). The spec needs to document which fields come from `page['vars']` vs scraped vs hardcoded.
4. **`crawled_source` not explicitly marked** — it must always be `'WEB'` for HTML scrapers. Without a spec entry it could be omitted or misspelled.

---

## 4. Proposal

### 4.1 `spec_full.json` structure

Single file at repo root. Extends the dmart taxonomy with one new `extraction_method`:

| extraction_method | Meaning |
|---|---|
| `HARDCODED` | Fixed per scraper type — `crawled_source: 'WEB'`, `scraped_at_timestamp`, `url`, `free_field` |
| `INFER` | Per-project constant, set during Phase 1 — `restaurant_country` (2-letter ISO), `currency` in menu items |
| `FROM_VARS` | Passed via `page['vars']` from a prior phase — `restaurant_position`, `restaurant_id`, `restaurant_name` (menu), `cuisine` (menu) |
| `FIND` | Scraped from HTML / JSON-LD / meta tags |
| `DETERMINE` | Computed from other extracted fields — `restaurant_delivers` (from tags), `item_is_promoted` |

Top-level structure:

```json
{
  "version": "1.0",
  "description": "DHero restaurant pipeline — canonical field spec",
  "collections": ["restaurants", "menu_items"],
  "fields": [ ... ]
}
```

Each field entry:

```json
{
  "name": "restaurant_name",
  "collection": "restaurants",
  "type": "str",
  "extraction_method": "FIND",
  "priority": 1,
  "notes": "FIND — JSON-LD name, og:title, or CSS. Required.",
  "selectors": [],
  "verified": false,
  "discovered": false,
  "confidence": null,
  "extraction_notes": null
}
```

For `HARDCODED`:

```json
{
  "name": "crawled_source",
  "collection": "*",
  "type": "str",
  "extraction_method": "HARDCODED",
  "priority": 3,
  "notes": "Always 'WEB' for HTML scrapers.",
  "hardcoded_value": "WEB"
}
```

`"collection": "*"` means the field appears in all collections.

### 4.2 Restaurants collection fields

| Field | extraction_method | Priority | Notes |
|---|---|---|---|
| `lead_id` | `DETERMINE` | 1 | MD5 hash of stable identifiers |
| `url` | `HARDCODED` | 3 | `page['url']` |
| `date` | `HARDCODED` | 3 | `Time.parse(page['fetched_at']).strftime(...)` |
| `restaurant_name` | `FIND` | 1 | JSON-LD → og:title → CSS |
| `restaurant_address` | `FIND` | 1 | JSON-LD address.streetAddress → CSS |
| `restaurant_city` | `FIND` | 2 | JSON-LD address.addressLocality → CSS |
| `restaurant_area` | `FIND` | 2 | JSON-LD address.addressRegion → CSS |
| `restaurant_post_code` | `FIND` | 3 | JSON-LD address.postalCode → CSS |
| `restaurant_country` | `INFER` | 2 | 2-letter ISO — hardcoded per project during Phase 1 |
| `restaurant_lat` | `FIND` | 2 | JSON-LD geo.latitude → meta → CSS |
| `restaurant_long` | `FIND` | 2 | JSON-LD geo.longitude → meta → CSS |
| `phone_number` | `FIND` | 2 | JSON-LD telephone → meta → CSS |
| `main_cuisine` | `FIND` | 2 | JSON-LD servesCuisine (first) → CSS |
| `cuisine_name` | `FIND` | 2 | Hash `{cuisine1: ..., cuisine2: ...}` from JSON-LD or CSS |
| `restaurant_rating` | `FIND` | 2 | JSON-LD aggregateRating.ratingValue → CSS |
| `number_of_ratings` | `FIND` | 2 | JSON-LD aggregateRating.reviewCount → CSS |
| `opening_hours` | `FIND` | 2 | JSON-LD openingHours → CSS. Hash `{Mon: ["0900-2200"]}` |
| `restaurant_tags` | `FIND` | 3 | Array of feature/service strings |
| `restaurant_delivers` | `DETERMINE` | 2 | Inferred from tags, delivery badge, or site type |
| `restaurant_delivery_zones` | `FIND` | 3 | Array of `{delivery_zone, minimum_order_value, delivery_fee, currency}` |
| `restaurant_position` | `FROM_VARS` | 2 | Rank passed from listings parser via `vars['rank_in_listing']` |
| `img_url` | `FIND` | 2 | JSON-LD image → og:image → CSS |
| `description` | `FIND` | 3 | JSON-LD description → og:description → CSS |
| `scraped_at_timestamp` | `HARDCODED` | 3 | `Time.parse(page['fetched_at']).strftime('%Y%m%d %H:%M:%S')` |
| `crawled_source` | `HARDCODED` | 3 | Always `'WEB'` |
| `free_field` | `HARDCODED` | 4 | Always `nil` |

### 4.3 Menu items collection fields

| Field | extraction_method | Priority | Notes |
|---|---|---|---|
| `item_id` | `DETERMINE` | 1 | MD5 hash of `restaurant_id + item_name + index` |
| `restaurant_id` | `FROM_VARS` | 1 | `vars['loc_id']` — set by restaurant_details parser |
| `restaurant_name` | `FROM_VARS` | 1 | `vars['restaurant_name']` |
| `restaurant_url` | `FROM_VARS` | 2 | `vars['restaurant_url']` |
| `cuisine` | `FROM_VARS` | 2 | `vars['cuisine']` (main_cuisine from restaurant_details) |
| `category_name` | `FIND` | 2 | Menu section/category heading |
| `item_name` | `FIND` | 1 | Menu item name. Required. |
| `item_description` | `FIND` | 2 | Item description text |
| `item_price` | `FIND` | 1 | Numeric price, stripped of currency symbol |
| `currency` | `INFER` | 2 | 3-letter ISO — inferred from site/country during Phase 1 |
| `item_is_promoted` | `DETERMINE` | 2 | True if under a promo section or marked promoted |
| `img_url` | `FIND` | 3 | Item image (handle lazy-load `data-src`) |
| `is_available` | `FIND` | 2 | False if sold-out marker present |
| `item_attributes` | `FIND` | 3 | JSON string of dietary labels / tags |
| `barcode` | `FIND` | 4 | Usually nil for restaurant menus |
| `sku` | `FIND` | 3 | From data attributes if available |
| `url` | `HARDCODED` | 3 | `page['url']` |
| `scraped_at_timestamp` | `HARDCODED` | 3 | `Time.parse(page['fetched_at']).strftime('%Y%m%d %H:%M:%S')` |
| `crawled_source` | `HARDCODED` | 3 | Always `'WEB'` |
| `free_field` | `HARDCODED` | 4 | Always `nil` |

### 4.4 Boilerplate parser updates

`restaurant_details.rb` output hash updated to use legacy field names, grouped by extraction_method:

```ruby
output = {
  _collection:  "locations",
  _id:          lead_id,

  # HARDCODED / INFER
  date:                  Time.parse(page['fetched_at']).strftime('%Y%m%d %H:%M:%S'),
  url:                   page['url'],
  restaurant_country:    "PLACEHOLDER_COUNTRY_ISO",
  scraped_at_timestamp:  Time.parse(page['fetched_at']).strftime('%Y%m%d %H:%M:%S'),
  crawled_source:        'WEB',
  free_field:            nil,

  # FROM_VARS
  restaurant_position:   page['vars']&.dig('rank_in_listing'),

  # FIND / DETERMINE
  lead_id:               lead_id,
  restaurant_name:       restaurant_name,
  restaurant_address:    restaurant_address,
  restaurant_city:       restaurant_city,
  restaurant_area:       restaurant_area,
  restaurant_post_code:  restaurant_post_code,
  restaurant_lat:        restaurant_lat,
  restaurant_long:       restaurant_long,
  phone_number:          phone_number,
  main_cuisine:          main_cuisine,
  cuisine_name:          cuisine_name,
  restaurant_rating:     restaurant_rating,
  number_of_ratings:     number_of_ratings,
  opening_hours:         opening_hours,
  restaurant_tags:       restaurant_tags,
  restaurant_delivers:   restaurant_delivers,
  restaurant_delivery_zones: restaurant_delivery_zones,
  img_url:               img_url,
  description:           description,
}
```

`menu.rb` updated similarly with `item_name`, `item_description`, `item_price`, `currency`, `item_is_promoted` matching the spec.

`config.yaml` exporters updated to match both schemas exactly.

---

## 5. Implementation Order

| Step | Task | Effort | Risk |
|---|---|---|---|
| 1 | Create `spec_full.json` at repo root | Medium | Low |
| 2 | Update `restaurant_details.rb` — field names + grouping + nil-warn | Medium | Low |
| 3 | Update `menu.rb` — field names + grouping + nil-warn | Small | Low |
| 4 | Update `listings.rb` — minor: ensure `rank_in_listing` var key matches spec | Small | Low |
| 5 | Update `config.yaml` — exporters for both collections | Small | Low |
| 6 | Fill `spec/sample-dhero-spec.md` — usage example and field table | Small | Low |
