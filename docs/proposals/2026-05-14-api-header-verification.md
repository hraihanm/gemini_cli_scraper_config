# Proposal: API Header Verification Protocol

**Created:** 2026-05-14
**Status:** Done
**Scope:** `docs/workflows/phases/01-site-discovery.md`, `docs/workflows/phases/api-01-scrape.md`, `generated_scraper/snoonu_qa/lib/headers.rb`, `generated_scraper/snoonu_qa/seeder/seeder.rb`, `generated_scraper/snoonu_qa/parsers/listings.rb`

---

## 1. Background

Some sites expose their data through APIs that require custom request headers beyond standard browser headers. Examples: app version identifiers, device IDs, platform flags, geolocation coordinates, language preferences. Without these headers the API returns an empty response or an error, even though the URL is correct.

The snoonu_qa scraper surfaced this: `https://admin.snoonu.com/api/v7/web/merchants` returns empty when fetched bare. The correct request requires headers like `appversion: 2`, `snoonu-app-platform: Web`, `latitude`, `longitude`, `language`, `deviceid`.

---

## 2. Current State

- `01-site-discovery.md` STEP 7 checks whether to use `browser` vs `standard` fetch_type — no protocol for detecting or capturing required API headers.
- `api-01-scrape.md` steps 4–6 are one-liners: "update `lib/headers.rb` for cookies" — no concrete guidance.
- `lib/headers.rb` boilerplate only defines `MINIMAL_HEADERS` (Accept + User-Agent). No `API_HEADERS` concept.
- Seeder and parser `pages <<` entries carry no `headers:` key — API requests go out bare.
- snoonu_qa seeder queues the merchants API URL without headers → empty responses.

---

## 3. Problem(s)

1. **Agent doesn't test the API before committing to it.** It finds the URL via network inspection but never verifies a bare fetch works.
2. **No protocol for capturing working headers.** Even if the agent notices the response is empty, there's no instruction to use `browser_network_search` to read the successful browser request's headers.
3. **No stable vs ephemeral classification.** Session cookies and trace IDs expire; app-level headers (version, platform, language) are stable and safe to hardcode. The agent has no guidance to distinguish them.
4. **`lib/headers.rb` has no place for API headers.** The constant is missing, so parsers can't reference it.
5. **snoonu_qa is broken today** — seeder, listings pagination, and any future parser all fetch bare.

---

## 4. Proposal

### 4.1 Header verification protocol (added to both Phase 1 workflows)

Three-step protocol when an API endpoint is discovered:

**Step A — Test bare**
`browser_request({ url: api_url, method: 'GET' })` with no custom headers.
If the response contains real data → bare fetch works, no headers needed, continue.
If empty / error → proceed to Step B.

**Step B — Capture from browser**
`browser_network_search({ query: api_url, searchIn: ['url'], includeHeaders: true })`
Read the `requestHeaders` of the matching entry — this is what the browser sent when it got a real response.

Classify each header:
- **Stable** (safe to hardcode): app version, platform, language, device ID, geolocation — anything that doesn't change per session
- **Ephemeral** (do not hardcode): `cookie`, `traceparent`, `x-datadog-*`, `authorization` bearer tokens with expiry — log as a note, do not put in `headers.rb`

**Step C — Test with stable headers**
Re-run `browser_request` with only the stable headers. Confirm the response contains real data.
If still empty → some ephemeral header is required; document under `_notes` and flag `requires_browser_session: true` in state.

### 4.2 `discovery-state.json` — new `api_config` field (STEP 9)

```json
"api_config": {
  "has_api": false,
  "endpoint_pattern": null,
  "requires_custom_headers": false,
  "stable_headers": {},
  "ephemeral_headers_noted": [],
  "requires_browser_session": false,
  "bare_test": "not_tested",
  "headers_test": "not_tested"
}
```

When an API is found and tested:
```json
"api_config": {
  "has_api": true,
  "endpoint_pattern": "https://admin.snoonu.com/api/v7/web/merchants?category_id={id}&Page={n}",
  "requires_custom_headers": true,
  "stable_headers": {
    "appversion": "2",
    "language": "en",
    "snoonu-app-platform": "Web",
    "snoonu-app-version": "65535.65535.65535.65535",
    "latitude": "25.2857654",
    "longitude": "51.5315461",
    "deviceid": "web-PLACEHOLDER"
  },
  "ephemeral_headers_noted": ["cookie", "traceparent", "x-datadog-trace-id", "x-datadog-parent-id"],
  "requires_browser_session": false,
  "bare_test": "empty_response",
  "headers_test": "success_20_items"
}
```

### 4.3 `lib/headers.rb` — add `API_HEADERS` constant (STEP 10)

When `api_config.requires_custom_headers: true`, add to `lib/headers.rb`:

```ruby
module ReqHeaders
  MINIMAL_HEADERS = {
    "Accept"     => "application/json",
    "User-Agent" => "Mozilla/5.0 ...",
  }

  # Required by the site's API — discovered and verified during Phase 1
  API_HEADERS = MINIMAL_HEADERS.merge({
    "appversion"           => "2",
    "language"             => "en",
    "snoonu-app-platform"  => "Web",
    "snoonu-app-version"   => "65535.65535.65535.65535",
    "latitude"             => "25.2857654",
    "longitude"            => "51.5315461",
    "deviceid"             => "web-PLACEHOLDER",
  })
end
```

### 4.4 Seeder and parsers — add `headers:` and `fetch_type:`

All `pages <<` entries that target API endpoints must include:
```ruby
pages << {
  url:        api_url,
  page_type:  "listings",
  fetch_type: "standard",
  headers:    ReqHeaders::API_HEADERS,
  vars:       { ... }
}
```

---

## 5. Implementation Order

| Step | File | Change | Effort | Risk |
|---|---|---|---|---|
| 1 | `docs/workflows/phases/01-site-discovery.md` | Add STEP 7b (header verification protocol) + STEP 9 api_config + STEP 10 headers.rb update | Medium | None |
| 2 | `docs/workflows/phases/api-01-scrape.md` | Expand steps 4–6 with same protocol | Medium | None |
| 3 | `generated_scraper/snoonu_qa/lib/headers.rb` | Add `API_HEADERS` with stable headers from curl sample | Low | None |
| 4 | `generated_scraper/snoonu_qa/seeder/seeder.rb` | Add `headers:` + `fetch_type: 'standard'` to all pages | Low | Low |
| 5 | `generated_scraper/snoonu_qa/parsers/listings.rb` | Add `headers:` + `fetch_type: 'standard'` to pagination pages | Low | Low |
