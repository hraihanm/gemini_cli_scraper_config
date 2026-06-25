# DataHen Ruby parser patterns (extended)

**version:** 1.0.0

For top-level script rules and reserved variables, see **`docs/shared/datahen-conventions.md`** (canonical). This file adds operational patterns from the former long `system.md`.

## Preloaded libraries

DataHen v3 pre-loads the following gems in every parser runtime — **never add `require` for them**:

- `nokogiri` — HTML parsing
- `json` — JSON encode/decode
- `digest` — MD5/SHA hashing
- `cgi` — CGI utilities

Still require explicitly:
- `chronic` — natural-language date parsing
- `./lib/headers` — project-specific request headers
- `./lib/helpers` — project-specific helper methods

## URL construction — avoid `addressable`

Do not use `require 'addressable'` or `Addressable::URI.join`. Simple string interpolation is sufficient and keeps the parser dependency-free:

```ruby
# Relative → absolute URL
url = href.start_with?('http') ? href : "#{base_url}#{href}"
```

`base_url` (from `URLs::BASE_URL`) has no trailing slash; hrefs from restaurant/menu sites are clean `/path` strings. This covers all dhero use cases without a gem dependency.

## Error handling

Wrap CSS extraction in `begin/rescue`; use safe navigation `&.text&.strip`; log meaningful messages with `puts` during development.

## Memory

In production parsers: `save_pages if pages.count > 99` and `save_outputs if outputs.count > 99` — server-side flush, not for quick local `parser_tester` loops.

## Variable passing

Preserve `vars` across `pages <<` (merge prior `page['vars']` into new entries). Pass `category_name`, breadcrumbs, rank, and page context into detail jobs as required by the field spec.

## Collection switching — validity routing

Route invalid, out-of-scope, or error records to a side collection instead of the main one.
This preserves visibility without polluting the primary dataset.

```ruby
# Permanently closed → side collection
if is_permanently_closed
  location[:_collection] = 'locations_permanently_closed'
  outputs << location
  finish
end

# Outside target country / city
collection = target_cities.include?(city) ? 'locations' : 'locations_outside_scope'
outputs << location.merge(_collection: collection)

# Product not found
if page['response_status_code'] == 404
  outputs << { _collection: 'products_not_found', url: page['url'] }
  finish
end
```

Side collections are queryable in DataHen and invaluable for QA.

---

## Helper patterns — universal, put in `lib/helpers.rb`

```ruby
# Normalize nil/empty/sentinel strings to nil
def empty_to_nil(str)
  str = str.to_s.strip
  return nil if str.empty? || str == '{}' || str == '[]' || str == '.'
  str
end

# Normalize relative or CDN image URLs to absolute
def fix_image_url(url, base_url: 'https://example.com')
  return nil if url.nil? || url.strip.empty?
  return url if url.start_with?('http')
  "#{base_url}#{url}"
end

# Strip HTML tags from description fields while preserving structure
def clean_html_description(html_str)
  return nil if html_str.nil?
  text = html_str
    .gsub('&nbsp;', ' ').gsub('&ndash;', '-').gsub('&amp;', '&')
    .gsub(/<h[1-6][^>]*>(.*?)<\/h[1-6]>/m) { "\n#{$1.strip}\n" }
    .gsub(/<li[^>]*>(.*?)<\/li>/m)          { "• #{$1.strip}\n" }
    .gsub(/<br\s*\/?>/i, "\n")
    .gsub(/<[^>]+>/, '')
    .gsub(/\n{3,}/, "\n\n")
    .strip
  text.empty? ? nil : text
end
```

---

## JSON extraction from `<script>` tags

### JSON-LD (typed schema)
```ruby
json_ld = html.css('script[type="application/ld+json"]').lazy.filter_map { |s|
  JSON.parse(s.text) rescue nil
}.find { |j| j['@type'] == 'Product' || j['@type'] == 'FoodEstablishment' }
```

### Embedded JS state (`window.__INITIAL_STATE__`)
```ruby
script = html.css('script').detect { |s| s.text.include?('window.__INITIAL_STATE__=') }
if script
  json_str = script.text.strip
    .sub(/^window\.__INITIAL_STATE__=/, '')
    .sub(/;.*$/, '')   # strip trailing JS
  state = JSON.parse(json_str) rescue nil
end
```

### JSON in script `src` attribute (URL-encoded)
```ruby
script_src = html.at_css('body > script[src]')&.[]('src')
if script_src&.include?('{')
  decoded = CGI.unescape(script_src)
  json_str = decoded.scan(/JSON\.parse\("({.+})"\)/).flatten.first
    &.gsub('\\"', '"')
  data = JSON.parse(json_str) rescue nil
end
```

---

## Full-product-hash enrichment pattern (listings → details)

When listings already have most fields, pass the partial hash in `vars` so the details
parser only fetches what's missing (description, images, etc.) — avoids redundant extraction:

```ruby
# listings.rb — build partial hash, pass in vars
product_stub = {
  '_collection'          => 'products',
  '_id'                  => product_id,
  'name'                 => name,
  'customer_price_lc'    => price,
  'competitor_product_id'=> product_id,
  # ... all fields extractable from listing ...
}
pages << { url: detail_url, page_type: 'details', vars: { 'product' => product_stub } }

# details.rb — merge missing fields
product = page['vars']['product'] || {}
product['description'] = html.at_css('.desc')&.text&.strip
product['img_url']     ||= html.at_css('.img img')&.[]('src')
outputs << product
```

---

## URL encoding for accented characters in paths

```ruby
product_url = raw_url.gsub(/[^[:ascii:]]/) { |c|
  c.force_encoding('utf-8').bytes.map { |b| "%%%02X" % b }.join
}
```

---

## Variant queuing (Shopify-style products)

When a product has variants, queue one page per variant on first visit; extract only the
targeted variant on the return visit:

```ruby
# First visit — no variant_index in vars
if vars['variant_index'].nil?
  variants.each_with_index do |v, idx|
    next unless v['available']
    pages << {
      url: "#{page['url']}?variant=#{v['id']}",
      page_type: 'details',
      vars: vars.merge('variant_index' => idx, 'variant_id' => v['id'])
    }
  end
  finish
end
# Return visit — extract only vars['variant_index'] variant
variant = variants[vars['variant_index'].to_i]
```

---

## Code generation safety

- Validate Ruby before saving.
- Comment non-obvious selectors and site quirks.
- Never declare `pages`, `outputs`, `page`, or `content`.
