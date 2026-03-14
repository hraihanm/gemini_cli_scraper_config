# Proposal: HTML and API Scraping Improvements

**Created:** 2026-03-14
**Status:** Done
**Scope:** `.gemini/commands/dmart-details-parser.toml`, `.gemini/commands/dmart-api-scrape.toml`, `.gemini/commands/dmart-api-navigation-parser.toml`, `.gemini/commands/dmart-api-details-parser.toml`, `CLAUDE.md`

**Architecture decision:** Improvements live in TOML agent instructions, NOT in boilerplate templates. Templates remain clean PLACEHOLDER skeletons. TOMLs tell the AI agent what to check and what code to generate.

## 1. Background

After analyzing production scrapers and the current boilerplate, several recurring failure modes were identified in both HTML and API scraping. These improvements harden the boilerplate against the most common breakage patterns.

## 2. Current State

- `helpers.rb:27` — `number_from()` strips everything except digits and `.`, which silently misparses European prices (e.g., "1.299,00" → 1.299 instead of 1299.0)
- `details.rb:55` — Each field has exactly one CSS selector; when it fails (site redesign, A/B test), the field returns nil silently
- `details.rb:187` — Image extraction does not use `og:image` meta tag as fallback
- `details.rb` — No JSON-LD extraction; sites that embed schema.org Product data are parsed via brittle CSS instead
- `dmart-api-scrape.toml:143` — GraphQL endpoints not detected; only REST JSON documented
- `dmart-api-scrape.toml:120` — Bearer token / Authorization header capture not in workflow
- `dmart-api-navigation-parser.toml:271` — Only offset/page-number pagination documented; cursor-based not supported
- `dmart-api-navigation-parser.toml` — No deduplication for listings that may return overlapping products

## 3. Problem(s)

1. **European price parsing**: `number_from("1.299,00")` returns `1.299` (wrong). Czech, German, Spanish, Portuguese sites use `.` as thousands separator and `,` as decimal.
2. **Single CSS selector fragility**: One selector per field means any site update silently breaks extraction. No fallback hierarchy.
3. **Missing JSON-LD extraction**: Most modern e-commerce sites embed complete product data in `application/ld+json`. Ignoring this means using brittle CSS for fields that are available structured.
4. **No meta tag fallbacks**: `og:image` and `og:title` are reliable fallbacks for image and name.
5. **No required-field warnings**: When extraction returns nil for name/price/image, there is no visible signal during parser testing.
6. **No GraphQL support in API workflow**: Sites using GraphQL (Shopify, custom React frontends) cannot be scraped with the current API TOML.
7. **Cursor pagination not supported**: APIs using `pageInfo.hasNextPage` / `endCursor` (common in GraphQL and modern REST) will silently stop after page 1.
8. **No auth token detection**: Bearer tokens used by APIs are not captured in Phase 1, causing Phase 2/3 parsers to fail authentication silently.

## 4. Proposal

### 4.1 `dmart-details-parser.toml` — JSON-LD + meta tag pre-check (HTML agent)

Add step 9.a0 before the per-field CSS selector discovery loop:
- `browser_grep_html(query: "@type")` — check for JSON-LD Product schema
- If found: extract all available fields via `json_ld.dig(...)`, mark as discovered, skip CSS for those fields
- If not found: proceed with normal CSS selector discovery
- Always extract `og:image` and `og:title` as fallbacks for img_url and name

The AI agent generates the appropriate Ruby code (with `json_ld`, `og_image`, etc.) when writing `details.rb`. The template itself stays clean with PLACEHOLDERs.

### 4.2 `dmart-api-details-parser.toml` — JSON-LD as last resort

Add a note in the "fields not available via API" section: if critical fields (description, brand, images) are consistently nil across all 3 test products, the agent may queue a secondary HTML page fetch and extract from JSON-LD. This is explicitly last resort — adds a second HTTP fetch per product — so exhaust API fields first.

### 4.3 `dmart-api-scrape.toml` — GraphQL + auth token detection

Add to Step 9.c:
- Search for GraphQL endpoints: `browser_network_search({query: "graphql", searchIn: ["url"]})`
- If found: document operationName, variables structure, cursor field for pagination
- Capture auth headers: `browser_network_search({query: "Authorization", searchIn: ["requestHeaders"]})`
- If Bearer token found: document whether it's static (hardcode in headers.rb) or dynamic (capture via seeder)

### 4.4 `dmart-api-navigation-parser.toml` — Cursor pagination + deduplication

Add cursor-based pagination pattern alongside offset:
```ruby
# Cursor-based pagination (GraphQL / modern REST with hasNextPage)
next_cursor = data.dig('pageInfo', 'endCursor') || data.dig('meta', 'nextCursor')
has_next    = data.dig('pageInfo', 'hasNextPage') == true || !next_cursor.nil?
if has_next && next_cursor
  pages << {
    url: api_url, method: "POST",
    body: { variables: { after: next_cursor, first: per_page } }.to_json,
    fetch_type: "standard", headers: headers,
    vars: vars.merge('cursor' => next_cursor, 'page' => current_page + 1)
  }
end
```

Add deduplication guard in listings loop:
```ruby
seen_ids = (page['vars']['seen_ids'] || [])
products = products.reject { |p| seen_ids.include?(p['id'].to_s) }
seen_ids += products.map { |p| p['id'].to_s }
# pass seen_ids forward: vars.merge('seen_ids' => seen_ids)
```

## 5. Implementation Order

| Step | File | Change | Effort | Risk |
|---|---|---|---|---|
| 1 | `dmart-details-parser.toml` | Add JSON-LD + meta tag pre-check (step 9.a0) | Medium | None — additive instruction |
| 2 | `dmart-api-details-parser.toml` | Add JSON-LD last-resort note | Low | None — additive note |
| 3 | `dmart-api-scrape.toml` | GraphQL detection + auth token capture | Low | None — additive steps |
| 4 | `dmart-api-navigation-parser.toml` | Cursor pagination + deduplication | Medium | Low — commented template |
