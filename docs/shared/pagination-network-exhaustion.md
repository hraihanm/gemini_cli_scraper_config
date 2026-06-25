# Pagination & Network-Exhaustion Protocol

**version:** 1.0.0

**Used by:** Phase 1 (STEP 8c), Phase 4 (STEP 4), /run-pipeline mandate.

A "list surface" is any page or API layer that fans out to more URLs — product category listings, restaurant lists, menu category tabs, search-result pages. Every list surface MUST be exhausted before the phase is marked complete.

---

## Mandatory Probe Sequence

Run these three steps on every identified list surface, in order:

### Step 1 — Static detect

```javascript
browser_detect_pagination()
```

Returns strategy hint (`count`, `next_button`, `url_pattern`) and page/item counts if visible in DOM. This covers obvious HTML pagination only.

### Step 2 — Interaction probe

Perform each of these; wait 1–2 s for network after each action:

1. **Scroll** — scroll to page bottom 2–3 times (use `browser_evaluate(() => window.scrollTo(0, document.body.scrollHeight))`)
2. **Load-more / infinite scroll** — click any "Load more" / "Show more" button if present
3. **Tab / filter clicks** — click each visible category chip, cuisine filter, or menu section tab one by one

After each interaction run:

```javascript
browser_network_requests_simplified()
```

Watch for new JSON requests that weren't present on initial page load.

### Step 3 — Network capture

After interactions, run targeted search:

```javascript
browser_network_search({ query: "<expected_api_keyword>", searchIn: ["requestUrl", "responseBody"] })
```

Use `browser_get_request_context` on any promising URL to classify headers as stable vs ephemeral.

---

## Classification (required result)

Record the discovered strategy in `discovery-state.json.pagination_surfaces` (one entry per surface):

| Strategy | When |
|---|---|
| `page_number` | `?page=N` or `pageNumber=N` param, explicit total |
| `offset` | `?offset=N` or `from=N`, step by page size |
| `cursor` | GraphQL `pageInfo.endCursor` / REST `nextCursor` |
| `infinite_scroll` | scroll triggers XHR with offset/token — no explicit total |
| `geo_fanout` | one request per lat/long or hex cell |
| `next_button` | HTML next-page link; follow until absent |
| `none` | **Evidence required** — see below |

### `none` is only valid when

All three of the following are logged in `_log` and recorded in `evidence`:

1. `browser_detect_pagination` returned no strategy
2. Scrolled to bottom 3 times — no new network requests appeared
3. Clicked every visible tab/filter/category — no new network requests appeared

A `none` without this evidence is a **structural error** (stop the phase, surface to user).

---

## State schema — `pagination_surfaces`

Add this array to `discovery-state.json` (Phase 1) or `menu-listings-state.json` (Phase 4):

```json
"pagination_surfaces": [
  {
    "surface": "restaurant_list | menu_categories | product_listings | category_listings",
    "strategy": "page_number | offset | cursor | infinite_scroll | geo_fanout | next_button | none",
    "endpoint": "https://... or null",
    "params": ["page", "lat", "long"],
    "stable_headers": {},
    "probe_log": ["static_detect", "scroll", "tab_click", "network_capture"],
    "evidence": "scrolled 3x — no new requests; tab click on 'Burgers' triggered GET /api/menu?category=burgers",
    "pagination_warning": null
  }
]
```

Set `pagination_warning` (non-empty string) when coverage is known to be incomplete (e.g. HTML-only and no API found, total unknown).

---

## QA gate conditions

The QA gate (`/qa`) treats the following as **blocking**:

- Any list surface with `pagination_surfaces` entry missing (`null` or absent)
- Any `pagination_surfaces` entry where `strategy: "none"` and `evidence` is empty or null
- Restaurant list count < 10 and no `pagination_warning` documented
- Menu phase complete, `details_parser_needed: true`, but `menu` page count = 0 (GID collision signature — see `docs/shared/datahen-conventions.md`)

---

## GID collision guard

DataHen deduplicates pages by `MD5(url)` regardless of `page_type`. Never queue the same URL for two different purposes. If Phase 3 queues `<restaurant_url>` as `menu_listings`, Phase 4 must queue a **distinct** URL per category — either a real API endpoint with a `categoryId` param, or a URL-buster suffix like `?_cat=<category_slug>`. Queuing the identical URL again is silently dropped.

---

## Quick reference — dhero two-layer obligation

| Layer | Phase | Probe target |
|---|---|---|
| Restaurant listings | Phase 1 STEP 8c | Scroll + network during restaurant list load; geo/city API detection |
| Menu categories | Phase 4 STEP 4 | Scroll menu + click each category tab + network capture per tab |
