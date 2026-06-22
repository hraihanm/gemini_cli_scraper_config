---
name: run-pipeline
description: "Run a full scraper pipeline end-to-end in one session (all phases). Usage: /run-pipeline project=<dhero|dmart-dloc|greenfield|...> url=<url> name=<slug> [kind=html|api] [spec=<path>] [out=<dir>]"
---

When the user types `/run-pipeline ...`, execute **every phase** of a project's pipeline back-to-back **in a single `agy` session**, handing off between phases via state files. This is the native replacement for the old per-phase `chain.ps1`/`chain.sh` scripts.

## Preamble
Firmware rules apply via `AGENTS.md`; also `read_file` → `docs/shared/agent-rules-gemini.md`. Load KB spokes per phase as needed (index: `docs/shared/KB_HUB.md`): `docs/shared/datahen-conventions.md`, `docs/shared/selector-discovery.md`, `docs/shared/output-hash-rules.md`, `docs/shared/parser-testing.md`.

## Parse args
From the invocation, extract: `project=` (required), `url=` (required for phase 1), `name=` (required), `kind=` (optional), `spec=`, `out=`.

## Load profile
`read_file` → `profiles/<project>.toml`. Resolve `kind`: use the `kind=` arg if given, else the profile's `[defaults] kind` if set, else `html`. Select the phase array:
- `kind=html` → `pipeline.phases[]`
- `kind=api`  → `api_pipeline.phases[]`

(For dhero both arrays are the same fetch-agnostic 5 phases; the seeding strategy from Phase 1 decides API vs HTML, so the default `kind=api` is safe.)

## Execute all phases
For each phase entry **in order**:
1. `read_file` → the phase's `workflow` doc (authoritative path from the profile).
2. Run that phase to completion exactly as its dedicated skill would (same arg semantics: phase 1 uses `url=`/`name=`; later phases use `scraper=<name>`/`project=<project>`).
3. On success, continue to the next entry **in this same session** via its state file — do **not** spawn a new process.
4. On failure of any phase: **STOP**, write the `_log` structural-error entry per `docs/shared/datahen-conventions.md`, surface the error, and print the manual `/<failed.command> scraper=<name> project=<project>` line so the user can resume.

## Final QA gate
If the profile defines a `[qa]` section (dhero, dmart-dloc, and greenfield all do), after the final phase succeeds run its `[qa].command` **in the same session** before summarizing — i.e. `/qa scraper=<name> project=<project>`. The eval gate is **mandatory** here: `/qa` runs the report with `--require-eval`, so a scraper with no eval fixture/score is **not deployable**. Pass `--model` and any `--telemetry` you tracked. This produces `spec.csv`, `GENERATION_REPORT.md`, and `deploy-readiness.json`. Treat `deployable:false` as a pipeline failure: surface the `_blocking` items and STOP rather than reporting success.

After the final phase (and QA gate, if any), emit a one-paragraph run summary (phases completed, queued/parsed counts, nil-rate warnings, and the `deployable` verdict).
