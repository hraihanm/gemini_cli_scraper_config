# Proposal: Mandatory Pagination & Network-Exhaustion Protocol

**Created:** 2026-06-24
**Status:** Done
**Scope:** `docs/shared/pagination-network-exhaustion.md` (new spoke), `docs/workflows/phases/01-site-discovery.md`, `docs/workflows/phases/04-menu-listings.md`, `.agents/skills/run-pipeline/SKILL.md`, `docs/shared/KB_HUB.md`

---

## 1. Background

Analysis of the Snoonu KW scraper revealed two compounding failures caused by incomplete pagination discovery:

1. **Restaurant listings truncated** — Phase 1 seeded a single HTML listings page (~19 restaurants), never probing for scroll-triggered API endpoints or geo-grid pagination. The real listing API accepts `lat`/`long` headers and paginates by `page_number`, but nothing in Phase 1 forced the agent to find it.

2. **Menu items = 0** — Phase 3 queued the restaurant URL as `menu_listings`. Phase 4 re-queued the *same* URL as `menu`. DataHen's GID deduplication (MD5 of URL) silently dropped the second enqueue. Even fixing the GID collision only yields one category's worth of items, because other categories load via tab-click XHR — an interaction the current workflow never performed.

Neither failure is site-specific. Any listing surface (product categories, restaurant list, menu tabs) can exhibit the same gap: static HTML shows page 1; real data lives behind scrolls, clicks, or API calls the agent never triggered.

---

## 2. Current State

### Phase 1 (01-site-discovery.md)
- STEP 8 navigates the site and discovers page types, but has no mandatory scroll/interaction/network probe step.
- STEP 8b (dhero) picks a seeding strategy based on visible network requests during page load — but does **not** require clicking through the listing or scrolling to trigger lazy-loaded requests.
- `discovery-state.json` has `seeding.pagination` (single string) but no `pagination_surfaces` array covering all list layers.
- STEP 9b output contract does not require any pagination evidence.

### Phase 4 (04-menu-listings.md)
- STEP 4 checks for `__NEXT_DATA__`, JSON-LD, and `browser_network_requests_simplified`, but does **not** click menu category tabs or scroll before classifying structure.
- Structure D (API-driven) is discovered only from page-load requests; per-category XHR triggered by tab clicks is never probed.
- `menu-listings-state.json` has no `menu_api` field to record discovered per-category API endpoints.

### /run-pipeline skill
- No mention of pagination exhaustion across phases.

---

## 3. Problem(s)

1. **Silent under-seeding** — agents can complete Phase 1 with `strategy: url_listings` + `pagination: page_number` derived from static HTML, never discovering the geo-grid API that powers the real app.

2. **Tab/scroll endpoints invisible** — listing APIs triggered by user interaction (scroll, category-tab click, load-more) are never captured. The result is one page / one category of data on DataHen, not full coverage.

3. **GID collision** — when Phase 3 queues a URL and Phase 4 re-queues the same URL as a different `page_type`, DataHen deduplicates to the first and the second is lost. This is a symptom of interaction-blind Phase 4: it has no per-category API URLs to queue, so it falls back to the menu root URL.

4. **No enforcement** — `pagination_strategy: none` is never challenged. There is no QA gate that asks "did you scroll? did you click tabs? did you watch the network?"

---

## 4. Proposal

### 4.1 New spoke: `docs/shared/pagination-network-exhaustion.md`

A concise, task-scoped reference covering:
- What qualifies as a "list surface"
- 3-step mandatory probe sequence (static detect → interaction → network capture)
- Classification taxonomy and state schema (`pagination_surfaces` array)
- `none` evidence requirement
- QA gate conditions

### 4.2 Phase 1 — new STEP 8c

Insert "STEP 8c: Pagination Surface Probe" between STEP 8b and STEP 9. Required for **all projects**, runs on every identified list surface. Records findings in `discovery-state.json.pagination_surfaces`.

Add `pagination_surfaces` to the STEP 9 schema and STEP 9b output contract (required field, ≥1 entry per surface, `none` requires non-empty evidence string).

### 4.3 Phase 4 — strengthen STEP 4

Add a mandatory "Scroll + Network Exhaustion Probe" sub-step *before* classifying menu structure. Requires: scroll menu, click each visible category tab, run `browser_network_search` after each click, classify. Add `menu_api` to `menu-listings-state.json` schema.

### 4.4 /run-pipeline — pagination mandate paragraph

Add a one-paragraph mandate to the "Execute all phases" section: exhausting the pagination protocol is a gate before marking any list phase complete; `none` requires `_log` evidence; dhero applies the protocol twice (restaurant list in Phase 1, menu categories in Phase 4).

### 4.5 KB_HUB.md — register spoke

Add row under "Task → load these spokes" and "Spokes" table.

---

## 5. Implementation Order

| Step | File | Effort | Risk |
|---|---|---|---|
| 1 | Create `docs/shared/pagination-network-exhaustion.md` | Small | Low |
| 2 | Patch Phase 1 — add STEP 8c + schema + STEP 9b + checklist | Medium | Low |
| 3 | Patch Phase 4 — strengthen STEP 4 + state schema | Small | Low |
| 4 | Patch `/run-pipeline` SKILL.md — pagination mandate | Small | Low |
| 5 | Update `KB_HUB.md` — register new spoke | Small | Low |
