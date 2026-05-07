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

## Code generation safety

- Validate Ruby before saving.
- Comment non-obvious selectors and site quirks.
- Never declare `pages`, `outputs`, `page`, or `content`.
