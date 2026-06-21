---
name: run-pipeline
description: "Run a full scraper pipeline end-to-end in one session (all phases). Usage: /run-pipeline project=<dhero|dmart-dloc|greenfield|...> url=<url> name=<slug> [kind=html|api] [spec=<path>] [out=<dir>]"
---

When the user types `/run-pipeline ...`, execute **every phase** of a project's pipeline back-to-back **in a single `agy` session**, handing off between phases via state files. This is the native replacement for the old per-phase `chain.ps1`/`chain.sh` scripts.

## Preamble
Firmware rules apply via `AGENTS.md`; also `read_file` → `docs/shared/agent-rules-gemini.md`. Relevant knowledge skills (datahen-conventions, selector-discovery, output-hash-rules, parser-testing) auto-load per phase by semantic match.

## Parse args
From the invocation, extract: `project=` (required), `url=` (required for phase 1), `name=` (required), `kind=` (`html` default, or `api`), `spec=`, `out=`.

## Load profile
`read_file` → `profiles/<project>.toml`. Select the phase array:
- `kind=html` → `pipeline.phases[]`
- `kind=api`  → `api_pipeline.phases[]`

## Execute all phases
For each phase entry **in order**:
1. `read_file` → the phase's `workflow` doc (authoritative path from the profile).
2. Run that phase to completion exactly as its dedicated skill would (same arg semantics: phase 1 uses `url=`/`name=`; later phases use `scraper=<name>`/`project=<project>`).
3. On success, continue to the next entry **in this same session** via its state file — do **not** spawn a new process.
4. On failure of any phase: **STOP**, write the `_log` structural-error entry per `docs/shared/datahen-conventions.md`, surface the error, and print the manual `/<failed.command> scraper=<name> project=<project>` line so the user can resume.

After the final phase, emit a one-paragraph run summary (phases completed, queued/parsed counts, any nil-rate warnings).
