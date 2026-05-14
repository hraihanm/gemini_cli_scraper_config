# Proposal: DHero 5-stage pipeline — menu_listings + menu_details split

**Created:** 2026-05-13
**Status:** Done
**Scope:** `profiles/dhero.toml`, `docs/workflows/phases/`, `.gemini/commands/`, `templates/dhero_boilerplate/`, `generated_scraper/ai-degusta_ve/`

---

## 1. Background

The dhero pipeline currently has 4 stages. Stage 4 (menu parser) does two things in a single pass: navigates to the restaurant's menu entry point, discovers what category/page URLs exist, and then also extracts item-level data — all in one parser. This is fine for simple restaurants where the full menu is on a single page, but breaks down when:

- The menu has multiple category tabs or sub-pages
- The menu is paginated (load more / infinite scroll)
- Different category URLs need to be scraped individually

The correct architecture — matching how dmart handles categories → listings → details — is to split menu into two stages:
- **Stage 4: menu_listings** — receives the restaurant's menu root URL, discovers category/page URLs, queues them
- **Stage 5: menu_details** — receives a single category/page URL, extracts item-level data from it

This is a general solution, not site-specific. Simple single-page menus are handled by having `menu_listings` queue the current URL as a `menu_details` page (pass-through).

---

## 2. Current State

### Pipeline (profiles/dhero.toml)
```
Phase 1: scrape              → 01-site-discovery.md
Phase 2: navigation-parser   → 02-navigation-parser.md
Phase 3: restaurant-details-parser → 03-restaurant-details.md
Phase 4: menu-parser         → 04-menu-parser.md       ← does listings + details in one
```

### Parsers (boilerplate + generated)
- `parsers/restaurant_details.rb` — queues `page_type: 'menu'` for each restaurant
- `parsers/menu.rb` — single parser that: probes for menu URL, finds selectors, extracts items

### Config page types (boilerplate config.yaml)
```yaml
- page_type: menu
  file: ./parsers/menu.rb
```

### Commands
- `.gemini/commands/menu-parser.toml` — routes to `04-menu-parser.md`
- No menu-listings command exists

### State files (generated scraper)
- `menu-state.json` — written by the menu parser after completion
- No `menu-listings-state.json` exists

---

## 3. Problem(s)

1. **The menu parser conflates navigation with extraction.** It decides which URL to scrape AND extracts items from it — two separate concerns in one file.
2. **Pagination and multi-category menus cannot be handled generically.** If a restaurant's menu has 5 category tabs, the current parser would need per-site logic to queue all 5. There's no systematic listing phase to discover and queue them.
3. **Vars flow is direct restaurant_details → menu, skipping a natural "listings" layer** that would know which category each item came from at the URL level.
4. **The boilerplate template (`menu.rb`) gives agents no structural guidance** on the listings vs details separation. Agents write all logic into one file.

---

## 4. Proposal

### 4.1 New pipeline shape

```
Phase 1: scrape
Phase 2: navigation-parser
Phase 3: restaurant-details-parser  → queues page_type: 'menu_listings'
Phase 4: menu-listings-parser       → queues page_type: 'menu'  (one per category/page)
Phase 5: menu-parser                → extracts items from single category page
```

`menu_listings` and `menu` are the DataHen page type names (stable, used in config.yaml and `pages <<`).

---

### 4.2 Data / vars flow

```
restaurant_details.rb → pages << { url: menu_root_url, page_type: 'menu_listings',
                                   vars: { loc_id, restaurant_name, restaurant_url, cuisine } }

menu_listings.rb      → pages << { url: category_url, page_type: 'menu',
                                   vars: { loc_id, restaurant_name, restaurant_url, cuisine,
                                           category_name } }   ← adds category_name

menu.rb               → outputs << { ...item fields... }       ← reads category_name from vars
```

---

### 4.3 menu_listings.rb boilerplate — what the agent must implement

The `menu_listings` parser is a **navigation parser** for menus. It mirrors how `listings.rb` works for restaurant discovery. Agent responsibilities:

1. Navigate to the menu root URL (built by `restaurant_details.rb` — see §4.5)
2. Detect menu structure:
   - **Single page** (all items visible, no tabs, no load-more): queue the current URL as `menu` with `category_name: nil`
   - **Tabbed / multi-category**: extract each category tab URL or anchor, queue each as separate `menu` page
   - **Paginated**: detect total pages / next-button pattern, queue all pages
   - **API-driven**: capture API endpoint, queue via `fetch_type: "standard"` pages
3. Pass all restaurant vars through to each queued `menu` page, adding `category_name`

Boilerplate skeleton:
```ruby
# frozen_string_literal: true
# ============================================================================
# Menu Listings Parser - DHero Boilerplate
# ============================================================================
# PURPOSE: Discover menu category/page URLs for a restaurant and queue them.
# Receives the restaurant's menu root URL. Queues page_type: 'menu' pages.
# ============================================================================

require './lib/headers'

html = Nokogiri::HTML(content)

# FROM_VARS — passed from restaurant_details parser
loc_id          = page['vars']&.dig('loc_id')
restaurant_name = page['vars']&.dig('restaurant_name')
restaurant_url  = page['vars']&.dig('restaurant_url')
cuisine         = page['vars']&.dig('cuisine')

base_vars = {
  loc_id:          loc_id,
  restaurant_name: restaurant_name,
  restaurant_url:  restaurant_url,
  cuisine:         cuisine,
}

queued = 0

# ============================================================================
# Strategy A: Multi-category / tabbed menu
# PLACEHOLDER: Replace with discovered category selectors.
# Each category tab or section becomes one 'menu' page.
# ============================================================================
# html.css('PLACEHOLDER_CATEGORY_TAB_SELECTOR').each do |tab|
#   category_name = tab.text.strip
#   category_url  = Addressable::URI.join(page['url'], tab['href']).to_s
#   next if category_url.nil? || category_url.empty?
#
#   pages << {
#     url:       category_url,
#     page_type: 'menu',
#     vars:      base_vars.merge(category_name: category_name),
#   }
#   queued += 1
# end

# ============================================================================
# Strategy B: Single-page menu — all items on this page
# Use when no separate category URLs exist.
# Pass current URL directly to menu parser, category_name comes from CSS.
# ============================================================================
if queued == 0
  pages << {
    url:       page['url'],
    page_type: 'menu',
    vars:      base_vars.merge(category_name: nil),
  }
  queued = 1
end

warn "[MENU_LISTINGS] url=#{page['url']} queued=#{queued} menu pages"
```

---

### 4.4 menu.rb boilerplate — what changes

`menu.rb` becomes a **pure item extractor**. It no longer probes for URLs or decides which page to scrape. It receives a single page, reads `category_name` from vars (if the listings parser set it) or discovers it from the page CSS.

The existing boilerplate content is mostly correct already — just remove the URL-probing / dual-path logic and add the `category_name` vars read:

```ruby
# FROM_VARS — passed from menu_listings parser
restaurant_id   = page['vars']&.dig('loc_id')
restaurant_name = page['vars']&.dig('restaurant_name')
restaurant_url  = page['vars']&.dig('restaurant_url')
cuisine         = page['vars']&.dig('cuisine')
category_name   = page['vars']&.dig('category_name')  # nil if single-page menu
```

If `category_name` is nil, the parser discovers it from the page CSS (section header).

---

### 4.5 restaurant_details.rb boilerplate — queue change

Currently queues `page_type: 'menu'`. Must change to `page_type: 'menu_listings'`.

Menu root URL construction stays as established: strip `.html`, append `/menu` if a separate menu page exists, or use restaurant URL if inline. The agent decides this during Phase 3 discovery and writes the appropriate URL.

```ruby
# Queue menu listings page (Phase 4) — menu_listings will queue individual menu pages
pages << {
  url:       menu_root_url,   # built during discovery: separate /menu URL or restaurant URL
  page_type: 'menu_listings',
  vars: {
    loc_id:          lead_id,
    restaurant_name: restaurant_name,
    restaurant_url:  page['url'],
    cuisine:         main_cuisine,
  }
}
```

---

### 4.6 config.yaml — new page type

```yaml
parsers:
  - page_type: listings
    file: ./parsers/listings.rb
    disabled: false
  - page_type: restaurant_details
    file: ./parsers/restaurant_details.rb
    disabled: false
  - page_type: menu_listings          # NEW
    file: ./parsers/menu_listings.rb  # NEW
    disabled: false
  - page_type: menu
    file: ./parsers/menu.rb
    disabled: false
```

---

### 4.7 profiles/dhero.toml — new pipeline phase

```toml
[[pipeline.phases]]
phase    = "restaurant-details-parser"
workflow = "docs/workflows/phases/03-restaurant-details.md"
label    = "Phase 3: Restaurant Details Parser"
command  = "restaurant-details-parser"

[[pipeline.phases]]                                          # NEW
phase    = "menu-listings-parser"
workflow = "docs/workflows/phases/04-menu-listings.md"
label    = "Phase 4: Menu Listings Parser"
command  = "menu-listings-parser"

[[pipeline.phases]]                                          # renumbered from 4→5
phase    = "menu-parser"
workflow = "docs/workflows/phases/05-menu-details.md"
label    = "Phase 5: Menu Details Parser"
command  = "menu-parser"
```

---

### 4.8 New workflow docs

**`04-menu-listings.md`** (new) — mirrors structure of `02-navigation-parser.md`:
- STEP 1: Load state — `restaurant-details-state.json`, `discovery-state.json`
- STEP 2: Determine menu root URL (from `restaurant-details-state.json.menu_url_pattern`)
- STEP 3: Test existing `menu_listings.rb`
- STEP 4: Navigate to menu root URL, detect structure (single / tabbed / paginated / API)
- STEP 5: Discover category selectors or pagination pattern
- STEP 6: Edit `menu_listings.rb` — implement discovered strategy
- STEP 7: Test on 3 restaurant URLs — each must queue ≥ 1 `menu` page
- STEP 7b: Eval gate
- STEP 8: Write `menu-listings-state.json` (structure type, selectors, category count)
- STEP 9: Update phase status, auto-chain to `menu-parser`

**`05-menu-details.md`** (was `04-menu-parser.md`) — significant simplification:
- Remove all URL-probing / dual-path logic
- STEP 4: Navigate to the URL provided (it is always a single specific category/page)
- STEP 5: Discover item selectors only (no structure detection — that's done)
- Add: read `category_name` from vars; if nil, discover from page CSS
- STEP 8: Write `menu-state.json`

---

### 4.9 New command file

**`.gemini/commands/menu-listings-parser.toml`**:
```toml
description = "Phase 4 (dhero): Menu listings parser. Usage: /menu-listings-parser scraper=<name> project=dhero [url=...] [auto_next=true]"

prompt = """
DHero Phase 4 — menu listings parser.

Firmware: `.gemini/system.md`.

@{docs/shared/agent-rules-gemini.md}
@{docs/shared/datahen-conventions.md}
@{docs/shared/selector-discovery.md}

Parse {{args}}: `scraper=`, `project=` (must be dhero), `url=`, `resume-url=`, `out=`, `auto_next=`.

1. `read_file` → `profiles/dhero.toml`.
2. Find pipeline phase `menu-listings-parser` — read its `workflow` path.
3. `read_file` → that workflow; execute every STEP.
4. Auto-chain to `menu-parser` when `auto_next=true`.
"""
```

**`.gemini/commands/menu-parser.toml`** — update workflow reference from `04-menu-parser.md` to `05-menu-details.md` (no other changes needed, the command name stays `menu-parser`).

---

### 4.10 CLAUDE.md alias update

Update the dhero pipeline alias in CLAUDE.md:
```
dhero: /dhero-scrape → /dhero-navigation-parser → /dhero-restaurant-details → /dhero-menu-listings → /dhero-menu-parser
```

---

### 4.11 ai-degusta_ve generated scraper — migration

`restaurant_details.rb`: change `page_type: 'menu'` → `page_type: 'menu_listings'`
`config.yaml`: add `menu_listings` page type pointing to `parsers/menu_listings.rb`
`parsers/menu_listings.rb`: new file — implement Strategy B (single-page pass-through) initially; agent upgrades to Strategy A when multi-category pages are found
`parsers/menu.rb`: strip the dual-path URL-probing logic; pure item extractor

---

## 5. Implementation Order

| Step | File(s) | Change | Effort | Risk |
|---|---|---|---|---|
| 1 | `templates/dhero_boilerplate/parsers/menu_listings.rb` | Create new boilerplate | Low | None |
| 2 | `templates/dhero_boilerplate/parsers/menu.rb` | Add `category_name` vars read; remove dual-path URL logic | Low | Low |
| 3 | `templates/dhero_boilerplate/parsers/restaurant_details.rb` | Change `page_type: 'menu'` → `'menu_listings'` | Low | Low |
| 4 | `templates/dhero_boilerplate/config.yaml` | Add `menu_listings` page type | Low | None |
| 5 | `profiles/dhero.toml` | Add `menu-listings-parser` phase; renumber menu-parser to phase 5 | Low | Low |
| 6 | `docs/workflows/phases/04-menu-listings.md` | Create new workflow | Medium | None |
| 7 | `docs/workflows/phases/05-menu-details.md` | Create from current `04-menu-parser.md`; simplify | Medium | Low |
| 8 | `docs/workflows/phases/04-menu-parser.md` | Delete or redirect to `05-menu-details.md` | Low | Low |
| 9 | `docs/workflows/phases/03-restaurant-details.md` | Update queue snippet and schema to use `menu_listings` | Low | Low |
| 10 | `.gemini/commands/menu-listings-parser.toml` | Create new command | Low | None |
| 11 | `.gemini/commands/menu-parser.toml` | Update workflow path to `05-menu-details.md` | Low | None |
| 12 | `CLAUDE.md` | Update dhero alias to show 5-stage pipeline | Low | None |
| 13 | `generated_scraper/ai-degusta_ve/` | Migrate existing scraper (config, parsers, state) | Medium | Medium |

Steps 1–12 are purely additive or boilerplate changes — low risk. Step 13 touches the live generated scraper; the `menu.rb` dual-path logic from the previous fix should be simplified back to a clean item extractor once `menu_listings.rb` takes over discovery.
