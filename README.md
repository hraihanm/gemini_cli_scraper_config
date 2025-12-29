Gemini Scraper Commands (Usage)
==============================

This repository bundles three Gemini CLI commands that scaffold a full scraper: discover the site, build navigation parsers, then build detail parsers.

Run location
------------
- Run all commands from a terminal in the repository root (this folder) so relative paths resolve correctly.

Prerequisite
------------
- Playwright MCP Mod (experiment branch): https://github.com/hraihanm/playwright-mcp-mod/tree/experiment

Gemini CLI MCP setup
--------------------
Add the MCP server to your `.gemini/settings.json` so Gemini CLI can load the Playwright MCP Mod (with vision for coordinate clicks):

```json
{
  "mcpServers": {
    "playwright-mod": {
      "command": "npx",
      "args": ["D:\\DataHen\\projects\\playwright-mcp-mod", "--caps", "vision"]
    }
  }
}
```

Quick start
-----------
Run these commands in order (adjust arguments to your target site). Use `auto_next=true` if you want the next command to run automatically after the current one finishes:

1) `/scrape-site name=<scraper_slug> url=<https://target-site/> [spec=path/to/spec.csv]`
   - Optional: `auto_next=true` will automatically call `/create-navigation-parser` when done.
2) `/create-navigation-parser scraper=<scraper_slug>`
   - Optional: `auto_next=true` will automatically call `/create-details-parser` when done.
3) `/create-details-parser scraper=<scraper_slug> [url=<sample-detail-url>] [spec=...]`

What each command does
----------------------
1) `/scrape-site` — site discovery  
   - Finds site structure, sample URLs, popup handling strategy, and seeds field specs.  
   - Saves to `generated_scraper/<scraper>/.scraper-state/`:  
     - `discovery-state.json` (structure, sample URLs, popup_handling, urls_accessed)  
     - `discovery-knowledge.md` (human-readable notes)

2) `/create-navigation-parser` — navigation discovery & parsers  
   - Reads `discovery-state.json` + `discovery-knowledge.md`.  
   - Reuses recorded `popup_handling` (selectors/coords) before trying new methods.  
   - Generates/updates `categories.rb`, `subcategories.rb` (if needed), `listings.rb`.  
   - Enforces DataHen v3 parser structure (top-level scripts, no `def parse`, no `pages = []`/`outputs = []`).

3) `/create-details-parser` — detail selectors & parser  
   - Reads `navigation-selectors.json`, `field-spec.json` (if any), and discovery files.  
   - Reuses `popup_handling` first, then follows the popup strategy order below.  
   - Outputs `parsers/details.rb`, updates `detail-selectors.json` and `detail-knowledge.md`.

Popup handling order (all commands)
-----------------------------------
1) Press ESC: `browser_press_key("Escape")`  
2) Click upper-left corner: `browser_mouse_click_xy("Upper left corner", 10, 10)`  
3) Selector-based click: `browser_click` (cookie/notify/modal buttons)  
4) Coordinate fallback on the button: `browser_mouse_click_xy` (center of button)  
5) Verify with `browser_snapshot()` and log success in `popup_handling` (for reuse)

Tips
----
- Keep `discovery-state.json` and knowledge files in sync; later phases depend on them.  
- Coordinate tools require `--caps=vision`.  
