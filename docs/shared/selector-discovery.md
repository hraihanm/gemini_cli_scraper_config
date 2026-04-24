# Selector Discovery Protocol

**version:** 2.0.0

This file defines the standard protocol for discovering CSS selectors using browser tools. Follow this order for every field.

---

## Discovery Order (most efficient → most expensive)

### Step 1 — browser_grep_html (start here)

```javascript
browser_grep_html(query: "<visible text value of the field>")
```

- Uses actual visible text on the page, not CSS class guesses
- Returns HTML snippets with `>>>match<<<` markers — class names, data attributes, DOM structure visible
- Identify CSS selector directly from snippet (e.g., `span.product-price`, `[data-brand]`)
- Token-efficient: returns only matching context, NOT the full page HTML

Examples:
```javascript
browser_grep_html(query: "Samsung Galaxy S24")  // → finds name selector
browser_grep_html(query: "KSh 89,999")          // → finds price selector
browser_grep_html(query: "Samsung")             // → finds brand selector
browser_grep_html(query: "@type")               // → detects JSON-LD presence
```

### Step 2 — browser_inspect_element (when you have a ref or grep is ambiguous)

```javascript
// Single element
browser_inspect_element({ element: "product name", ref: "e42" })

// Batch mode — inspect multiple refs in one call (use whenever inspecting > 1 element)
browser_inspect_element({
  element: "product name", ref: "e42",
  batch: [
    { element: "price", ref: "e67" },
    { element: "brand", ref: "e91" }
  ]
})
```

Use when:
- `browser_snapshot()` gave you a ref for this field
- The grep snippet shows multiple candidate classes — need to confirm the right one

### Step 3 — Verify the selector

```javascript
// For text fields (names, prices, labels, descriptions)
browser_verify_selector(element, selector, expected_text)

// For attribute fields (src, href, data-*) — do NOT use browser_evaluate for these
browser_verify_selector(element, selector, expected_value, { attribute: "src" })
```

Use `browser_evaluate()` only for complex JavaScript-based extraction — NOT for simple attribute reads.

### Step 4 — Fallback: browser_view_html (last resort)

Only call if Steps 1–3 completely fail. High token cost.

```
💭 browser_view_html: need full DOM for <field> — browser_grep_html returned no results after 3 queries
```

---

## Special Tools

### browser_extract_json_ld — structured data shortcut

Run this BEFORE per-field CSS discovery on every details page:

```javascript
browser_extract_json_ld({ type: "Product" })
```

If `found: true`:
- `data` contains parsed JSON-LD. `fields_available` lists what's extractable.
- `script_tag_selector` gives the exact CSS selector for Ruby (e.g., `script[type="application/ld+json"]`)
- For every JSON-LD field that maps to an output field, mark as "discovered via JSON-LD"
- Proceed to CSS discovery only for fields NOT in JSON-LD

### browser_detect_pagination — pagination shortcut

Run this BEFORE manual pagination strategy probing on every listings page:

```javascript
browser_detect_pagination({ current_url: "<current listing page URL>" })
```

Checks 12+ count-element patterns, 8+ next-button patterns, and URL structure automatically.
- `strategy: "count_based"` → use `count_selector` and `url_pattern` from result
- `strategy: "next_button"` → use `next_button_selector` from result
- `strategy: "unknown"` → fall back to manual strategy probing

### browser_count_selector — count elements without browser_evaluate

```javascript
browser_count_selector({ selector: ".product-item", expected_min: 1 })
```

Preferred over `browser_evaluate(() => document.querySelectorAll(...).length)` for counting elements.

### browser_extract_images — image gallery shortcut

```javascript
browser_extract_images({ container_selector: ".product-gallery" })
```

Returns `primary_url`, `images` array, `lazy_load_pattern`. Use instead of multiple `browser_evaluate` calls for image variants.

---

## Browser Fetch Detection (Navigation Parsers)

Before setting `fetch_type` in categories/listings parsers, check if the content needs JavaScript:

```javascript
// Check if links are visible in DOM
browser_evaluate(() => {
  const categorySelectors = [
    '.category-item a', '.nav-menu a', '.category-link',
    '[class*="category"] a', 'nav a[href*="category"]'
  ];
  for (const sel of categorySelectors) {
    const els = document.querySelectorAll(sel);
    if (els.length > 0) return { found: true, selector: sel, count: els.length };
  }
  return { found: false };
})
```

If not found → check for reveal buttons → test button click → document in `navigation-selectors.json`:
- `needs_browser_fetch`: true/false
- `button_to_reveal.selector`: CSS selector of button
- `button_to_reveal.puppeteer_code`: e.g., `"await page.click('button.menu-toggle'); await sleep(2000);"`
