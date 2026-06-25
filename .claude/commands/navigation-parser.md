
When the user types `/navigation-parser ...`, run **Phase 2: Navigation parsers**. Session-independent.

## Preamble
Firmware rules apply via `AGENTS.md`; also `read_file` → `docs/shared/agent-rules-gemini.md`. Load KB spokes as needed (index: `docs/shared/KB_HUB.md`): `read_file` → `docs/shared/datahen-conventions.md`, `docs/shared/selector-discovery.md`.

## Parse args
From the invocation, extract: `scraper=` (required), `project=` (default `dmart-dloc`), `resume-url=`, `out=`, `auto_next=`.

## Load profile and phase doc
1. `read_file` → `profiles/<project>.toml`.
2. In `pipeline.phases`, locate the entry whose `command` (or `phase`) equals **`navigation-parser`** — use its `workflow` path from the profile (authoritative; do not assume a fixed index).
3. `read_file` → that phase doc.

## Execute
Follow the phase doc **exactly**.

## Phase report (required before marking done)
After all state files are written: write `.scraper-state/reports/02-navigation-parser.md`.
Follow the two-zone schema in `docs/shared/phase-report-spec.md` (template: `templates/phase-report-template.md`).
Zone 1 = structured table (required rows). Zone 2 = free narrative.

## Auto-chain (in-session)
If `auto_next=true`: read the next `pipeline.phases[]` entry after the current one and begin it **in this same session** via its state file — no new process. On failure, print the manual `/<next.command> scraper=<scraper> project=<project>` line.
