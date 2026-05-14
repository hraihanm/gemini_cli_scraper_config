# Proposal: degusta_ve — Queue /menu URL and expand menu parser

**Created:** 2026-05-13
**Status:** Done
**Scope:** `generated_scraper/ai-degusta_ve/parsers/restaurant_details.rb`, `generated_scraper/ai-degusta_ve/parsers/menu.rb`, `generated_scraper/ai-degusta_ve/.scraper-state/restaurant-details-state.json`, `generated_scraper/ai-degusta_ve/.scraper-state/menu-state.json`

## 1. Background

The ai-degusta_ve scraper was originally built with the assumption that the menu was inline on the restaurant detail page (the "RECOMENDADOS POR USUARIOS" section). The site at degustavenezuela.com also exposes a dedicated `/menu` sub-page per restaurant, e.g. `https://www.degustavenezuela.com/caracas/restaurante/la-romanina_289/menu`, which contains full menu listings with category sections, item names, descriptions, and prices.

## 2. Current State

- `restaurant_details.rb` (line 162): queues `page['url']` — the restaurant detail URL itself — as the `menu` page type.
- `menu.rb`: only handles `.dg-platos-recomendados .dish-holder` (recommended section); no price or image data.
- `restaurant-details-state.json`: `menu_url_pattern = "inline_same_page"`.
- `menu-state.json`: `menu_structure.type = "inline_recommended_dishes"`.

## 3. Problem(s)

- The proper menu page (`/menu`) is never queued, so the full menu listings are never scraped.
- The recommended section only yields dish name + vote count as description; no prices, no categories, no images.
- `item_price` is always nil because the recommended section has no price data.

## 4. Proposal

### 4a. `restaurant_details.rb` — queue the `/menu` URL

Strip `.html` from the restaurant URL (if present) and append `/menu`:

```ruby
menu_url = page['url'].sub(/\.html$/, '') + '/menu'
pages << {
  url:       menu_url,
  page_type: 'menu',
  vars: { ... }
}
```

### 4b. `menu.rb` — dual-path parser

Detect whether the incoming URL ends with `/menu`. If yes, parse the full menu page (category sections + items). If not, fall back to the existing recommended-section logic.

The full menu page selectors are PLACEHOLDER — needs verification via `browser_grep_html` on a live page when running `/dhero-menu-parser`. Common degusta patterns (`.dg-platos-categoria`, `.dish-holder`, `.dish-name`, `.precio`) are used as the starting guess.

### 4c. State files

Update `restaurant-details-state.json.menu_url_pattern` to `"separate_url"`.
Update `menu-state.json` to reflect the new structure and note that full-menu selectors are unverified.

## 5. Implementation Order

1. Create proposal (this file) — effort: low, risk: none
2. Update `restaurant_details.rb` — effort: low, risk: low (only URL construction)
3. Update `menu.rb` — effort: medium, risk: medium (new selectors are PLACEHOLDER, need agent verification)
4. Update state files — effort: low, risk: none
5. Re-run `/dhero-menu-parser scraper=ai-degusta_ve` to discover actual `/menu` page selectors and test
