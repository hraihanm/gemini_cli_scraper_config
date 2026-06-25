# DHero Output Schema — A1 / A2 / A3 Field Reference

**version:** 1.0  
**pipeline:** dhero (5-phase: scrape → navigation → restaurant-details → menu-listings → menu-parser)  
**collections:** `locations` (restaurant records) → A1 + A2 exports; `items` (menu items) → A3 export

---

## Overview

Every dhero scraper produces three output files per run:

| File | Collection | Content |
|---|---|---|
| `<name>_A1Restaurants_YYYYMMDD.json.gz` | `locations` | Restaurant core fields (standardized) |
| `<name>_A2Restaurants_YYYYMMDD.json.gz` | `locations` | Restaurant variable fields |
| `<name>_A3Items_YYYYMMDD.json.gz` | `items` | Menu item level fields |

The split is enforced by `config.yaml` exporters via `excluded_fields`. Both A1 and A2 draw from the **same `locations` collection record** — the parser writes all fields in one pass.

---

## A1 — Restaurant Core (Standardized)

Fields shared by all dhero sources. Priority fields (client-designated) marked ★.

| # | Field | Type | Format | QA Rule |
|---|---|---|---|---|
| A1.1 | ★ `date` | string | `YYYYMMDD HH:MM:SS` | `"date":"20191129 14:52:43"` |
| A1.2 | ★ `lead_id` | string (MD5) | 32-char hex | Must not repeat; must match A2 lead_id |
| A1.3 | `url` | string | full URL | Present for web sources; `null` for APP sources |
| A1.4 | ★ `restaurant_name` | string | as-is | Never blank |
| A1.5 | ★ `restaurant_address` | string | street address | `null` if source doesn't have it |
| A1.6 | `restaurant_post_code` | string | postal/zip code | `null` if source doesn't have it |
| A1.7 | `restaurant_area` | string | region/district | `null` if source doesn't have it |
| A1.8 | ★ `restaurant_lat` | float | decimal degrees | `null` if 0 or unavailable |
| A1.8 | ★ `restaurant_long` | float | decimal degrees | `null` if 0 or unavailable |
| A1.9 | ★ `restaurant_city` | string | city name | `null` if source doesn't have it |
| A1.10 | ★ `restaurant_country` | string | ISO 3166 Alpha-2 | Never blank; 2-letter code e.g. `"AE"` |
| A1.11 | `restaurant_delivers` | boolean | `true` / `false` | `false` when source has no delivery option |
| A1.12 | `phone_number` | string | include country code | `null` if source doesn't have it |
| A1.13 | `restaurant_rating` | string/float | as shown on site | `null` if missing; most general rating if multiple |
| A1.14 | `restaurant_position` | integer | 1-based rank | May be empty when not available |
| A1.15 | `number_of_ratings` | integer | count | `null` if missing |
| A1.16 | `main_cuisine` | string | single cuisine | Exactly one value; `null` if not available |
| A1.17 | `is_permanently_closed` | boolean | `true` / `false` / `null` | `false` for all available restaurants. `null` if no suitable selector exists. See note below. |
| A1.18 | `input_lat` | float | decimal degrees | From input list. Only populated for geo-coordinate scrapers. See note below. |
| A1.18 | `input_long` | float | decimal degrees | From input list. Only populated for geo-coordinate scrapers. |
| A1.x | `opening_hours` | hash | `{Mon: ["HHMM-HHMM"]}` | Also in A2. `null` if unavailable. Days closed are omitted. |
| A1.x | `restaurant_tags` | array | `["Delivery", "Parking"]` | Also in A2. `null` if empty. |
| A1.x | `restaurant_delivery_zones` | array of hashes | see A2.7 | Also in A2. `null` if not available. |

### A1 field notes

**`is_permanently_closed` (added ~May 2023):**
- Client is not interested in permanently closed locations — the output should contain `false` for all available restaurants.
- If the site has a closed-indicator element, use it to skip those restaurants during the listings phase.
- Set to `null` only when confirmed during feasibility that no suitable selector exists (post Jun 2023 client update).

**`input_lat` / `input_long` (added Aug 2023):**
- Coordinates from the input list — not scraped from the site.
- Only applicable when the scraper uses a geo-coordinate input list. Confirm during feasibility check.
- Passed via `page['vars']['input_lat']` and `page['vars']['input_long']`.

**`opening_hours`, `restaurant_tags`, `restaurant_delivery_zones`:**
- These three fields appear in **both A1 and A2**. They are not excluded from the A1 exporter.

---

## A2 — Restaurant Variable Fields

Shares `date`, `lead_id`, and `url` with A1. All other A2 fields are excluded from A1.

| # | Field | Type | Format | QA Rule |
|---|---|---|---|---|
| A2.1 | `date` | string | `YYYYMMDD HH:MM:SS` | Same as A1 |
| A2.2 | `lead_id` | string (MD5) | 32-char hex | Must match A1 lead_id |
| A2.3 | `url` | string | full URL | Same as A1 |
| A2.4 | `cuisine_name` | hash | `{cuisine1: "Pizza", cuisine2: "Burger"}` | All cuisines; `{}` if none found |
| A2.5 | `opening_hours` | hash | `{Sun: ["1000-2200"], Mon: ["0800-1130", "1600-2330"]}` | Also in A1. `null` if unavailable. |
| A2.6 | `restaurant_tags` | array | `["Burger", "Online payment"]` | Also in A1. `null` if empty. |
| A2.7 | `restaurant_delivery_zones` | array of hashes | `[{delivery_zone, minimum_order_value, delivery_fee, currency}]` | Also in A1. `null` if not available. Internal keys null if missing. |
| A2.8 | `free_field` | hash | varies | `null` unless client requests extra fields. Internal keys `null` if missing. |

---

## A3 — Item Level (Menu Items)

One record per menu item. `lead_id` repeats for all items from the same restaurant.

| # | Field | Type | Format | QA Rule |
|---|---|---|---|---|
| A3.1 | `date` | string | `YYYYMMDD HH:MM:SS` | Same format as A1/A2 |
| A3.2 | `lead_id` | string (MD5) | 32-char hex | Matches restaurant's lead_id in A1/A2; repeats per item |
| A3.3 | `url` | string | full URL | `null` for APP sources |
| A3.4 | `item_id` | string (MD5) | 32-char hex | Never null; must not repeat |
| A3.5 | `item_name` | string | as-is | Never null |
| A3.6 | `item_description` | string | as-is | `null` if not available |
| A3.7 | `item_price` | float | numeric, no symbol | Current price (discounted when promoted). `null` if 0 or unparseable — not `"0"`. Watch decimal formats in SA/French sources. |
| A3.8 | `currency` | string | ISO 4217 (3-letter) | Never null; e.g. `"AED"`, `"USD"`, `"BDT"` |
| A3.9 | `item_is_promoted` | boolean | `true` / `false` | `false` when no promotion info. Never null. |
| A3.10 | `menu_category` | string | as-is | Category heading. `null` if not available. Added Sep 2022. |
| A3.11 | `menu_item_image_url` | string | full URL | Item image URL. Check `src` and `data-src`. `null` if not available. Added Sep 2022. |
| A3.12 | `original_price` | float | numeric, no symbol | Pre-promotion price. Populated only when `item_is_promoted=true` and original price is shown. `null` otherwise. Must always be present in output hash. Added Jun 2023. |
| A3.13 | `free_field` | hash | varies | `null` unless client requests extra item fields. |

### A3 field notes

**`menu_category` and `menu_item_image_url`:**
- Required for all new dhero sources (from Oct 2022 onwards) and retroactively added to a specific set of prior sources via change request.
- Confirm in the client external sheet whether `menu_category` / `menu_item_image_url` apply to the current source.
- `menu_category` is sourced from `page['vars']['category_name']` (set by `menu_listings.rb`) or discovered from page CSS if nil.
- `menu_item_image_url` uses `src` first, `data-src` fallback for lazy-loaded images.

**`item_price` vs `original_price`:**
- When `item_is_promoted=true`: `item_price` = current (discounted) price; `original_price` = pre-promotion price.
- When `item_is_promoted=false`: `item_price` = normal price; `original_price` = `null`.

---

## Field Scope Summary

| Field | A1 | A2 | A3 |
|---|---|---|---|
| `date` | ✓ | ✓ | ✓ |
| `lead_id` | ✓ | ✓ | ✓ |
| `url` | ✓ | ✓ | ✓ |
| `restaurant_name` | ✓ | | |
| `restaurant_address` | ✓ | | |
| `restaurant_post_code` | ✓ | | |
| `restaurant_area` | ✓ | | |
| `restaurant_lat` | ✓ | | |
| `restaurant_long` | ✓ | | |
| `restaurant_city` | ✓ | | |
| `restaurant_country` | ✓ | | |
| `restaurant_delivers` | ✓ | | |
| `phone_number` | ✓ | | |
| `restaurant_rating` | ✓ | | |
| `restaurant_position` | ✓ | | |
| `number_of_ratings` | ✓ | | |
| `main_cuisine` | ✓ | | |
| `is_permanently_closed` | ✓ | | |
| `input_lat` | ✓ | | |
| `input_long` | ✓ | | |
| `opening_hours` | ✓ | ✓ | |
| `restaurant_tags` | ✓ | ✓ | |
| `restaurant_delivery_zones` | ✓ | ✓ | |
| `cuisine_name` | | ✓ | |
| `free_field` (restaurant) | | ✓ | |
| `item_id` | | | ✓ |
| `item_name` | | | ✓ |
| `item_description` | | | ✓ |
| `item_price` | | | ✓ |
| `currency` | | | ✓ |
| `item_is_promoted` | | | ✓ |
| `original_price` | | | ✓ |
| `menu_category` | | | ✓ |
| `menu_item_image_url` | | | ✓ |
| `free_field` (item) | | | ✓ |

---

## Internal / Pipeline-Only Fields

These fields exist in the DataHen collections for internal use but are excluded from all client exports:

| Field | Collection | Purpose |
|---|---|---|
| `crawled_source` | both | Always `'WEB'` — DataHen tracking |
| `img_url` | locations | Restaurant hero image — internal |
| `description` | locations | Restaurant description — internal |
| `restaurant_id` | items | Same as lead_id — used for item_id computation |
| `restaurant_name` (items) | items | Passed via vars for context |
| `restaurant_url` | items | Passed via vars for context |
| `cuisine` | items | Passed via vars for context |
| `is_available` | items | Sold-out status — internal |
| `item_attributes` | items | Dietary labels — internal |
| `barcode` | items | Usually null for restaurant menus |
| `sku` | items | data-item-id / data-id — internal |

---

## Source-Specific Extras

Some dhero sources have additional fields not in the standard A1/A2/A3 schema. These are defined per-source and placed in `free_field` or as extra A2 fields.

| Frequency | Source | File | Extra Field(s) |
|---|---|---|---|
| Daily | JAHEZ - Saudi Arabia | Only file | `minimum_prime_order_value` |
| Biweekly | GETIR - Turkey | A2 | `delivery_type` |
| Biweekly | BRINGO - Romania | A2 | `menu_total` |

---

## Config Exporter Wiring

The `config.yaml` A1 exporter excludes: `cuisine_name`, `img_url`, `description`, `free_field`, `crawled_source`.

The `config.yaml` A2 exporter excludes: all A1-only fields + `is_permanently_closed`, `input_lat`, `input_long`, `img_url`, `description`, `crawled_source`.

`opening_hours`, `restaurant_tags`, `restaurant_delivery_zones` are **not excluded from either** exporter — they appear in both A1 and A2.

See `templates/dhero_boilerplate/config.yaml` for the canonical `excluded_fields` lists.

---

## Related Docs

- `docs/shared/datahen-conventions.md` — Parser structure, state file logging, `_log` schema
- `docs/shared/datahen-ruby-parsers.md` — Pre-loaded gems, error handling, vars passing
- `dhero-field-spec.json` — Canonical field spec with `output_file` annotations and `extraction_method` classifications
- `docs/workflows/phases/03-restaurant-details.md` — Phase 3 step-by-step (locations extraction)
- `docs/workflows/phases/05-menu-details.md` — Phase 5 step-by-step (items extraction)
