# Phase 4: Menu Parser

**version:** 2.0.0

**Used by:** dhero
**Reads:** `restaurant-details-state.json` (`_notes` optional), `navigation-selectors.json` (legacy `restaurant-details-knowledge.md` / `menu-knowledge.md` optional merge)
**Writes:** `menu-state.json` (includes human **`_notes`** — replaces standalone `menu-knowledge.md` for new runs)
**Edits:** `parsers/menu.rb`
**Next phase:** LAST phase in dhero pipeline — no chaining

---

## Context

This is the final phase of the dhero pipeline. The restaurant details parser (Phase 3) queued restaurant pages with `page_type: "menu"`. This parser extracts menu items per restaurant.

Menu items are the primary data output — equivalent to "products" in the e-commerce pipeline.

---

## Inputs (from args)

- `scraper=<scraper_name>` — REQUIRED
- `project=dhero` — REQUIRED (or set by alias)
- `url=<restaurant_url>` — OPTIONAL — uses sample from restaurant-details-state.json if not provided
- `resume-url=<url>` — OPTIONAL
- `out=<base_dir>` — OPTIONAL, defaults to `./generated_scraper`
- `auto_next=true|false` — OPTIONAL, default: false (this is the last phase — auto_next has no effect)

---

## STEP 1: Load State Files and Profile

Load `profiles/dhero.toml`.

Load state files:
1. `restaurant-details-state.json` — get `restaurant_urls_sampled`, `menu_url_pattern`, `vars_passed_to_menu`, `_notes` if any
2. (Legacy) `restaurant-details-knowledge.md` — merge once if needed
3. `navigation-selectors.json`
4. `discovery-state.json` — popup_handling
5. `menu-state.json` (if resuming)

Load `parsers/menu.rb` from boilerplate.

Validate prerequisites:
- `restaurant-details-state.json` must exist → "Run `/restaurant-details-parser scraper=<scraper> project=dhero` first"
- `menu.rb` must exist from boilerplate

---

## STEP 2: Determine Sample Restaurant URL

Use `restaurant-details-state.json.restaurant_urls_sampled[0]`.
Or use `url` param / `resume-url` if provided.

---

## STEP 3: Test Existing Parser

```javascript
parser_tester({
  scraper_dir: "<absolute_path>/generated_scraper/<scraper>",
  parser_path: "parsers/menu.rb",
  page_type: "menu",
  auto_download: true,
  vars: '{"restaurant_name":"<name>","restaurant_url":"<url>","cuisine":"<cuisine>"}',
  quiet: false
})
```

---

## STEP 4: Navigate to Restaurant Menu Page

Navigate to the sample restaurant URL.

**IMPORTANT**: The menu may be:
- **Inline on the restaurant page** — use the restaurant detail URL directly
- **Separate URL** — check `restaurant-details-state.json.menu_url_pattern` and navigate accordingly

Handle popups.

**Pre-check for embedded JSON** (menus often use embedded JSON or API calls):
```javascript
// Check for window.__NEXT_DATA__ or similar embedded JSON
browser_evaluate(() => {
  if (window.__NEXT_DATA__) return { found: true, type: 'NEXT_DATA', size: JSON.stringify(window.__NEXT_DATA__).length };
  if (window.__INITIAL_DATA__) return { found: true, type: 'INITIAL_DATA' };
  return { found: false };
})

// Also check for JSON-LD
browser_extract_json_ld({ type: "Menu" })
browser_extract_json_ld({ type: "Restaurant" })
```

Check for menu API calls:
```javascript
browser_network_requests_simplified()
// Look for requests to /api/menu, /menu, /items, /products with JSON responses
```

If API found: use `browser_request` to fetch menu JSON directly (cheaper than scraping DOM).

---

## STEP 5: Discover Menu Item Selectors

Using `docs/shared/selector-discovery.md` protocol:

### Key fields to extract per menu item
- `name` — item name
- `description` — item description
- `customer_price_lc` — price
- `currency_code_lc` — currency
- `category_name` — menu section/category (e.g., "Starters", "Mains", "Desserts")
- `img_url` — item photo (may not be present on all sites)
- `is_available` — whether item is currently available
- `item_attributes` — tags (e.g., vegetarian, spicy, halal, new)
- `barcode` / `sku` — item ID if available

### Menu structure detection
- **Single page**: All menu items on one page
- **Tabbed sections**: Separate tabs per category (Starters / Mains / etc.)
- **Paginated**: Load more or infinite scroll
- **API-driven**: Items loaded via API (preferred — use `browser_request`)

Document menu structure in `menu-state.json` → `_notes` (markdown).

---

## STEP 6: Edit parsers/menu.rb

Follow `docs/shared/datahen-conventions.md` conventions.

Menu parser iterates menu sections and extracts items:

```ruby
html = Nokogiri::HTML(content)

# Restaurant context from vars
restaurant_name = page[:vars]['restaurant_name']
restaurant_url  = page[:vars]['restaurant_url']
cuisine         = page[:vars]['cuisine']

# Extract menu sections
html.css('.menu-section').each do |section|
  category_name = section.at_css('.section-title')&.text&.strip

  section.css('.menu-item').each_with_index do |item, idx|
    name        = item.at_css('.item-name')&.text&.strip
    description = item.at_css('.item-description')&.text&.strip
    price_text  = item.at_css('.item-price')&.text&.strip
    customer_price_lc = price_text&.gsub(/[^\d.]/, '')&.to_f
    img_url     = item.at_css('img')&.[]('src')
    is_available = item.at_css('.sold-out').nil?

    next if name.nil? || name.empty?

    outputs << {
      name:                  name,
      description:           description,
      customer_price_lc:     customer_price_lc,
      currency_code_lc:      'KES',  # from discovery-state or profile default
      category_name:         category_name,
      img_url:               img_url,
      is_available:          is_available,
      restaurant_name:       restaurant_name,
      restaurant_url:        restaurant_url,
      cuisine:               cuisine,
      item_attributes:       nil,
      barcode:               nil,
      sku:                   nil,
      url:                   page[:url],
      scraped_at_timestamp:  Time.now.utc.iso8601,
      crawled_source:        'WEB',
    }
  end
end

save_outputs(outputs) if outputs.length > 99
```

Adapt selectors to the actual site's CSS. Replace PLACEHOLDER strings.

---

## STEP 7: Test Parser

Test on 3 different restaurant URLs. Each should produce menu item outputs. Fix and re-test if any fail.

---

## STEP 8: Write menu-state.json (USE ABSOLUTE PATH)

Include top-level JSON (shape can include `menu_structure`, `selectors_summary`, `test_urls`) plus non-empty **`_notes`** markdown covering:
- Menu structure detected (sections, tabs, pagination, API)
- Selectors used for each field
- Fields not available (nil)
- Embedded JSON / API findings
- Sample output validation

---

## STEP 9: Update Phase Status

`phase-status.json` — set `menu_discovery.status = "completed"`.

`browser-context.json` — update.

---

## STEP 10: Completion Report (FINAL PHASE)

This is the LAST phase of the dhero pipeline. No auto-chaining.

```
🎉 DHero Scraper Generation Complete!

Scraper: <scraper_slug>
Project: dhero

All 4 phases completed:
  ✅ Phase 1: Site Discovery
  ✅ Phase 2: Navigation Parser (Restaurant Listings)
  ✅ Phase 3: Restaurant Details Parser
  ✅ Phase 4: Menu Parser

Parser files ready:
  - parsers/listings.rb
  - parsers/restaurant_details.rb
  - parsers/menu.rb

To test the full pipeline:
  datahen_run reset → seed → step listings → step restaurant_details → step menu
```

---

## Completion Checklist

- ✅ Menu structure detected (sections, API, pagination type)
- ✅ `menu.rb` edited with item selectors
- ✅ Parser tested on 3 restaurant URLs
- ✅ Each restaurant produces menu item outputs
- ✅ `menu-state.json` written (includes `_notes`)
- ✅ `phase-status.json` updated
- ✅ Final completion report shown (no chaining — this is the last phase)
