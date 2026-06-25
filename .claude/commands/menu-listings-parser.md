
When the user types `/menu-listings-parser ...`, run **DHero Phase 4 — menu listings parser**.

## Preamble
Firmware rules apply via `AGENTS.md`; also `read_file` → `docs/shared/agent-rules-gemini.md`. Load KB spokes as needed (index: `docs/shared/KB_HUB.md`): `read_file` → `docs/shared/datahen-conventions.md`, `docs/shared/selector-discovery.md`.

## Parse args
From the invocation, extract: `scraper=`, `project=` (must be **`dhero`**), `url=`, `resume-url=`, `out=`, `auto_next=`.

## Load profile and phase doc
1. `read_file` → `profiles/dhero.toml`.
2. Find the pipeline phase **`menu-listings-parser`** — read its **`workflow`** path (authoritative).
3. `read_file` → that phase doc; execute every STEP.

## Phase report (required before marking done)
After all state files are written and parser tests pass: write `.scraper-state/reports/04-menu-listings.md`.
Follow the two-zone schema in `docs/shared/phase-report-spec.md` (template: `templates/phase-report-template.md`).
Zone 1 = structured table (required rows). Zone 2 = free narrative.

## Auto-chain (in-session)
If `auto_next=true`: begin **`menu-parser`** (the next `pipeline.phases[]` entry) **in this same session** via its state file — no new process. On failure, print the manual `/menu-parser scraper=<scraper> project=dhero` line.
