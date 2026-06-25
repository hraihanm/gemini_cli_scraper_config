# Proposal: Production Scraper Pattern Absorption

**Created:** 2026-06-25
**Status:** Done (steps 1-4); steps 5-7 pending follow-up
**Scope:** `docs/shared/datahen-conventions.md`, `docs/shared/datahen-ruby-parsers.md`, `templates/*/lib/helpers.rb`, `templates/dhero_boilerplate/lib/`

## 1. Background

13 production scrapers were surveyed:
`esselunga_it`, `15_web_tesco_malaysia`, `aldawaa_sa`, `varus_ua_kiev`, `medco_ni`,
`los_jardines`, `farmacia_sv`, `SanRoque_UY`, `tripadvisor`, `eztable_tw`,
`chope_sg`, `17_web_jayagrocer_malaysia`, `66_web_parknshop_hongkong`

These are real, deployed, DataHen V3 scrapers with months/years of production hardening.
The goal is to extract generalizable patterns and close the gaps between generated boilerplate
and production quality.

## 2. Current State

Current boilerplates and knowledge spokes are missing 10 critical patterns that every
production scraper uses.

## 3. Gaps Found

| # | Gap | Severity | Where to fix |
|---|---|---|---|
| 1 | `page['effective_url']` fallback for redirected pages | High | conventions.md |
| 2 | `failed_content` variable for error response bodies | High | conventions.md |
| 3 | `finish` after `limbo` — mandatory or parser continues | High | conventions.md |
| 4 | `autorefetch` pattern (limbo vs refetch + threshold) | High | conventions.md + helpers.rb |
| 5 | `needs_reparse` + `+1` second `scraped_at_timestamp` trick | Medium | conventions.md |
| 6 | `priority:` tuning convention (seeder→categories→listings→details) | Medium | conventions.md |
| 7 | `raise` for fatal nil fields (vs silent `warn`) | Medium | conventions.md |
| 8 | `http2: true` and `freshness:` page options | Medium | conventions.md |
| 9 | `empty_to_nil` / `fix_image_url` / `clean_html_description` helpers | Medium | helpers.rb |
| 10 | `_collection` switching (permanently_closed, outside_country, not_found) | Medium | ruby-parsers.md |

## 4. Proposal

### Immediate (this PR)
- Update `docs/shared/datahen-conventions.md` — page runtime variables, response handling, priority, `needs_reparse`
- Update `docs/shared/datahen-ruby-parsers.md` — helper patterns, collection switching, JSON extraction tricks
- Update `templates/dmart_dloc_boilerplate/lib/helpers.rb` — add `fix_image_url`, `clean_html_description`, `empty_to_nil`, `autorefetch`
- Update `templates/dhero_boilerplate/lib/helpers.rb` — add `empty_to_nil`, `autorefetch`

### Structural (follow-up PRs)
- Extract `lib/autorefetch.rb` as a shared file both parsers `require` (removes copy-paste per parser)
- Add `lib/fetch.rb` page-builder factory to dhero boilerplate (tripadvisor pattern)
- Add `lib/extraction.rb` to dmart boilerplate (JSON-LD + meta extraction helpers; currently dhero-only)
- Shopify variant queuing loop in dmart boilerplate (jayagrocer pattern)
- OAuth2 / token flow scaffolding for API scrapers

## 5. Implementation Order

| Step | Action | Status |
|---|---|---|
| 1 | datahen-conventions.md updates | Done |
| 2 | datahen-ruby-parsers.md updates | Done |
| 3 | dmart helpers.rb | Done |
| 4 | dhero helpers.rb | Done |
| 5 | lib/autorefetch.rb extraction (separate require) | Pending |
| 6 | lib/fetch.rb page-builder factory for dhero | Pending |
| 7 | lib/extraction.rb JSON-LD + meta helpers for dmart | Pending |
