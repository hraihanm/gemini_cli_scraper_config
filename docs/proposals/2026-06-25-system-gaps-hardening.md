# Proposal: System Gaps Hardening

**Created:** 2026-06-25
**Status:** Done
**Scope:** boilerplate templates, phase docs, KB spokes, AGENTS.md

## 1. Background

Post-migration audit identified gaps in the scraper generation system — not in already-built scrapers, but in the templates and knowledge the agent uses to build new ones.

## 2. Current State

- `menu.rb` boilerplate uses `empty?` guard on `item_name` — misses sentinel values like `"."`, `"{}"`, `"[]"`
- `02-navigation-parser.md` has no completeness-check probe for HTML listings that already contain all fields — agent always queues details phase even when unnecessary
- `dmart_dloc_boilerplate/lib/` has no `extraction.rb` — every generated scraper re-derives JSON-LD extraction, phone formatting, id computation inline; dhero has had this since day one
- `AGENTS.md` is 393 lines — procedural workflow content belongs in spokes; firmware should be ~80 lines of invariants only

## 3. Problems

1. **`item_name: "."` bug** — sentinel slips through `empty?`, produces junk records in `items` collection
2. **Missed phase skip** — no probe for "does listings HTML already have all restaurant/product fields?" — agent defaults to full pipeline even when a phase could be skipped
3. **Duplicated extraction logic** — each dmart scraper re-derives `json_ld`, `og_image`, phone, price. Bugs fixed in one scraper don't propagate. Dhero `extraction.rb` is proven; dmart needs the same
4. **AGENTS.md context bloat** — 393 lines prepended every AGY session; PARSE framework, browser protocols, full tool reference all duplicated from spokes

## 4. Proposal

### Fix 1 — `menu.rb` boilerplate item_name guard
Use `Extraction.str_empty_to_nil` (already required via `./lib/extraction`) on item_name in both embedded JSON block and CSS fallback block.

### Fix 2 — HTML listings completeness probe in `02-navigation-parser.md`
Add a STEP before queueing details URLs: "Does this listings page already contain all required fields?" If yes: output inline + set `details_parser_needed: false` + disable details parser in config.yaml.

### Fix 3 — `lib/extraction.rb` for dmart boilerplate
Port from dhero's extraction.rb, adapted for dmart/product context:
- `json_ld_for_type(html, *types)` — find first matching JSON-LD block
- `og_value(html, property)` — read og: meta tag
- `number_from(text)` — strip non-numeric, return float or nil
- `price_from(text, divisor: 1)` — price normalization (handles pence, cents)
- `boolean_from(text)` — in-stock detection
- `encode_url_path(url)` — percent-encode non-ASCII
- `md5_id(*parts)` — stable product id
- Move existing `fix_image_url`, `clean_html_description` from `helpers.rb` here

### Fix 4 — AGENTS.md slim-down
Move procedural sections to existing spokes:
- PARSE framework + Browser-First Analysis → `docs/shared/agent-best-practices.md`
- Playwright Element Reference Protocol → `docs/shared/selector-discovery.md`
- Pagination Investigation Protocol → `docs/shared/pagination-network-exhaustion.md`
- Browser Tool Selection Protocol → `docs/shared/browser-mcp-tools.md`
- Browser Fetch Type section → `docs/shared/browser-mcp-tools.md`
- E-commerce Data Patterns → `docs/shared/datahen-conventions.md`
- E-commerce Quality Standards → `docs/shared/agent-best-practices.md`
Keep in AGENTS.md: persona, critical invariants (Ruby 2.6.5, top-level scripts, no refs), pointer to KB_HUB.md.

## 5. Implementation Order

| Step | Fix | Effort | Risk |
|---|---|---|---|
| 1 | `menu.rb` boilerplate guard | 15 min | Low |
| 2 | HTML listings completeness probe in phase doc | 30 min | Low |
| 3 | `lib/extraction.rb` for dmart boilerplate | 2 hrs | Medium |
| 4 | AGENTS.md slim-down | 1 hr | Medium — must not lose any rules |
