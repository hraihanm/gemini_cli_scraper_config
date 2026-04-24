# API Phase 1: API-oriented site / endpoint discovery

**version:** 1.0.0

**Profile:** use `[[api_pipeline.phases]]` from `profiles/<project>.toml` — this file is referenced by the phase whose `workflow` points here.

## Goal

Copy boilerplate, discover **JSON/XML API** endpoints (XHR/fetch), capture sample responses, configure seeder for `fetch_type: "standard"` on API pages where raw JSON is required.

## Rules

- **Gemini CLI:** use tools directly (`read_file`, `write_file`, `browser_*`, `parser_tester`, `run_terminal_cmd`). No Python driver scripts.
- **Absolute paths** for all `write_file` targets.
- **API fetch:** prefer `fetch_type: "standard"` for API URLs; use browser first only to capture cookies/session if needed.
- **Expensive tools:** justify before `browser_view_html`, `browser_network_download`, `browser_request` (see `docs/shared/agent-rules-gemini.md`).

## Steps (summary)

1. Load profile + prior state (if any) under `generated_scraper/<scraper>/.scraper-state/`.
2. Copy template from profile `template.copy_command_*` into `{output_dir}/<scraper>/`.
3. Copy field spec into `.scraper-state/field-spec.json` via shell copy (not read/write JSON).
4. `browser_navigate` target site; handle popups; `browser_network_requests_simplified` / `browser_network_search` to find listing/product API URLs.
5. `browser_network_download` or `browser_request` to save sample JSON bodies under `.scraper-state/` or `cache/` (absolute paths).
6. Update `seeder/seeder.rb`, `lib/headers.rb`, `config.yaml` for API URLs, cookies, and page_types.
7. Write merged discovery state JSON with `_notes` (same pattern as HTML Phase 1 — include `api_endpoints`, auth notes, next command from `api_pipeline`).
8. Write `session-audit-api_scrape.json` with **real** `tool_call_counts` (or `tool_call_counts_incomplete`).
9. Completion report + optional auto-chain to next `api_pipeline` phase via `scripts/chain.ps1` / `scripts/chain.sh`.

Extend with project-specific details as needed.
