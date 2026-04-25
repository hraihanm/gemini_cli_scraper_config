# Output Hash Rules

**version:** 2.0.0

All details parsers MUST emit an output hash with all 53 fields. This file defines the rules.

---

## Golden Rule

**All 53 fields in field-spec.json MUST appear in the output hash.**
- Fields that cannot be extracted MUST be set to `nil` explicitly
- NEVER omit a field — a missing key is treated as an error

---

## Canonical Field Names

| Field | Canonical name |
|---|---|
| Currency | `currency_code_lc` |
| Rank | `rank_in_listing` |
| Scrape time | `scraped_at_timestamp` |
| Source | `crawled_source: 'WEB'` |

---

## Validation Block (required before outputs <<)

```ruby
warn "WARN: name is nil for #{page[:url]}"             if name.nil?
warn "WARN: customer_price_lc is nil for #{page[:url]}" if customer_price_lc.nil?
warn "WARN: img_url is nil for #{page[:url]}"           if img_url.nil?
```

---

## Complete Output Hash Template

```ruby
outputs << {
  # Identity
  name:                   name,
  sku:                    sku,
  barcode:                barcode,
  brand:                  brand,
  product_type:           product_type,
  category:               category,

  # Pricing
  customer_price_lc:      customer_price_lc,
  base_price_lc:          base_price_lc,
  currency_code_lc:       currency_code_lc,
  has_discount:           has_discount,
  discount_pct:           discount_pct,
  type_of_promotion:      type_of_promotion,
  is_promoted:            is_promoted,
  promo_attributes:       promo_attributes,

  # Images
  img_url:                img_url,
  img_url_2:              img_url_2,
  img_url_3:              img_url_3,
  img_url_4:              img_url_4,

  # Availability
  is_available:           is_available,
  availability_status:    availability_status,
  stock_count:            stock_count,

  # Description
  description:            description,
  short_description:      short_description,

  # Attributes
  item_attributes:        item_attributes,
  item_identifiers:       item_identifiers,
  allergens:              allergens,
  nutrition_facts:        nutrition_facts,
  ingredients:            ingredients,
  dimensions:             dimensions,

  # Reviews
  reviews:                reviews,
  store_reviews:          store_reviews,

  # Navigation context
  rank_in_listing:        rank_in_listing,
  page_number:            page_number,
  listing_position:       listing_position,
  category_name:          category_name,
  breadcrumb:             breadcrumb,

  # Meta
  scraped_at_timestamp:   scraped_at_timestamp,
  crawled_source:         'WEB',
  url:                    page[:url],

  # Additional (project-specific — nil if not applicable)
  weight:                 weight,
  unit_of_measure:        unit_of_measure,
  pack_size:              pack_size,
  country_of_origin:      country_of_origin,
  seller_name:            seller_name,
  seller_rating:          seller_rating,
  delivery_time:          delivery_time,
  is_new:                 is_new,
  is_exclusive:           is_exclusive,
  collection:             collection,
  additional_images:      additional_images,
  raw_price_text:         raw_price_text,
}
```

---

## DMART vs DLOC Scope

- **DLOC scrapers**: include all 53 fields
- **DMART scrapers**: only fields 1–42 — set `allergens`, `nutrition_facts`, `ingredients`, `dimensions`, `img_url_2/3/4` to `nil`

Check the scraper name or `config.yaml` — "dloc" in the name/project means DLOC.

---

## Listings-Only Mode (API scrapers)

When the listings API returns a "maximal" payload (`fieldset=maximal` or equivalent) that contains all required product fields, the details parser phase is skipped. In this case the **listings parser becomes the final output emitter** and the full 53-field rule still applies.

**Rules:**
- All 53 fields MUST appear in the listings parser output hash in canonical order
- Fields the listings API does not provide MUST be set to `nil` — never omit them
- Field order must match the template above (same as a details parser) — this is for human readability when reviewing outputs side-by-side across scrapers
- `config.yaml` must have the details parser entry set to `disabled: true`
- `navigation-selectors.json` must record `"details_parser_needed": false`

The nil-field discipline matters: DataHen exports produce CSV/JSON with consistent column counts. A missing key causes schema drift that breaks downstream pipelines even when the value would have been nil anyway.
