# Proposal: snoonu_kw Menu Parser (Phase 5)

**Created:** 2026-06-24
**Status:** Done
**Scope:** `generated_scraper/snoonu_kw/parsers/menu.rb`, eval fixtures, state files

## 1. Background
Phase 4 queues per-category POST pages to `gateway.kwt.snoonu.com/api/v3/merchant_products`. Phase 5 must parse JSON responses into `items` collection outputs.

## 2. Current State
`menu.rb` is boilerplate with PLACEHOLDER CSS selectors. API response structure confirmed via live probe.

## 3. Problem(s)
- Parser expects HTML/CSS; actual content is JSON API response
- Pagination (`current_page < last_page`) not implemented
- No eval fixtures for menu phase

## 4. Proposal
- Parse `JSON.parse(content)` → `data` array of products
- Use `Extraction.item_prices` for price/original_price; `Extraction.promoted?` for `item_is_promoted`
- `category_name` from `page['vars']['category_name']`
- `currency: 'KWD'` (Kuwait)
- Queue next page when `current_page < last_page` (same POST pattern as menu_listings)
- Deduplicate by product `id`
- Test 3 category API responses; create eval fixture

## 5. Implementation Order
1. Implement menu.rb — low risk
2. parser_tester on 3 samples — medium risk
3. eval gate + state files — low risk
