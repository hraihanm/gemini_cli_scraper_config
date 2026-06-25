
When the user types `/scrape ...`, run **Phase 1: Site Discovery**. Session-independent — drive everything from state files and the project profile.

## Preamble
Firmware rules are always in effect via `AGENTS.md`. Also `read_file` → `docs/shared/agent-rules-gemini.md` and follow ALL rules unconditionally. Load KB spokes as needed (index: `docs/shared/KB_HUB.md`): `read_file` → `docs/shared/datahen-conventions.md`.

## Parse args
From the invocation, extract: `url=` (required), `name=` (required), `project=` (default `dmart-dloc`), `spec=`, `out=`, `auto_next=` (default false).

## Load profile and phase doc
1. `read_file` → `profiles/<project>.toml` (resolve `<project>` from args).
2. From the profile read `pipeline.phases[0]` — note its `workflow` path (authoritative — do not hardcode).
3. `read_file` → that phase doc.

## Execute
Follow the phase doc **exactly** (all STEPs). Apply the template substitutions it defines (`{output_dir}`, `{scraper}`, `{project}`, `<next_phase_from_profile>`, etc.).

## Phase report (required before marking done)
After all state files are written: write `.scraper-state/reports/01-scrape.md`.
Follow the two-zone schema in `docs/shared/phase-report-spec.md` (template: `templates/phase-report-template.md`).
Zone 1 = structured table (required rows). Zone 2 = free narrative (observations, surprises, next-phase watch-outs).

## Auto-chain (in-session)
If `auto_next=true`: close the browser, then read `pipeline.phases[1]` from the profile and **immediately begin that phase in this same session** using its state file — do **not** spawn a new process or shell script. If the next phase fails, stop and print the manual `/<pipeline.phases[1].command> scraper=<name> project=<project>` line for the user.
