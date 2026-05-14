# Proposal: Menu parser — teach agent about /menu sub-URL pattern

**Created:** 2026-05-13
**Status:** Done
**Scope:** `docs/workflows/phases/03-restaurant-details.md` (STEP 4, STEP 5), `docs/workflows/phases/04-menu-parser.md` (STEP 2, STEP 4, STEP 5, STEP 8)

---

## 1. Background

The dhero pipeline has two workflow documents that define how the Gemini agent behaves:
- **Phase 3** (`03-restaurant-details.md`): discovers restaurant fields and queues menu pages
- **Phase 4** (`04-menu-parser.md`): navigates to menu pages, discovers selectors, writes `menu.rb`

The `.toml` command files (`restaurant-details-parser.toml`, `menu-parser.toml`) are thin routers — they just point to these workflow docs. All agent instruction is in the workflow docs.

---

## 2. Current State

### Phase 3 — `03-restaurant-details.md` STEP 4 (Menu URL Discovery)

Instructs the agent to:
- Look for inline menu section or "View Menu" links on the restaurant detail page
- If inline: queue the same URL; set `menu_url_pattern = "inline_same_page"`
- If separate: capture the link; set `menu_url_pattern = "separate_url"`

The code snippet shows:
```ruby
menu_url = page[:url]  # if menu is inline
# OR
menu_url = html.at_css('a.menu-link')&.[]('href')  # if separate URL
```

**Missing**: no instruction to probe for `{base_url}/menu` as a standard pattern. The agent on degusta_ve found no "View Menu" link and no inline full menu, so it concluded `inline_same_page` — missing the `/menu` sub-URL entirely.

### Phase 4 — `04-menu-parser.md` STEP 4 (Navigate to Menu Page)

Says:
> IMPORTANT: The menu may be:
> - Inline on the restaurant page — use the restaurant detail URL directly
> - Separate URL — check `restaurant-details-state.json.menu_url_pattern`

**Missing**:
- No instruction to verify or re-probe the URL type if the current page yields 0 items
- No mention of the `/menu` sub-URL pattern as a standard variant to try

### Phase 4 — STEP 2 (Determine Sample URL)

Just uses `restaurant_urls_sampled[0]` — the restaurant detail URL. If `menu_url_pattern = "separate_url"`, the agent needs to know to construct the actual menu URL, not just use the restaurant URL as-is.

### Phase 4 — STEP 5 (Discover Menu Item Selectors)

Generic — no distinction between:
- A `/menu` page (likely has category sections, prices, images)
- An inline recommended-dishes section (no prices/images, dedup required)

### Phase 4 — STEP 8 (Write menu-state.json)

No `menu_url_pattern` or `menu_url_template` fields specified in the schema.

---

## 3. Problem(s)

1. **Phase 3 agent misses `/menu` sub-URL** — it looks for inline menu or explicit "View Menu" links but doesn't probe the predictable `/menu` sub-path that food directory sites commonly expose.

2. **Phase 4 agent uses wrong sample URL** — if `menu_url_pattern` is `"separate_url"`, STEP 2 still uses the restaurant detail URL instead of building the correct `/menu` URL.

3. **Phase 4 STEP 4 has no fallback probe** — if the current page yields 0 items, the agent doesn't try the `/menu` variant.

4. **STEP 5 selector discovery is single-path** — no guidance on the different HTML structure of a `/menu` page vs the inline recommended section.

5. **menu-state.json schema is incomplete** — missing `menu_url_pattern` and `menu_url_template` fields.

---

## 4. Proposal

### Change A — `03-restaurant-details.md` STEP 4: Add `/menu` sub-URL probe

**Where**: STEP 4, "Menu URL Discovery" section.

**Add** a new Step 4.c before the existing inline/separate detection:

> **4.c Probe for `/menu` sub-URL (check first)**
>
> Many food directory sites expose a dedicated menu page at `{restaurant_base_url}/menu`. Before inspecting the page for inline menu content or "View Menu" links:
>
> 1. Build candidate: `menu_url = current_restaurant_url.sub(/\.html$/, '') + "/menu"`
> 2. Navigate to `menu_url` (or use `browser_request` to check status)
> 3. Check if the page has menu item elements (any `.dish-holder`, `.menu-item`, `.plato`, or similar item-level elements)
>
> - **If menu items found** → set `menu_url_pattern = "separate_url"`, document `menu_url_template = "{restaurant_url_without_html}/menu"`, skip remaining inline checks
> - **If 404 or no items** → fall through to existing inline / link-scan checks

**Update** the STEP 5 Ruby snippet to show the `/menu` URL construction:

```ruby
# Pattern 1: inline (same page as restaurant detail)
menu_url = page['url']

# Pattern 2: explicit link on the page
menu_url = html.at_css('a[href*="/menu"]')&.[]('href')

# Pattern 3: /menu sub-URL (probe during STEP 4)
menu_url = page['url'].sub(/\.html$/, '') + '/menu'
```

**Update** `restaurant-details-state.json` schema at STEP 7 to include `menu_url_template`:

```json
{
  "menu_url_pattern": "separate_url",
  "menu_url_template": "{restaurant_url_without_html}/menu"
}
```

---

### Change B — `04-menu-parser.md` STEP 2: Build correct menu URL

**Where**: STEP 2 "Determine Sample Restaurant URL".

**Replace** current text with:

> Use `restaurant-details-state.json.restaurant_urls_sampled[0]` as the base restaurant URL.
>
> Then build the actual URL to navigate based on `menu_url_pattern`:
>
> - `"separate_url"`: `menu_url = restaurant_url.sub(/\.html$/, '') + "/menu"`
> - `"inline_same_page"`: `menu_url = restaurant_url`
> - (missing / unknown): probe both (Step 4 will resolve)
>
> `url=` / `resume-url=` params override this — if they end with `/menu`, treat as `separate_url`.

---

### Change C — `04-menu-parser.md` STEP 4: Add re-probe when page yields 0 items

**Where**: STEP 4 "Navigate to Restaurant Menu Page".

**Add** after the embedded JSON / API check block:

> **4.x Zero-item fallback probe**
>
> After initial page inspection, if no menu items are visible and no embedded JSON was found:
>
> 1. Build `/menu` variant: `menu_url = current_url.sub(/\.html$/, '') + "/menu"` (skip if already on `/menu` URL)
> 2. Navigate to `menu_url`
> 3. Re-check for items
> 4. If items found: use this URL; update `menu_url_pattern = "separate_url"` in state
> 5. If still no items: surface to user — `"No menu items found on either URL. Manual investigation required."`

---

### Change D — `04-menu-parser.md` STEP 5: Two-path selector discovery

**Where**: STEP 5 "Discover Menu Item Selectors".

**Add** a preamble before "Key fields to extract":

> **Determine menu page type first**
>
> | URL ends with `/menu` | Expected structure |
> |---|---|
> | Yes | Category section containers → items within each section. Prices and images likely present. |
> | No (inline page) | Look for recommended/popular section. No prices or images. Dedup required (desktop + mobile views). |
>
> **For `/menu` pages**:
> - Discover category container selector: `browser_grep_html(query: "categoria")` or grep visible section headings
> - Discover item container within each section
> - Check for price elements: `browser_grep_html(query: "precio")` or `browser_grep_html(query: "$")` / `browser_grep_html(query: "Bs")`
> - Check for images: `browser_extract_images` on one section container
>
> **For inline recommended sections**:
> - Grep for `browser_grep_html(query: "RECOMENDADOS")` to find container
> - Items deduplicated by `data-id-dish` attribute (desktop + mobile both render the same items)
> - Expect nil `item_price` and `img_url`

---

### Change E — `04-menu-parser.md` STEP 8: Update menu-state.json schema

**Where**: STEP 8 "Write menu-state.json".

**Add** to required top-level fields:

```json
{
  "menu_url_pattern": "separate_url | inline_same_page",
  "menu_url_template": "{restaurant_url_without_html}/menu | null"
}
```

---

## 5. Implementation Order

| Step | File | Change | Effort | Risk |
|---|---|---|---|---|
| 1 | `03-restaurant-details.md` | STEP 4 — `/menu` probe (Change A) | Medium | Low |
| 2 | `03-restaurant-details.md` | STEP 5 snippet + STEP 7 schema (Change A cont.) | Low | Low |
| 3 | `04-menu-parser.md` | STEP 2 — URL construction (Change B) | Low | Low |
| 4 | `04-menu-parser.md` | STEP 4 — zero-item fallback probe (Change C) | Low | Low |
| 5 | `04-menu-parser.md` | STEP 5 — two-path discovery (Change D) | Medium | Low |
| 6 | `04-menu-parser.md` | STEP 8 — state schema (Change E) | Low | Low |

No changes to `.toml` command files — they are thin routers and don't encode agent behavior directly.
