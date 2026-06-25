# Proposal: snoonu_kw Restaurant Details Parser (Phase 3)

**Created:** 2026-06-24
**Status:** Done
**Scope:** `generated_scraper/snoonu_kw/parsers/restaurant_details.rb`, state files

## 1. Background
Phase 2 completed for snoonu_kw. Phase 3 must extract restaurant metadata and queue menu pages for Phase 4.

## 2. Current State
`restaurant_details.rb` is boilerplate with PLACEHOLDER selectors. Discovery confirmed inline SSR menu on restaurant URL; `/menu` sub-URL is empty.

## 3. Problem(s)
- No field extraction implemented
- Menu queue uses broken `/menu` pattern

## 4. Proposal
- Primary: JSON-LD `Restaurant` block (name, geo, rating, phone, cuisine, image)
- Secondary: `__NEXT_DATA__` → `merchant-details` query (tags, weekdayAvailabilities, ratingDetails)
- CSS fallbacks: `h1.Title_title__Bptb4`, `.MerchantDetails_detail__ez3c5` label/value pairs
- Menu: queue `menu_listings` with `?_dh_menu=1` GID buster (inline menu, separate page type)

## 5. Implementation Order
1. Implement parser — low risk
2. Test 3 URLs via parser_tester — medium risk
3. Write restaurant-details-state.json + phase-status — low risk
