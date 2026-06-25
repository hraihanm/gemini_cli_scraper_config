# Phase Report: {{PHASE_NAME}}

**Scraper:** {{SCRAPER_NAME}}
**Phase:** {{PHASE_SLUG}}  (e.g. `01-scrape`, `03-restaurant-details`)
**Completed:** {{ISO_TIMESTAMP}}
**Status:** ✅ Complete | ⚠️ Partial | ❌ Failed

---

## Structured Summary

<!-- Agent: fill every row. Use n/a only if the field genuinely does not apply to this phase. -->

| Field | Value |
|---|---|
| **Pagination surfaces found** | e.g. `restaurant_list: next-button`, `categories: none (3 probes)` |
| **Popup / modal handling** | e.g. `location modal dismissed via ESC` or `none observed` |
| **Extraction method** | e.g. `JSON-LD (Product)`, `CSS selectors`, `API JSON` |
| **Selectors verified** | e.g. `6/7 (name, price, brand, img, url, sku) — rating skipped` |
| **Parser test iterations** | e.g. `3 (2 fixes: image selector, price regex)` |
| **Parser test result** | e.g. `✅ 3/3 URLs pass, 0 nil fields on required` |
| **Eval score** | e.g. `100% (4/4 fixtures)` or `n/a (no evals yet)` |
| **Expensive tool uses** | e.g. `browser_view_html ×1 (pagination footer not visible in grep)` |
| **Structural errors** | e.g. `none` or `restaurant_address nil on all 3 test URLs` |
| **Data gaps (non-blocking)** | e.g. `original_price nil — no promo items in samples` |
| **Key decisions** | See Decision Log below |
| **Next phase ready** | ✅ Yes | ⚠️ Conditional | ❌ No |
| **Blockers for next phase** | e.g. `none` or `confirm GID buster scope before menu listings` |

### Decision Log

<!-- One row per significant decision. Copy from _log entries in the state file if present. -->

| Decision | Rationale |
|---|---|
| Used JSON-LD for name/price/brand | `@type: Product` found — more stable than CSS |
| CSS fallback for img_url | JSON-LD `image` field is thumbnail only; `og:image` gives full-size |
| Declared pagination: none (restaurant_list) | Scroll×3 + tab-click + network capture — 0 new requests; API returns all at once |

---

## Agent Narrative

<!-- Free section — write anything useful. No schema, no required fields. -->
<!-- Audience: a developer reading this cold, or you resuming after a break. -->

### What happened

<!-- Brief story: what the site looked like, what the agent found, how the session went. -->

### Surprises / anomalies

<!-- Anything unexpected: site behavior, API quirks, selector fragility, data inconsistencies. -->

### Judgment calls

<!-- Decisions where multiple paths were valid — what you picked and why. -->

### Watch out in next phase

<!-- Anything the next-phase agent should know that isn't in the state files. -->

### If I were doing this again

<!-- Retrospective: what would be faster, what was a dead end, what assumption was wrong. -->
