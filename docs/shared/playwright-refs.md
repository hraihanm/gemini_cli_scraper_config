# Playwright refs vs real CSS selectors

**version:** 1.0.0

Playwright snapshots show internal references (`ref=e123`). These are **not** DOM attributes.

## Rules

- Use **refs** only as the second argument to browser **action** tools: `browser_click`, `browser_hover`, `browser_type`, etc.
- For **Ruby parsers** and **`browser_verify_selector`**, use **real CSS selectors** from `browser_inspect_element(element, ref)` first.
- **Never** put `ref=` inside `document.querySelector`, `browser_verify_selector` selector strings, or `html.css(...)`.

## Workflow

1. `browser_snapshot()` — get `ref` for interaction.
2. `browser_inspect_element('Description', 'e425')` — get real CSS selector.
3. `browser_verify_selector('Description', '.real.selector', 'expected')` — verify.
4. Use the real selector in Ruby: `html.at_css('.real.selector')`.

## Self-check (abort and fix if matched)

Before saving parser code or calling `browser_verify_selector`, reject selectors containing:

- `[ref=`, `ref="e`, `ref='e`, or `querySelector('[ref=`

If matched: call `browser_inspect_element`, then proceed with the real selector.

## Table: refs vs CSS

| Tool | Internal refs | CSS selectors |
|------|---------------|---------------|
| Navigation / click / type | Yes | Never |
| Ruby parser / verify_selector | Never | Yes |
| browser_inspect_element | Yes (ref arg) | Never as first-class |
