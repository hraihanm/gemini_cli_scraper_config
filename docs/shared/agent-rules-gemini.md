# Agent Rules — Gemini CLI

**version:** 2.0.0

Shard included by slash-command prompts (`@{docs/shared/agent-rules-gemini.md}`). **Firmware** (no-code-gen, tool glossary, state-read policy) lives in **`.gemini/system.md`** — follow that first.

---

## CRITICAL: NEVER CALL BROWSER TOOLS VIA SHELL

🚨 **CRITICAL: NEVER CALL BROWSER TOOLS VIA SHELL** 🚨
- Browser tools (`browser_navigate`, `browser_snapshot`, `browser_grep_html`, `browser_network_search`, etc.) are **MCP tools** — call them **directly** as tool calls
- **WRONG** ❌: `run_terminal_cmd("gemini -y -i 'browser_navigate(...); browser_snapshot()'")`
- **RIGHT** ✅: Call `browser_navigate({ url: "..." })` directly as a tool
- `run_terminal_cmd` / shell is **ONLY** for auto-chaining at the very end. Never for browser actions.

---

## CRITICAL: ABSOLUTE PATHS REQUIRED

🚨 CRITICAL - ABSOLUTE PATHS REQUIRED:
- **ALL `write_file` operations MUST use ABSOLUTE PATHS** - Relative paths will fail
- Before writing any file, convert relative path to absolute:
  * Determine workspace root (current working directory)
  * Convert: `generated_scraper/<scraper>/.scraper-state/file.json`
  * To absolute: `<workspace_root>/generated_scraper/<scraper>/.scraper-state/file.json`
  * Example: `D:\\DataHen\\projects\\gemini_cli_testbed\\generated_scraper\\naivas_online\\.scraper-state\\phase-status.json`
- Use absolute paths for: `phase-status.json`, `discovery-state.json` (includes human `_notes` — see workflows), `browser-context.json`, selector JSON files
- **browser-context.json location**: `generated_scraper/<scraper>/.scraper-state/browser-context.json` (scraper-specific, NOT global)

---

## Browser Tools: Popup Handling

🚨 BROWSER TOOLS FOR NAVIGATION AND POPUP HANDLING:
- **browser_screenshot()**: Use to visually inspect pages for popups, modals, cookie banners
- **browser_click()**: Use to interact with elements (navigation, popups, cookies, notifications)
- **browser_snapshot()**: Use to check for overlays and get accessibility tree
- **MANDATORY**: After every `browser_navigate()`, check for and handle popups before proceeding
- Common popup patterns: cookie banners, notification overlays, modal dialogs, age verification
- Always use `browser_snapshot()` after handling popups to verify page is ready

### Standard Popup Handling Sequence (run after every browser_navigate)

a) **Check for existing strategy**: Read `discovery-state.json` `popup_handling` section if available
b) **Check for popups**: `browser_snapshot()` + `browser_screenshot()`
c) **Strategy 1 — ESC key**: `browser_press_key("Escape")` → verify dismissed
d) **Strategy 2 — Upper-left click**: `browser_mouse_click_xy("Upper left corner", 10, 10)` → verify dismissed
e) **Strategy 3 — Selector-based**: Try `[id*="cookie"]`, `button:contains("Accept")`, `button:contains("Later")`
f) **Strategy 4 — Coordinate click**: AI vision to locate button → `browser_mouse_click_xy()`
g) **Final verification**: `browser_snapshot()` — only proceed after confirmed clear

**Document successful strategy** in `discovery-state.json` under `popup_handling` for reuse in later phases.

---

## Expensive Tool Justification

🚨 **EXPENSIVE TOOL JUSTIFICATION** (required before each expensive call):
Before calling `browser_view_html`, `browser_network_download`, `browser_request`, or `datahen_run`, write one line:
  💭 [tool]: [what I expect to find/confirm] → [why not a cheaper alternative]

Examples:
  💭 browser_view_html: need full DOM for category list — browser_grep_html returned no results
  💭 datahen_run step: running listings parser to verify pagination vars flow to details

Always try cheap alternatives first: `browser_grep_html` before `browser_view_html`, `browser_network_search` before `browser_network_download`/`browser_request`

---

## Auto-Chaining Rules

🚨 **CRITICAL AUTO-CHAINING EXECUTION RULE**:
- **MANDATORY**: If `auto_next=true` parameter is provided in `{{args}}`, you MUST execute the next command automatically
- **DO NOT** just display the command - you MUST execute it using `run_terminal_cmd` tool
- **DO NOT** skip execution - the execution is MANDATORY, not optional
- Failure to execute when `auto_next=true` is a completion failure

### How to determine the next command (GENERIC — reads from profile)

**CRITICAL**: Do NOT hardcode the next command name. Look it up from the project profile.

1. Read `profiles/<project>.toml` (already loaded earlier in this session)
2. Find the `[[pipeline.phases]]` array
3. Locate the entry where `phase` matches the CURRENT command's phase name
4. The NEXT command is `pipeline.phases[current_index + 1].phase`
5. If current phase is LAST in the pipeline: display completion summary only, no chaining

### Auto-chain execution steps (when auto_next=true)

**Step A — Close browser**:
- Call `browser_close()` MCP tool — REQUIRED before spawning new console

**Step B — Spawn next command (use repo scripts — no hand-rolled nested quotes)**:
- Ensure current working directory is the **repository root** (where `scripts/` lives).
- **Windows**: run via `run_terminal_cmd`:
  `pwsh -NoProfile -File scripts/chain.ps1 -Phase <next_phase> -Scraper <scraper_slug> -Project <project>`
  Replace `<next_phase>` with the pipeline lookup value (e.g. `navigation-parser`). Use **absolute** path to `scripts/chain.ps1` if not cwd-root.
- **macOS/Linux**: run:
  `bash scripts/chain.sh <next_phase> <scraper_slug> <project> true`
- If spawn **fails**, log is appended to `.gemini/auto-chain.log` — print this line for the user:
  `gemini -y -i "/<next_phase> scraper=<scraper_slug> project=<project> auto_next=true"`

**Step C — Store shell info** (for consistency):
```json
{
  "shell_type": "PowerShell_or_Bash",
  "standardized_at": "<timestamp>",
  "spawn_command_template": "pwsh -File scripts/chain.ps1 -Phase <phase> -Scraper <slug> -Project <proj>"
}
```
Write to `.gemini/shell-info.json` using **`write_file`** with an **ABSOLUTE** path.

---

## Stop Rules

🚨🚨🚨 **MANDATORY: STOP AFTER COMPLETION (if auto_next=false)** 🚨🚨🚨
- **IF auto_next=false or not provided**: After displaying completion summary, you MUST STOP
- **DO NOT continue with any other work, tasks, or projects**
- **DO NOT create new scrapers, directories, or todo lists**
- **DO NOT start any new work**
- **This command is COMPLETE - END SESSION NOW**
- **Wait for user's next command - do not proceed autonomously**
- **IF auto_next=true**: Follow auto-chain steps above to spawn next command, then END
