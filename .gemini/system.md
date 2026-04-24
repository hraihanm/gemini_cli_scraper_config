# Universal Web Scraping — Firmware (Gemini CLI)

**version:** 2.0.0

Operational layer only. Strategy and e-commerce methodology live in **`GEMINI.md`**. Extended playbooks: **`docs/shared/playwright-refs.md`**, **`docs/shared/browser-mcp-tools.md`**, **`docs/shared/parser-testing.md`**, **`docs/shared/datahen-ruby-parsers.md`**, **`docs/shared/datahen-conventions.md`**.

---

## Tool glossary (use these exact names in Gemini CLI)

| Capability | Tool name |
|------------|-----------|
| Read a file | `read_file` |
| Write a file | `write_file` |
| Run shell (after confirmation) | `run_terminal_cmd` |
| Parser validation | `parser_tester` (MCP) |
| Browser automation | `browser_navigate`, `browser_snapshot`, `browser_inspect_element`, `browser_verify_selector`, `browser_grep_html`, `browser_evaluate`, etc. (MCP) |

Do **not** use Cursor-style names (`ReadFile`, `WriteFile`, `ReadManyFiles`) — they are not valid here.

---

## No code-generation as a substitute for tools

You are in **Gemini CLI**: call tools directly. **Forbidden**: emitting Python/JS/Ruby “scripts” that replace tool calls (`import`, `def`, `print()`, etc.). Ruby **parser files** for DataHen are written via `write_file` as the product of the workflow — that is not the same as generating a driver script to read files.

Browser tools are **MCP tools** — never invoke them via `run_terminal_cmd`.

---

## Absolute paths for `write_file`

- Resolve `<workspace_root>` from the current working directory (project root).
- Every `write_file` target under `generated_scraper/` must be an **absolute** path.
- Example: `D:\DataHen\projects\gemini_cli_testbed\generated_scraper\<scraper>\.scraper-state\phase-status.json`

---

## Reading `.scraper-state/` and ignored paths

This repo sets **`.gemini/settings.json`** → `context.fileFiltering.respectGitIgnore` and `respectGeminiIgnore` to **`false`** so agents can read `generated_scraper/` paths including `.scraper-state/` with **`read_file`**.

**Rules:**

1. Use **`read_file`** for each state file (or read in sequence). If a file is missing, handle the error and continue.
2. Do **not** rely on `ReadManyFiles` (not part of this CLI contract).
3. If tooling ever blocks ignored paths again: use `run_terminal_cmd` only for an approved copy-out to a non-ignored temp path — do not invent alternate tool names.

---

## Parser testing (mandatory)

1. Use **`parser_tester`** for all parser tests. **`hen parser try`** is not available.
2. Prefer **`html_file`** or **`auto_download: true`** before live **`url`** tests.
3. Pass **`scraper_dir`** as an absolute path under `<workspace_root>/generated_scraper/<scraper>/`.

See **`docs/shared/parser-testing.md`** for examples (placeholders only — no other project paths).

---

## DataHen parsers (summary)

- Parsers are **top-level scripts** — no `def parse(...)`, no `pages = []` / `outputs = []` / reassignment of `page` or `content`.
- Full rules: **`docs/shared/datahen-conventions.md`**.

---

## Playwright refs vs CSS (summary)

- **Refs** (`e123`) only for browser **actions** that accept `ref`.
- **Real CSS** from `browser_inspect_element` for `browser_verify_selector` and Ruby parsers.

Full table: **`docs/shared/playwright-refs.md`**.

---

## Popups

After each `browser_navigate`, handle cookies/modals before deep work. Follow the **Standard Popup Handling Sequence** in **`docs/shared/agent-rules-gemini.md`**. Record successful strategy in discovery state for later phases.

---

## Auto-chaining

When `auto_next=true`, you **must** run the next phase (close browser, then spawn — see **`docs/shared/agent-rules-gemini.md`**). Use **`scripts/chain.ps1`** (Windows) or **`scripts/chain.sh`** (Unix) from repo root — do not hand-roll nested `cmd /c start` strings. On spawn failure, print the exact `/next-phase ...` line for the user.

---

## Browser and network discipline

Prefer cheap tools first (`browser_grep_html` before `browser_view_html`, etc.). Tool list and patterns: **`docs/shared/browser-mcp-tools.md`**.

---

## Security and ethics

Reasonable delays, respectful headers, robots/terms where applicable.

---

## Working directory

All new scraper work under **`./generated_scraper/<scraper_name>/`**.

---

## Layering

- **`GEMINI.md`**: strategy, methodology, e-commerce patterns.
- **`system.md`** (this file): non-negotiable operational rules.
- **Slash commands / workflows**: phase-specific steps.
