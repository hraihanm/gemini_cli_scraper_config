# DataHen Ruby parser patterns (extended)

**version:** 1.0.0

For top-level script rules and reserved variables, see **`docs/shared/datahen-conventions.md`** (canonical). This file adds operational patterns from the former long `system.md`.

## Preloaded libraries

`nokogiri`, `json`, `cgi` are typically available — follow project boilerplate for `require` lines.

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
