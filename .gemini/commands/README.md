Usage Guide for the 3 Gemini command TOMLs
==========================================

This repo includes three CLI command prompts that drive the scraper pipeline. Use them in this order:

Requirement
-----------
- Playwright MCP Mod (experiment branch): https://github.com/hraihanm/playwright-mcp-mod/tree/experiment

1) /scrape-site (`.gemini/commands/scrape-site.toml`)
   - Goal: Site discovery — identify structure, sample URLs, popup handling, and field spec seeds.
   - Inputs: url (required), name/--scraper (required), spec (optional), out (optional), auto_next (optional).
   - Key outputs (written under `generated_scraper/<scraper>/.scraper-state/`):
     - discovery-state.json (structure, sample URLs, popup_handling strategy, urls_accessed, etc.)
     - discovery-knowledge.md (human notes)
   - Popup handling (highest priority): after navigation run
     1) ESC key via `browser_press_key("Escape")`
     2) Click upper-left corner via `browser_mouse_click_xy(..., 10, 10)`
     3) Selector-based click via `browser_click`
     4) Fallback coordinate click on the button via `browser_mouse_click_xy`
     - Log success in `popup_handling` inside discovery-state.json for reuse.

2) /create-navigation-parser (`.gemini/commands/create-navigation-parser.toml`)
   - Goal: Discover category/subcategory/listing selectors and generate navigation parsers.
   - Inputs: scraper (required), resume-url (optional), out (optional), auto_next (optional).
   - Reads from discovery-state.json and discovery-knowledge.md produced in step 1.
   - Reuses popup_handling strategy from discovery-state.json first; then follows the same ESC → corner click → selector → coordinate order.
   - Generates/updates parsers: categories.rb, subcategories.rb (if needed), listings.rb.
   - Enforces DataHen v3 parser structure (top-level script, no def parse, no pages/outputs declarations).

3) /create-details-parser (`.gemini/commands/create-details-parser.toml`)
   - Goal: Discover field selectors and generate parsers/details.rb.
   - Inputs: scraper (required), url (optional), spec (optional), collection (optional), out (optional).
   - Reads navigation-selectors.json, field-spec.json (if any), discovery-state.json/knowledge.md.
   - Reuses popup_handling strategy; follows ESC → corner click → selector → coordinate order.
   - Enforces DataHen v3 parser structure (top-level script, no def parse, no pages/outputs declarations).
   - Outputs parsers/details.rb and updates detail-selectors.json and detail-knowledge.md.

Common notes
------------
- Always use the `read_file` tool per file (batch read tools are not available).
- Always write with absolute paths (WriteFile/replace/ApplyPatch).
- After each navigation, handle popups before any other action and verify with `browser_snapshot()`.
- Coordinate clicks require `--caps=vision`.
- Keep discovery-state.json and knowledge files in sync across phases; later phases rely on them.
