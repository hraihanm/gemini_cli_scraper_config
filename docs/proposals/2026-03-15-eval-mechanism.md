# Proposal: Scraper Eval Mechanism

**Created:** 2026-03-15
**Status:** In Progress
**Scope:** `playwright-mcp-mod/scraping/eval_runner.rb`, `playwright-mcp-mod/src/tools/mod/eval.ts`, `.gemini/commands/dmart-eval.toml`

## 1. Background
Parser testing currently validates one file at a time with no regression tracking. When a selector breaks or JSON-LD changes, there is no quick way to know which fields regressed. The professional agent development loop is: build → run evals → see what's nil → fix → re-run evals.

## 2. Current State
- `parser_tester` MCP tool: tests one or multiple files, returns text output
- `scraper_output_validator` MCP tool: validates one output's fields against config.yaml
- No fixture storage, no scoring, no nil-rate tracking across runs

## 3. Problem(s)
- No way to know if a change to a parser broke previously-working fields
- No quantitative score (what % of fields are populated?)
- No per-field nil rate across multiple test pages
- No repeatable test command the AI agent can run at the end of each phase

## 4. Proposal

### Fixture format
Fixtures live inside each scraper directory: `<scraper_dir>/evals/<test_name>/`
- `input.html` or `input.json` — the test content file
- `expected.json` — field assertions (see matcher syntax below)
- `meta.yaml` — optional: description, tags, notes

### expected.json matcher syntax
```json
{
  "name": "__non_nil__",
  "customer_price_lc": "__non_nil__",
  "currency_code_lc": "SAR",
  "img_url": "__non_nil__",
  "brand": "Nike"
}
```
Matchers:
- `"__non_nil__"` — field must be present and non-null
- `"__nil__"` — field must be null/nil
- `"__numeric__"` — field must be a number
- Any string/number — exact match (numbers within 1% tolerance)

### Components
1. `scraping/eval_runner.rb` — Ruby runner: finds fixtures, calls parser_tester.rb for each, compares outputs, emits JSON report
2. `src/tools/mod/eval.ts` — MCP tool `scraper_run_evals`: spawns eval_runner.rb, formats report as text
3. `.gemini/commands/dmart-eval.toml` — TOML command `/dmart-eval` for AI agent use

## 5. Implementation Order
1. Write `eval_runner.rb` (Ruby, low risk)
2. Write `eval.ts` MCP tool (moderate)
3. Update `index.ts` (trivial)
4. Write `dmart-eval.toml` (trivial)
