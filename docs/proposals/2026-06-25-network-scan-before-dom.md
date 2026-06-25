# Proposal: Network Scan Before DOM Inspection in Phase 1

**Created:** 2026-06-25
**Status:** Done
**Scope:** `docs/workflows/phases/01-site-discovery.md`

## 1. Background

kifli.hu was scraped with `fetch_type: "browser"` + Playwright-style driver code clicking a nav button. The real production scraper uses `fetch_type: "standard"` + `https://www.kifli.hu/api/v4/navigation/components/navigation-tabs/categories/` directly — no browser needed. The agent never found the API because STEP 7 checks the DOM first and only scans the network later (STEP 8c, pagination probe).

## 2. Current State

`01-site-discovery.md` STEP 7 ("Detect Browser Fetch Requirements"):
1. `browser_evaluate()` — look for category links in DOM
2. If not found → look for a reveal button
3. Set `fetch_type: "browser"` if reveal button found

Network scanning (STEP 8c) runs later, primarily for pagination detection. By then the fetch_type decision is already made.

## 3. Problem

**Ordering is wrong.** The agent decides `fetch_type: "browser"` before checking whether an API already serves the data. For SPA sites (React/Vue apps that load JSON from an API), navigating the homepage fires the API call immediately — `browser_network_requests_simplified()` right after navigate would catch it. Instead the agent sees "no links in DOM" → "reveal button exists" → "use browser."

Browser fetch is slower, more fragile, requires `browser_fetcher_image` in config.yaml, and the driver code often uses Playwright pseudo-selectors that crash on DataHen's Puppeteer runtime.

## 4. Proposal

Restructure STEP 7 as a four-level priority cascade — stop at the first that works:

```
navigate
  7a: network API? (browser_network_requests_simplified — zero overhead, already captured)
       └─ yes → verify headers → fetch_type: standard, navigation_api_url set → STEP 8
  7b: framework JSON? (__NEXT_DATA__, __NUXT_DATA__, embedded JSON)
       ├─ categories baked in → parse directly, fetch_type: standard on homepage
       └─ API URL in props  → verify headers → fetch_type: standard → STEP 8
  7c: DOM links visible?
       └─ yes → fetch_type: standard, no driver → STEP 8
  7d: reveal button (last resort)
       └─ fetch_type: browser + Puppeteer driver (XPath/evaluate only, no :has-text())
```

Also:
- Add `navigation_api_url` to `api_config` in discovery-state.json schema
- STEP 10 seeder: if `navigation_api_url` is set, use it as the seed URL (not the homepage)
- STEP 10 config.yaml: if `fetch_type: "browser"` is used, uncomment `browser_fetcher_image`

## 5. Implementation Order

| Step | Change | Effort | Risk |
|---|---|---|---|
| 1 | Restructure STEP 7 in `01-site-discovery.md` | 20 min | Low |
| 2 | Add `navigation_api_url` to STEP 9 schema | 5 min | Low |
| 3 | Update STEP 10 seeder priority + config.yaml browser_fetcher_image | 10 min | Low |
| 4 | Update STEP 9b output contract + checklist | 5 min | Low |
