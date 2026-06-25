# Browser MCP tools reference

**version:** 2.0.0

---

## After navigation

After each `browser_navigate`, handle cookies/modals before deep work (see popup sequence in `docs/shared/agent-rules-gemini.md`). Ignore console logs, 404s, and third-party script errors — focus on DOM structure.

---

## Tool reference

### Discovery

| Tool | When to use |
|---|---|
| `browser_snapshot()` | Always first — gets structure and refs |
| `browser_grep_html(query, ...)` | Search raw HTML for text/regex with context snippets — preferred over snapshot for selector discovery |
| `browser_inspect_element(ref)` | Get real CSS selector from a snapshot ref. Supports `batch` array |
| `browser_verify_selector(selector, expected)` | Confirm selector matches expected text. Supports `attribute` param for non-text verification and `batch` array |
| `browser_evaluate(fn)` | Quick DOM probes; verify non-text attributes (src, href, data-*) |
| `browser_count_selector(selector, min?, max?)` | Count DOM matches with assertions |
| `browser_view_html()` | **Last resort** — dumps full sanitized page HTML. High token cost. Justify before use |

### Structured data / images

| Tool | When to use |
|---|---|
| `browser_extract_json_ld(type?)` | Detail pages: try this before CSS selector work. Returns parsed JSON-LD blocks filtered by `@type` |
| `browser_extract_images(container_selector, limit?)` | Gallery containers with lazy-load — extracts all image URLs |

### Network / API

| Tool | When to use |
|---|---|
| `browser_network_requests_simplified()` | API discovery — filtered request list (prefer over `browser_network_requests()`) |
| `browser_network_search(query, searchIn?)` | Grep request URLs, headers, response bodies |
| `browser_network_download(url_pattern, dest)` | Save a network response body to file |
| `browser_network_replay(url_pattern, dest?)` | Find captured request by URL pattern + replay it |
| `browser_network_request(url, options?)` | Make HTTP request from browser context (inherits cookies) |
| `browser_get_request_context(url_pattern)` | Full request context (headers, cookies, body) — headers pre-classified stable vs ephemeral |

### Navigation / pagination

| Tool | When to use |
|---|---|
| `browser_detect_pagination(current_url)` | Call at start of navigation work — auto-detects pagination strategy |

---

## Discovery workflow (canonical order)

```
browser_grep_html(query: "<visible text>")
  → read selector from HTML snippet
  → browser_inspect_element(ref) if snippet is ambiguous
  → browser_verify_selector(selector, expected)  ← text fields
  → browser_evaluate("document.querySelector(…).src")  ← images, data-*
  → browser_view_html()  ← last resort only
```

---

## `browser_verify_selector` — text only

`browser_verify_selector` confirms **text content** only. It cannot verify:
- Image `src` or `srcset`
- `href` URLs
- `data-*` attributes
- Any non-text attribute

For those, use `browser_evaluate`:
```javascript
// ✅ Verify image src
browser_evaluate("document.querySelector('.product-image img').src")

// ✅ Verify data attribute
browser_evaluate("document.querySelector('[data-product-id]').dataset.productId")

// ✅ Verify href
browser_evaluate("document.querySelector('a.product-link').href")
```

---

## Fetch type (`fetch_type`)

| Value | When to use |
|---|---|
| `"standard"` | Default. Raw HTTP — use for HTML pages and ALL API endpoints (JSON/XML). Browser returns XML/HTML-wrapped content, not raw JSON |
| `"browser"` | JavaScript-rendered pages only. Requires `browser_fetcher_image` in `config.yaml` |

**API rule:** API endpoints MUST use `fetch_type: "standard"` — never `"browser"` for APIs.

When using `fetch_type: "browser"`, add to `config.yaml`:
```yaml
browser_fetcher_image: gcr.io/answers-engine-cloud/fetch-browser-chrome1
```

---

## Driver code — Puppeteer only

Driver code runs in **Puppeteer** (via Browserless). Playwright pseudo-selectors crash. See `docs/shared/datahen-conventions.md` → "Browser Fetch" for full rules and valid patterns.

Quick reference — forbidden vs valid:
```javascript
// ❌ Playwright-only pseudo-selectors
await page.click('button:has-text("Submit")');
await page.$('span:text("Buy now")');

// ✅ XPath (Puppeteer supports $x)
const [btn] = await page.$x('//button[contains(., "Submit")]');
if (btn) await btn.click();

// ✅ evaluate with text filter
await page.evaluate(() => {
  const btn = [...document.querySelectorAll('button')].find(b => b.textContent.includes('Submit'));
  if (btn) btn.click();
});
```

---

## Expensive tool justification

Before `browser_view_html`, `browser_network_download`, `browser_network_request`, or any full-page pull, write one justification line:

```
💭 browser_view_html: expect category nav links in sidebar — grep returned 0 matches suggesting dynamic render
```

---

## Overlay / popup handling

1. `browser_snapshot()` immediately after navigate — check for blocking overlays
2. Look for cookie consent banners, age gates, location selectors — handle before selector work
3. Use `browser_click(ref)` with the dismiss/accept button ref
4. Record the successful dismiss strategy in discovery state so later phases can replay it
5. If overlay re-appears on subsequent pages, add dismissal to the driver code for that page type

---

## Selector verification — do on 2–3 pages of the same type

Verify selectors on 2–3 different pages of the same `page_type` before writing parser code. A selector that works on page 1 may break on pages with different product variants, out-of-stock items, or sale badges.

Do not ship `*_PLACEHOLDER` selectors.
