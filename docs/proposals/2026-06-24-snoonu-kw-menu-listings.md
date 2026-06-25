# Proposal: snoonu_kw Menu Listings Parser (Phase 4)

**Created:** 2026-06-24
**Status:** Done
**Scope:** `generated_scraper/snoonu_kw/parsers/menu_listings.rb`, `lib/headers.rb`, state files

## 1. Background
Phase 3 queues `menu_listings` pages with `?_dh_menu=1` GID buster. Phase 4 must discover menu structure and queue `menu` pages for Phase 5.

## 2. Current State
`menu_listings.rb` is boilerplate Strategy B (single-page fallback). Discovery confirmed in-page category tabs trigger `POST gateway.kwt.snoonu.com/api/v3/merchant_products` with `{"menu_id":<category_id>,"page":1}`.

## 3. Problem(s)
- Boilerplate only queues one menu page via `_dh_menu=1` fallback
- SSR `menuData` only hydrates "All" (20 items); per-category data requires API
- Same API URL needs GID busters per category (`?_dh_cat=<id>`)

## 4. Proposal
- Structure: `multi_category` + `api_driven` → Strategy A (queue per category)
- Parse `__NEXT_DATA__` → `merchant-details` → `menuData` array (`id`, `name`)
- Skip "All" category (partial preview); queue POST API page per real category
- Add `ReqHeaders::API_HEADERS` (stable geo/platform headers from browser probe)
- Phase 5 (`menu.rb`) parses JSON API response — out of scope for this phase

## 5. Implementation Order
1. Update headers + menu_listings.rb — low risk
2. parser_tester on 3 menu root URLs — medium risk
3. Write menu-listings-state.json + phase-status — low risk
