# Browser MCP tools reference

**version:** 1.0.0

## Before interaction

- After `browser_navigate`, handle popups (see `docs/shared/agent-rules-gemini.md` popup sequence), then `browser_snapshot()`.

## Console noise

**Ignore** console logs, 404s, and third-party script errors during automation. Focus on DOM structure and selectors.

## Discovery tools

- `browser_snapshot()` — structure and refs.
- `browser_inspect_element(element, ref)` — real CSS selector; supports `batch` for multiple elements.
- `browser_verify_selector(element, selector, expected)` — verify text or use `attribute` for `src` / `href` / `data-*`. Supports `batch`.
- `browser_grep_html(query, ...)` — search HTML; prefer over `browser_view_html` when possible.
- `browser_view_html()` — last resort (high token cost). Justify before use.
- `browser_evaluate(function)` — quick DOM probes; prefer `browser_count_selector` for counts.
- `browser_extract_json_ld(type?)` — detail pages: try before heavy CSS work.
- `browser_extract_images(container_selector, limit?)` — galleries.
- `browser_detect_pagination(current_url)` — pagination strategy hint at start of navigation work.

## Network

- Prefer `browser_network_requests_simplified()` over `browser_network_requests()` for pagination/API discovery.
- `browser_network_search`, `browser_network_download`, `browser_network_replay` — API workflows.

## Expensive tools

Before `browser_view_html`, `browser_network_download`, `browser_request`, or heavy network pulls: one line justification — what you expect and why a cheaper tool is insufficient.

## Mandatory selector verification (summary)

1. Navigate → snapshot → inspect → verify on real CSS.
2. Repeat on 2–3 pages of the same type when possible.
3. Do not ship `*_PLACEHOLDER` selectors.
