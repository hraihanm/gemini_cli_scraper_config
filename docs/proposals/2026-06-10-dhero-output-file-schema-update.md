# Proposal: DHero Output File Schema Update (A1/A2/A3 Division)

**Created:** 2026-06-10
**Status:** Done
**Scope:** `dhero-field-spec.json`, `templates/dhero_boilerplate/config.yaml`, `templates/dhero_boilerplate/parsers/menu.rb`, `templates/dhero_boilerplate/parsers/restaurant_details.rb`, `docs/shared/dhero-output-schema.md`, `spec/sample-dhero-spec.md`

---

## 1. Background

The dhero field spec and boilerplate define all fields output by the restaurant pipeline, but they do not annotate which output file (A1/A2/A3) each field belongs to. The client delivers three output files per scraper:

- **A1** — Restaurant core (standardized): address, contact, rating, cuisine, etc.
- **A2** — Restaurant variable: hours, tags, delivery zones, cuisine list, free_field
- **A3** — Item level: menu items, prices, categories, images

The `config.yaml` exporters implement the split via `excluded_fields`, but several fields were **incorrectly excluded from A1** (`opening_hours`, `restaurant_tags`, `restaurant_delivery_zones`) when the client documentation states they appear in both A1 and A2.

New fields from change requests (`is_permanently_closed` May 2023, `input_lat`/`input_long` Aug 2023 for locations; `original_price` Jun 2023 for items) are also absent from the spec.

Finally, the items collection uses internal field names (`category_name`, `img_url`) that differ from the client output names (`menu_category`, `menu_item_image_url`).

---

## 2. Current State

- `dhero-field-spec.json`: No `output_file` annotation on any field. Missing: `is_permanently_closed`, `input_lat`, `input_long`, `original_price`. Items use `category_name` / `img_url` instead of `menu_category` / `menu_item_image_url`.
- `config.yaml` A1 exporter incorrectly excludes `opening_hours`, `restaurant_tags`, `restaurant_delivery_zones`.
- `config.yaml` A2 exporter does not exclude the new A1-only fields (`is_permanently_closed`, `input_lat`, `input_long`).
- `spec/sample-dhero-spec.md` A1 table stops at A1.16 (`main_cuisine`); missing A1.17 and A1.18.
- `templates/dhero_boilerplate/parsers/menu.rb` outputs `category_name:` and `img_url:` instead of `menu_category:` and `menu_item_image_url:`; lacks `original_price`.
- `templates/dhero_boilerplate/parsers/restaurant_details.rb` lacks `is_permanently_closed`, `input_lat`, `input_long`.

---

## 3. Problems

1. **Wrong A1 contents**: `opening_hours`, `restaurant_tags`, `restaurant_delivery_zones` appear in both A1 and A2 per client spec, but A1 exporter excluded them — A1 files are missing these fields.
2. **Stale items field names**: Parser outputs `category_name` / `img_url`; client pipeline expects `menu_category` / `menu_item_image_url` in A3.
3. **Missing fields**: `is_permanently_closed` (A1), `input_lat`/`input_long` (A1, geo-coord only), `original_price` (A3) are absent from spec and boilerplate.
4. **No `output_file` annotation**: Field spec gives no machine-readable indication of which output file a field belongs to, making agent-driven scraper generation error-prone.

---

## 4. Proposal

### 4.1 `output_file` annotation in field spec

Add `"output_file": [...]` to every field entry in `dhero-field-spec.json`. Values: `"A1"`, `"A2"`, `"A3"`, `"internal"`.

### 4.2 A1/A2/A3 division (authoritative)

| Field | A1 | A2 | A3 |
|---|---|---|---|
| date | ✓ | ✓ | ✓ |
| lead_id | ✓ | ✓ | ✓ |
| url | ✓ | ✓ | ✓ |
| restaurant_name | ✓ | | |
| restaurant_address | ✓ | | |
| restaurant_post_code | ✓ | | |
| restaurant_area | ✓ | | |
| restaurant_lat, restaurant_long | ✓ | | |
| restaurant_city | ✓ | | |
| restaurant_country | ✓ | | |
| restaurant_delivers | ✓ | | |
| phone_number | ✓ | | |
| restaurant_rating | ✓ | | |
| restaurant_position | ✓ | | |
| number_of_ratings | ✓ | | |
| main_cuisine | ✓ | | |
| is_permanently_closed | ✓ | | |
| input_lat, input_long | ✓ | | |
| cuisine_name | | ✓ | |
| opening_hours | ✓ | ✓ | |
| restaurant_tags | ✓ | ✓ | |
| restaurant_delivery_zones | ✓ | ✓ | |
| free_field (restaurant) | | ✓ | |
| item_id | | | ✓ |
| item_name | | | ✓ |
| item_description | | | ✓ |
| item_price | | | ✓ |
| currency | | | ✓ |
| item_is_promoted | | | ✓ |
| menu_category | | | ✓ |
| menu_item_image_url | | | ✓ |
| original_price | | | ✓ |
| free_field (item) | | | ✓ |

### 4.3 New locations fields

| Field | extraction_method | Notes |
|---|---|---|
| `is_permanently_closed` | HARDCODED | Always `false` — client wants only open restaurants; set to `false` unless selector confirmed. Added ~May 2023. |
| `input_lat` | FROM_VARS | Geo-coord input latitude. Only applicable when input list provides coordinates. `vars['input_lat']`. Added Aug 2023. |
| `input_long` | FROM_VARS | Geo-coord input longitude. `vars['input_long']`. Added Aug 2023. |

### 4.4 New items field

| Field | extraction_method | Notes |
|---|---|---|
| `original_price` | FIND | Pre-promotion price. Set when `item_is_promoted` is true. nil otherwise. Added Jun 2023. |

### 4.5 Items field renames

| Old name | New name | Reason |
|---|---|---|
| `category_name` | `menu_category` | Matches client A3 output schema |
| `img_url` (items) | `menu_item_image_url` | Matches client A3 output schema; plural per client spec |

### 4.6 `config.yaml` exporter corrections

A1 exporter — remove from `excluded_fields`:
- `opening_hours`
- `restaurant_tags`
- `restaurant_delivery_zones`

A2 exporter — add to `excluded_fields`:
- `is_permanently_closed`
- `input_lat`
- `input_long`

### 4.7 New knowledge base doc: `docs/shared/dhero-output-schema.md`

Full A1/A2/A3 reference for the dhero pipeline: field tables per file, QA requirements, special cases, history of additions.

---

## 5. Implementation Order

| Step | File | Change | Effort | Risk |
|---|---|---|---|---|
| 1 | `dhero-field-spec.json` | Add `output_file`, rename items fields, add new fields, update counts | Medium | Low |
| 2 | `config.yaml` | Fix A1 exporter, update A2 exporter | Low | Medium (A1 content changes) |
| 3 | `parsers/menu.rb` | Rename fields, add `original_price` | Low | Low |
| 4 | `parsers/restaurant_details.rb` | Add `is_permanently_closed`, `input_lat`, `input_long` | Low | Low |
| 5 | `docs/shared/dhero-output-schema.md` | Create knowledge base doc | Medium | None |
| 6 | `spec/sample-dhero-spec.md` | Add A1.17, A1.18 | Low | None |
