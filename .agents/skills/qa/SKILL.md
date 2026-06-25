---
name: qa
description: "QA gate for any generated scraper — validates output vs field spec and emits spec.csv, GENERATION_REPORT.md, deploy-readiness.json. Usage: /qa scraper=<name> project=<dhero|dmart-dloc|greenfield> [eval-score=N]"
---

When the user types `/qa ...` (or as the final step of `/run-pipeline`), run a one-shot QA pass over a generated scraper and produce the deploy-readiness deliverables a dev needs to continue work or deploy directly. Works for **any** project — dhero (`locations`/`items`), dmart-dloc and greenfield (single `products`).

## Preamble
Firmware rules apply via `AGENTS.md`; also `read_file` → `docs/shared/agent-rules-gemini.md`. Load KB spokes as needed (index: `docs/shared/KB_HUB.md`): `read_file` → `docs/shared/datahen-conventions.md`, `docs/shared/output-hash-rules.md`, `docs/shared/parser-testing.md`. Canonical spec for the run lives at `<scraper_dir>/.scraper-state/field-spec.json` (copied/built in Phase 1).

## Parse args
Extract: `scraper=` (REQUIRED), `project=` (REQUIRED — `dhero` | `dmart-dloc` | `greenfield`), `eval-score=` (OPTIONAL), `out=` (default `./generated_scraper`). Scraper dir = `<out>/<scraper>`.

## STEP 1: Determine collections + their parsers
`read_file` → `<scraper_dir>/.scraper-state/field-spec.json`. Collections:
- Fields carry a `collection` key → use the distinct values (dhero: `locations`, `items`).
- No `collection` key → single collection `products` (dmart-dloc, greenfield).

Map each collection to the parser that emits it (from `profiles/<project>.toml` + config.yaml):
- dhero: `locations` ← `parsers/restaurant_details.rb`; `items` ← `parsers/menu.rb` (or inline Strategy E).
- dmart-dloc / greenfield: `products` ← `parsers/details.rb`.

## STEP 2: Collect QA samples (≥3 records per collection)
The verdict is only valid with **≥3 real records per collection** (the gate enforces this). For each collection:
1. Pick 3 representative sample pages from the phase state files (`navigation-selectors.json` / `detail-selectors.json` sampled URLs/GIDs; API scrapers use cached sample endpoints).
2. Run `parser_tester` (`auto_download: true`, `quiet: true`) on each, passing the upstream `vars` (e.g. dhero `loc_id`/`rank`/`input_lat`; dmart `category_name`/`rank`).
3. Aggregate every returned output whose `_collection` matches into one array.
4. `write_file` (absolute path) each array to `<scraper_dir>/.scraper-state/qa-samples/<collection>.json` (filename = collection name, e.g. `products.json`, `locations.json`, `items.json`).

## STEP 3: Run the eval gate (MANDATORY)
The eval gate is **required** — the report is run with `--require-eval`, so a missing score is a **blocking** failure (no vacuous pass).
1. `scraper_run_evals({ scraper_dir })`; capture the score → pass as `--eval-score`.
2. **If no fixtures exist, create one** pair from the best `parser_tester` run (`evals/<slug>/input.html` + `expected.json`), then re-run `scraper_run_evals`. Do not skip.

## STEP 4: Generate the report
```
ruby scripts/scraper_qa_report.rb "<absolute scraper_dir>" --project <project> --name <scraper> \
     --require-eval --eval-score <N> --model <model-id> [--agy-version <v>] \
     [--telemetry '{"tool_calls":<n>,"elapsed_s":<n>,"est_cost_usd":<n>}']
```
Pass `--model` (the model id used) and, if you tracked them this session, real `--telemetry` counts — they are pinned into `deploy-readiness.json._meta` for reproducibility and drift tracking.
Reads `qa-samples/*.json` (collections = filenames), the spec, and every `.scraper-state/*-state.json` `_log`; writes into the scraper dir: `spec.csv`, `GENERATION_REPORT.md`, `deploy-readiness.json`, and `DATAHEN_PROJECT.txt` (if absent). Exit: `0` deployable, `2` not deployable, `1` bad invocation.

## STEP 5: Interpret the gate
- **Hard gates** (block deploy): `samples_ok` (≥3/collection), `schema_ok` (every spec field present per collection, nil-explicit), `types_ok`, `required_fields_ok` (priority-1 fields non-nil on all samples), `ids_ok` (`_id` present + unique per collection; dhero also checks items.lead_id ⊆ locations.lead_id), and `eval_ok` (with `--require-eval`, a missing OR <80% score blocks — see `_blocking.evals_required`).
- **Warnings** (non-blocking): priority-2 fields 100% nil — confirm they are genuine data gaps vs. a broken extraction (cross-check the field's `_log` `parser_test` entries).

## STEP 6: Surface the outcome
- `deployable: true` → report the badge + warnings + the `hen scraper deploy <scraper>` sequence from the report.
- `deployable: false` → **STOP**, write a `structural_error` `_log` entry, and for each `_blocking` item name the field, collection, and precise fix (missing key → add to output hash nil-explicit; required_nil → fix extraction; type_violation → coerce; id_failure → fix id derivation). Print the re-run line: `/qa scraper=<scraper> project=<project>`.

## Auto-chain
**None** — terminal QA step. Emit the final report summary only.
