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
| `failed_content` | String | Body of a **failed** HTTP response (non-2xx). Check `page['failed_response_status_code']` first. |

### Key `page` hash fields

| Key | Type | Purpose |
|---|---|---|
| `page['url']` | String | Original URL as queued — may differ from final URL after redirects |
| `page['effective_url']` | String | **Actual URL after redirects** — use for ID extraction when site redirects |
| `page['vars']` | Hash | Context forwarded from prior parsers (`page['vars']['category_name']`, etc.) |
| `page['fetched_at']` | String | ISO timestamp when DataHen fetched the page — use for `scraped_at_timestamp`, never `Time.now` |
| `page['response_status_code']` | Integer | HTTP status of a successful response |
| `page['failed_response_status_code']` | Integer | HTTP status of a failed response (nil when successful) |
| `page['refetch_count']` | Integer | How many times DataHen has retried this page |

```ruby
# ALWAYS use effective_url when extracting IDs from URL (site may redirect)
uid = page['url'].scan(/-d(\d+)-/).first&.first
uid ||= page['effective_url']&.scan(/-d(\d+)-/)&.first&.first

# ALWAYS use fetched_at for scraped_at_timestamp — never Time.now
scraped_at_timestamp: Time.parse(page['fetched_at']).strftime('%Y-%m-%d %H:%M:%S')
```

---

## Ruby Version Compatibility

DataHen workers run **Ruby 2.6.5**. All parser and lib files must be Ruby 2.6 compatible.

DataHen workers default to **Ruby 2.6.5** when no `.ruby-version` is present. Do **not** add a `.ruby-version` file unless you need to select a different supported version. Supported versions: `2.4.4, 2.4.9, 2.5.3, 2.5.7, 2.6.5, 2.7.2, 3.0.1`.

**Forbidden Ruby 3+ syntax** — do NOT use in any parser or lib file:
```ruby
# ❌ Endless method (Ruby 3.0+) — syntax error on 2.6.5
def autorefetch(reason = nil) = autorecovery(reason: reason)

# ✅ Use standard def/end instead
def autorefetch(reason = nil)
  autorecovery(reason: reason)
end
```

Other Ruby 3+ features to avoid: numbered block params (`_1`, `_2`), pattern matching (`in` keyword), `Hash#except`.

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

## Response Status Handling — `finish` after `limbo` is mandatory

```ruby
# Check status at top of every parser that could receive failed pages
unless page['response_status_code'] == 200
  autorefetch("HTTP #{page['response_status_code']} on #{page['url']}")
  finish   # ← REQUIRED: finish stops parser execution after limbo/refetch
end

# For structured error responses, read failed_content
if page['failed_response_status_code']
  if (failed_content || '').include?('ProductNotFoundError')
    outputs << { _collection: 'products_not_found', url: page['url'] }
  end
  finish
end
```

**`finish` is mandatory after `limbo` or `refetch`.** Without it, the parser continues executing on the failed content.

### `autorefetch` helper — standard pattern

```ruby
def autorefetch(reason)
  puts "AUTO-REFETCH: #{reason}" if ENV['debug']
  if page['refetch_count'].to_i > 3
    limbo page['gid']
  else
    refetch page['gid']
  end
  finish
end
```

Put this in `lib/helpers.rb` and `require './lib/helpers'` in each parser. The threshold `> 3` (4 attempts total) is the production standard seen across all surveyed projects. `limbo` puts the page in a limbo state for manual review; `refetch` re-queues it for another fetch attempt.

---

## Priority tuning — standard convention

Set `priority:` on every `pages <<` entry. DataHen processes higher-priority pages first.
**Always assign priority at queue time** — it cannot be changed after queuing.

| Page type | Priority |
|---|---|
| OAuth / token pages | 1000 |
| Seeder initial pages | 900 |
| Categories | 800 |
| Subcategories | 700 |
| Listings page 1 | 600 |
| Listings page 2+ | 500 |
| Restaurant details / product details | 100 |
| Menu listings | 80 |
| Menu details | 50 |

---

## `needs_reparse` — deduplication-safe re-run trick

DataHen deduplicates `outputs` by comparing all field values. A re-parse that produces identical
output is silently dropped. To force the output through, add 1 second to `scraped_at_timestamp`:

```ruby
scraped_at_timestamp: if ENV['needs_reparse'] == '1'
  (Time.parse(page['fetched_at']) + 1).strftime('%Y-%m-%d %H:%M:%S')
else
  Time.parse(page['fetched_at']).strftime('%Y-%m-%d %H:%M:%S')
end
```

---

## `raise` for fatal nil fields

Use `raise` (not `warn`) when a field is so critical that proceeding without it would corrupt the dataset:

```ruby
raise "empty product_id on #{page['url']}" if product_id.nil? || product_id.empty?
raise "availability nil on #{page['url']}"  if is_available.nil?
```

DataHen catches the exception, marks the page as failed, and surfaces it for manual review.
`warn` is for non-fatal data gaps (optional fields). `raise` is for fields that must exist.

---

## Page options reference

```ruby
pages << {
  url:                url,
  page_type:          'details',
  fetch_type:         'standard',   # raw JSON APIs — never 'browser' for APIs
  method:             'POST',        # default GET
  body:               { id: 123 }.to_json,
  headers:            { 'Accept' => 'application/json' },
  http2:              true,          # API performance — always set for API pages
  custom_headers:     true,          # use ONLY the headers above, not DataHen defaults
  no_default_headers: true,          # suppress DataHen's UA/Accept defaults
  freshness:          Time.now.utc.strftime('%FT%TZ'),  # force re-fetch even if cached
  priority:           100,
  no_url_encode:      true,          # prevents double-encoding pre-encoded URLs
  driver:             { name: "details_#{vars['id']}" },  # unique name avoids browser cache
  vars:               { 'id' => id }
}
```

**Driver name uniqueness:** DataHen caches browser sessions by driver name. Give retry pages a unique driver name so they get fresh sessions:
```ruby
driver: { name: "retry_#{page['refetch_count']}_#{page['url'].hash.abs}" }
```

---

## Browser Fetch (`fetch_type: "browser"`)

When any page uses `fetch_type: "browser"`, the scraper needs a browser fetcher image. Add this to `config.yaml` at the top level:

```yaml
browser_fetcher_image: gcr.io/answers-engine-cloud/fetch-browser-chrome1
```

Without this line the job will fail to fetch browser pages. The dmart/greenfield/dhero boilerplate `config.yaml` files have this line commented out — uncomment it whenever you add a `fetch_type: "browser"` page.

### Driver code constraints — Puppeteer, not Playwright

DataHen's browser driver runs on **Puppeteer** (via Browserless). Playwright pseudo-selectors are **not valid** in driver code.

**Forbidden** (Playwright-only, crashes on DataHen):
```javascript
// ❌ :has-text() is Playwright syntax — Puppeteer throws DOMException
await page.click('nav button:has-text("Kategóriák")');
await page.$('span:text("Add to cart")');
```

**Use XPath or evaluate instead:**
```javascript
// ✅ XPath — supported by Puppeteer's page.$x()
const [btn] = await page.$x('//nav//button[contains(., "Kategóriák")]');
if (btn) { await btn.click(); }
await sleep(2000);

// ✅ evaluate — use querySelectorAll + text filter
await page.evaluate(() => {
  const btn = [...document.querySelectorAll('nav button')]
    .find(b => b.textContent.includes('Kategóriák'));
  if (btn) btn.click();
});
await sleep(2000);
```

Other Playwright-specific APIs that don't work: `:text()`, `locator()`, `getByRole()`, `waitForLoadState('networkidle')` (use `waitUntil: 'networkidle0'` in `goto_options` instead).

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
