# DataHen V3 Parser Conventions

**version:** 2.0.0

This file defines the mandatory conventions for all DataHen V3 parser files. These apply to every parser written by any phase command.

---

## Parser Structure: Top-Level Scripts

🚨 **CRITICAL: DataHen v3 Parser Structure**:
- **DataHen parsers are TOP-LEVEL SCRIPTS, NOT FUNCTIONS**
- **NEVER** use `def parse(...)` or any function definition in parser files
- **NEVER** wrap parser code in functions - DataHen executes parser files directly as scripts
- **ALWAYS** start parser code directly with `html = Nokogiri::HTML(content)` - no function wrapper
- **Pre-defined variables** available at script level: `content`, `page`, `pages`, `outputs`
- **Why**: DataHen loads and executes parser files as Ruby scripts, not as function calls

### Forbidden patterns
```ruby
# ❌ NEVER do this
def parse(content, page, pages, outputs)
  html = Nokogiri::HTML(content)
end

# ❌ NEVER do this
pages = []
outputs = []

# ❌ NEVER do this
page = ...
content = ...
```

### Required pattern
```ruby
# ✅ ALWAYS start like this
html = Nokogiri::HTML(content)

# ✅ ALWAYS use pre-defined variables directly
pages << { url: next_url, page_type: "listings" }
outputs << { name: "Product", price: 9.99 }
```

---

## Reserved Variables (pre-defined by DataHen runtime)

| Variable | Type | Purpose |
|---|---|---|
| `content` | String | Raw HTML/JSON/XML content of the fetched page |
| `page` | Hash | Metadata about the current page (url, vars, page_type, etc.) |
| `pages` | Array | Queue pages to fetch next — use `pages <<` to add |
| `outputs` | Array | Data to save — use `outputs <<` to add |

---

## Required Gems

```ruby
require 'nokogiri'     # HTML parsing (always available)
require 'addressable'  # URL construction and normalization
require 'chronic'      # Natural language date parsing
require 'json'         # JSON parsing (for JSON-LD, embedded JSON)
```

---

## Pagination (Navigation Parsers)

```ruby
# Strategy 1: Count-based (TOP PRIORITY)
total_products = count_text.match(/(\d[\d,]*)/)[1].gsub(',', '').to_i
total_pages    = (total_products.to_f / products_per_page).ceil
(1..total_pages).each do |page_num|
  pages << {
    url: "#{base_url}?page=#{page_num}",
    page_type: "listings",
    vars: { category_name: category_name, page_number: page_num }
  }
end

# Strategy 2: Next-button fallback
next_link = html.at_css('.next-page')
if next_link
  pages << { url: next_link['href'], page_type: "listings" }
end
```

---

## Output Hash Rules

🚨 **MANDATORY: ALL 53 FIELDS MUST APPEAR IN THE OUTPUT HASH**
- Every field in field-spec.json MUST have an entry in the `outputs <<` hash
- Fields not found on the page MUST be set to `nil` explicitly — NEVER omit them
- Canonical field names: `currency_code_lc`, `rank_in_listing`, `scraped_at_timestamp`, `crawled_source: 'WEB'`

### Required validation block (before `outputs <<`)

```ruby
# Validation: warn on nil required fields
warn "WARN: name is nil for #{page[:url]}"          if name.nil?
warn "WARN: price is nil for #{page[:url]}"         if customer_price_lc.nil?
warn "WARN: img_url is nil for #{page[:url]}"       if img_url.nil?
```

---

## Agent Decision Log (`_log`)

Every state file that carries `_notes` MUST also include a top-level `_log` array. Each element records one key decision or observation, enabling post-mortem diagnosis without re-running the phase.

### Entry schema

```json
{ "step": "5",         "action": "json_ld_probe",       "result": "found",   "detail": "Product — fields: name, price, brand, description, img_url" }
{ "step": "6.pricing", "action": "selector_verify",     "selector": ".price-tag", "result": "matched", "sample": "€12.99" }
{ "step": "9",         "action": "parser_test",         "url": "https://…/product/123", "nil_rate": "2/53", "fields_nil": ["brand", "sub_category"] }
{ "step": "6.pricing", "action": "structural_error",    "detail": "Selector .price-tag — 0 matches on 3 pages" }
{ "step": "5.3",       "action": "pagination_strategy", "strategy": "count_based", "detail": "count selector .result-count, 240 products, 10/page → 24 pages" }
{ "step": "5.3",       "action": "fallback",            "from": "count_based", "to": "next_button", "reason": "count selector returned nil on category B" }
```

### Required entry points

| Trigger | `action` value | Required fields |
|---|---|---|
| JSON-LD probe | `json_ld_probe` | `result` (found/not_found), `detail` (type + fields list) |
| Each selector confirmed | `selector_verify` | `selector`, `result` (matched/failed), `sample` |
| Each `parser_tester` run | `parser_test` | `url`, `nil_rate` ("X/53"), `fields_nil` (array) |
| Pagination strategy chosen | `pagination_strategy` | `strategy`, `detail` |
| Fallback path taken | `fallback` | `from`, `to`, `reason` |
| Structural failure (stop condition) | `structural_error` | `detail` (what failed, how many pages tested) |

Keep entries **terse** — one object per decision. `_notes` is for human narrative; `_log` is for structured, scannable events.

---

## Page GID and URL Deduplication

🚨 **CRITICAL: DataHen deduplicates pages by URL only.**

GID = `MD5(url)`. The `page_type` field does **not** affect the GID.

**Consequence:** queuing the same URL with a different `page_type` does nothing — DataHen sees it as the same page and silently ignores the second queue entry. The page will not be re-fetched.

```ruby
# ❌ WRONG — second queue is ignored; same URL = same GID
pages << { url: page['url'], page_type: 'restaurant_details', ... }
pages << { url: page['url'], page_type: 'menu_listings', ... }  # silent no-op

# ✅ CORRECT — different URL = different GID
pages << { url: page['url'],          page_type: 'restaurant_details', ... }
pages << { url: page['url'] + '/menu', page_type: 'menu_listings', ... }
```

**When the data you need is already on the current page** (same URL), extract it inline in the same parser — do not queue the URL again. This is Strategy E (listings-only) applied at the parser level.

```ruby
# ✅ CORRECT — extract from current page's content directly, no re-queue
html = Nokogiri::HTML(content)
# ... extract location fields ...
outputs << { _collection: 'locations', ... }
# ... also extract menu items from the same content ...
outputs << { _collection: 'items', ... }
# No pages << needed
```

---

## save_pages / save_outputs Threshold

```ruby
# When arrays exceed 99 items, flush immediately
if pages.length > 99
  save_pages(pages)
  pages = []
end

if outputs.length > 99
  save_outputs(outputs)
  outputs = []
end
```

---

## Struct Fields: Special JSON-String Format

Five fields use a special single-quoted string-value JSON format:
`promo_attributes`, `reviews`, `store_reviews`, `item_attributes`, `item_identifiers`

**Rule**: wrap string values in single-quotes; use empty string `""` for missing (NEVER `"''"`)

```ruby
# promo_attributes
promo_attributes = promo_list.any? ?
  JSON.generate({ 'promo_detail' => promo_list.map { |v| "'#{v}'" }.join(', ') }) : nil

# reviews
reviews = (total_reviews_text || avg_rating_text) ?
  JSON.generate({
    'num_total_reviews' => total_reviews_text&.to_i,
    'avg_rating'        => avg_rating_text&.to_f
  }) : nil

# item_attributes
item_attributes = (tags.any? || dietary.any?) ?
  JSON.generate({
    'tags'               => tags.any?    ? tags.map    { |t| "'#{t}'" }.join(', ') : '',
    'dietary attributes' => dietary.any? ? dietary.map { |d| "'#{d}'" }.join(', ') : ''
  }) : nil
```

---

## Field Extraction Priority Order (Details Parser)

When writing field extraction code, try in this order:

1. **JSON-LD** (`<script type="application/ld+json">` with `@type: Product`) — most reliable across redesigns
2. **Meta tags** (`og:title`, `og:image`, `og:description`) — reliable fallback for key fields
3. **CSS selectors** — site-specific, discovered via browser tools

```ruby
# 1. JSON-LD
json_ld = html.css('script[type="application/ld+json"]').lazy.map { |s|
  begin
    parsed = JSON.parse(s.text)
    parsed.is_a?(Hash) && parsed['@graph'].is_a?(Array) ?
      parsed['@graph'].find { |i| i['@type'] == 'Product' } :
      (parsed['@type'] == 'Product' ? parsed : nil)
  rescue JSON::ParserError; nil end
}.find(&:itself)

name        = json_ld&.dig('name')&.strip
description = json_ld&.dig('description')&.strip
img_url     = json_ld&.dig('image').then { |i| i.is_a?(Array) ? i[0] : i }

# 2. Meta tag fallbacks
og_image = html.at_css('meta[property="og:image"]')&.[]('content')
og_title = html.at_css('meta[property="og:title"]')&.[]('content')&.strip
img_url  ||= og_image
name     ||= og_title

# 3. CSS selector fallbacks
name    ||= html.at_css('.product-title')&.text&.strip
img_url ||= html.at_css('.product-image img')&.[]('src')
```

---

## Testing Parsers

**ALWAYS** test parsers via `parser_tester` MCP tool — `hen parser try` is not available.

```javascript
parser_tester({
  scraper_dir: "<absolute_path>/generated_scraper/<scraper>",
  parser_path: "parsers/details.rb",
  page_type: "details",
  auto_download: true,   // uses active browser tab — no manual download needed
  vars: '{"category_name":"Electronics","rank":1}',
  quiet: false           // verbose during development; true for routine validation
})
```

- Test against **3 sample pages** before marking a field as verified
- Use `quiet: true` for routine validation, `quiet: false` when debugging
