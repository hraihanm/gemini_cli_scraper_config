# Proposal: Endpoint & URL Structure section in GENERATION_REPORT.md

**Created:** 2026-06-22
**Status:** Done
**Scope:** `scripts/scraper_qa_report.rb` — add `## Endpoint & URL Structure` section to `GENERATION_REPORT.md` by reading `discovery-state.json`

## 1. Background

Phase 1 (Site Discovery / API Scrape) writes a rich `discovery-state.json` that records API endpoints, stable/ephemeral headers, seeding strategy, URL patterns, and fetch requirements. This data is essential for debugging auth failures, understanding the seeding architecture, and onboarding — but none of it surfaces in `GENERATION_REPORT.md`. A maintainer must know to look in `.scraper-state/discovery-state.json` and parse it manually.

## 2. Current State

`write_report` in `scripts/scraper_qa_report.rb` already loads `discovery-state.json` via `load_json` in `main` (line 540) and passes it to `write_datahen_project`. The variable is never passed to `write_report`, so the report has no access to endpoint data.

`discovery-state.json` schema (from `docs/workflows/phases/01-site-discovery.md` STEP 9 and `docs/workflows/phases/api-01-scrape.md` STEP 8):
- `site_url`, `scraper_name`, `project`
- `site_structure` — `navigation_depth`, `listing_pattern`
- `page_types_found[]`
- `sample_urls` — per-type sample URLs
- `api_config` — `has_api`, `endpoint_pattern`, `requires_custom_headers`, `stable_headers{}`, `ephemeral_headers_noted[]`, `requires_browser_session`, `bare_test`, `headers_test`
- `api_endpoints[]` — `name`, `url_pattern`, `method`, `sample_response_file`
- `seeding` (dhero) — `strategy`, `input_file`, `pagination`, `auth`, `endpoints`
- `fetch_requirements` — `initial_page_needs_browser`, `categories_need_browser`, `button_to_reveal_categories`
- `popup_handling` — `popups_encountered`, `handling_method`

## 3. Problem(s)

1. A maintainer inheriting a scraper can't see at a glance "what API does this scraper call and what headers does it need?"
2. When auth breaks (e.g. session token expires), there's no report record of which headers were ephemeral vs. stable.
3. Seeding strategy (geo_grid, city_list, session_bootstrap, …) is not documented in any generated report — only in the raw state file.
4. `/run-pipeline` summary mentions phases completed but not what was discovered.

## 4. Proposal

Add `## Endpoint & URL Structure` immediately after the report header (before deploy-readiness gates) by:

1. Passing `discovery` into `write_report` ctx hash.
2. Adding `write_discovery_section(io, discovery)` helper that emits:
   - **Overview table**: site URL, navigation depth, listing pattern, page types, seeding strategy
   - **API configuration** (if `api_config.has_api`): endpoint pattern, header requirements (keys only — values stay in `lib/headers.rb`), ephemeral headers noted, bare/headers test results
   - **Discovered API endpoints**: name + URL pattern + method table
   - **Sample URLs**: per page type
   - **Fetch notes**: `initial_page_needs_browser`, reveal-button, popup handling
3. Calling `write_discovery_section` from `write_report` right after the header block.

Security: stable header **values** are deliberately omitted (keys only) — they live in `lib/headers.rb` and should not be echoed into a committed markdown report.

## 5. Implementation Order

1. Add `write_discovery_section(io, discovery)` helper — M / Low
2. Add `discovery:` key to `write_report` ctx; call `write_discovery_section` after header block — S / Low
3. Pass `discovery:` in the `write_report` call in `main` — S / Low
4. `ruby -c` syntax check — S / Low
