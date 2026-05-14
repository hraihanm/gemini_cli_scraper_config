# API Phase 1: API-oriented site / endpoint discovery

**version:** 1.1.0

**Profile:** use `[[api_pipeline.phases]]` from `profiles/<project>.toml` — this file is referenced by the phase whose `workflow` points here.

## Goal

Copy boilerplate, discover **JSON/XML API** endpoints (XHR/fetch), verify they work (with or without custom headers), capture stable headers, configure seeder for `fetch_type: "standard"` on API pages.

## Rules

- **Gemini CLI:** use tools directly (`read_file`, `write_file`, `browser_*`, `parser_tester`, `run_terminal_cmd`). No Python driver scripts.
- **Absolute paths** for all `write_file` targets.
- **API fetch:** prefer `fetch_type: "standard"` for API URLs; use browser first only to capture session state if needed.
- **Expensive tools:** justify before `browser_view_html`, `browser_network_download`, `browser_request` (see `docs/shared/agent-rules-gemini.md`).
- **Never ship a bare API URL** — always test first; always add `headers:` if the bare test fails.

## Steps

### 1. Load profile + prior state
Load `profiles/<project>.toml`. Read state files from `generated_scraper/<scraper>/.scraper-state/` if they exist.

### 2. Copy boilerplate template
Run copy command from profile. Verify key files exist.

### 3. Copy field spec
Shell copy (not read/write JSON) into `.scraper-state/field-spec.json`.

### 4. Navigate and discover API endpoints

`browser_navigate` to target site. Handle popups. Then:
```javascript
browser_network_requests_simplified()
// Look for XHR/fetch calls returning JSON — listing endpoints, search endpoints, category endpoints
browser_network_search({ query: "api", searchIn: ["url"] })
```

Record all discovered API endpoints with URL patterns, HTTP method, and query params.

### 5. Verify each API endpoint — header test protocol

**Do this for every discovered API endpoint before writing any code.**

**Step A — Test bare:**
```javascript
browser_request({ url: "<endpoint_url_with_sample_params>", method: "GET" })
```
If response contains real data → bare fetch works, no custom headers needed. Note `requires_custom_headers: false`.

If response is empty `{}` / `[]` / error → proceed to Step B.

**Step B — Capture headers from browser request:**
```javascript
browser_network_search({ query: "<endpoint_url_substring>", searchIn: ["url"], includeHeaders: true })
```
Read `requestHeaders` from the matched entry. Classify:

| Class | Examples | Action |
|---|---|---|
| **Stable** — safe to hardcode | `appversion`, `language`, `platform`, `deviceid`, `latitude`, `longitude`, `accept`, `content-type`, `origin`, `referer` | Include in `API_HEADERS` |
| **Ephemeral** — expires per session | `cookie`, `authorization` bearer tokens, `traceparent`, `x-datadog-*`, `tracestate` | Note only — do NOT hardcode |

**Step C — Test with stable headers only:**
```javascript
browser_request({
  url: "<endpoint_url>",
  method: "GET",
  headers: { /* stable headers only */ }
})
```
- Success → record stable headers; `requires_browser_session: false`
- Still empty → `requires_browser_session: true`; document in `_notes`; this endpoint may need a live session or token-refresh mechanism

### 6. Download sample responses
```javascript
browser_network_download({ url: "<api_url>", filename: "<absolute_path>/cache/<name>.json" })
```
Save at least one sample response per endpoint type. Verify the JSON structure.

### 7. Update boilerplate files

**`lib/headers.rb`:**
- Update `URLs::BASE_URL`
- If `requires_custom_headers: true`, add `API_HEADERS` to `ReqHeaders` module:
  ```ruby
  API_HEADERS = MINIMAL_HEADERS.merge({
    "header-name" => "value",
    # one entry per stable header
  })
  ```

**`seeder/seeder.rb`:**
- Set correct API URL and pagination pattern
- If `requires_custom_headers: true`: add `headers: ReqHeaders::API_HEADERS, fetch_type: "standard"` to every `pages <<` entry targeting an API URL
- If bare fetch works: `fetch_type: "standard"` only (no `headers:` key needed)

**`config.yaml`:** verify parsers array is correct.

### 8. Write discovery state JSON

Path: `generated_scraper/<scraper>/.scraper-state/discovery-state.json`

Include `api_config` block:
```json
{
  "scraper_name": "<scraper>",
  "project": "<project>",
  "site_url": "<url>",
  "discovered_at": "<timestamp>",
  "api_endpoints": [
    {
      "name": "merchants_listing",
      "url_pattern": "https://example.com/api/v1/items?category={id}&page={n}",
      "method": "GET",
      "sample_response_file": ".scraper-state/cache/merchants_page1.json"
    }
  ],
  "api_config": {
    "has_api": true,
    "endpoint_pattern": "<url_pattern>",
    "requires_custom_headers": true,
    "stable_headers": {
      "header-name": "value"
    },
    "ephemeral_headers_noted": ["cookie", "traceparent"],
    "requires_browser_session": false,
    "bare_test": "empty_response",
    "headers_test": "success_N_items"
  },
  "_notes": "## API Discovery\\n\\n- Endpoints found\\n- Header test results\\n- Pagination pattern\\n- **Next:** `/<next_phase> scraper=<scraper> project=<project>`\\n"
}
```

### 9. Write session audit + completion report

Write `session-audit-api_scrape.json` with real `tool_call_counts`. Display completion report with next command from `api_pipeline.phases`.

### 10. Auto-chain (if auto_next=true)

Spawn next phase via `scripts/chain.ps1` / `scripts/chain.sh` using `<next.command>` from profile pipeline.
