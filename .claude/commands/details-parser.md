
When the user types `/details-parser ...`, run **Phase 3: Details parser**. Session-independent.

## Preamble
Firmware rules apply via `AGENTS.md`; also `read_file` → `docs/shared/agent-rules-gemini.md`. Load KB spokes as needed (index: `docs/shared/KB_HUB.md`): `read_file` → `docs/shared/datahen-conventions.md`, `docs/shared/selector-discovery.md`, `docs/shared/output-hash-rules.md`.

## Parse args
From the invocation, extract: `scraper=`, `project=` (default `dmart-dloc`), `url=`, `spec=`, `collection=`, `resume-url=`, `out=`, `auto_next=`.

## Load profile and phase doc
1. `read_file` → `profiles/<project>.toml`.
2. Find the pipeline phase for **`details-parser`** — read its `workflow` path from the profile (authoritative). Note whether this is the **last** phase.
3. `read_file` → that phase doc.

## Execute
Follow the phase doc **exactly**.

## Auto-chain (in-session)
Only if this is **not** the last phase and `auto_next=true`: read the next `pipeline.phases[]` entry and begin it **in this same session** via its state file — no new process. Otherwise emit the final summary only. On failure, print the manual `/<next.command> ...` line.

## Phase report (required before marking done)
After all state files are written and parser tests pass: write `.scraper-state/reports/03-details-parser.md` (or the appropriate slug from the profile).
Follow the two-zone schema in `docs/shared/phase-report-spec.md` (template: `templates/phase-report-template.md`).
Zone 1 = structured table (required rows). Zone 2 = free narrative.

## Write scraper README (if last phase)
If this **is** the last phase: write `generated_scraper/<scraper>/README.md` using the template at `templates/scraper-readme-template.md`. Fill in the Summary table (site URL from `lib/headers.rb`, country/language/currency from the output hash, pipeline from active parsers in `config.yaml`). Add Key implementation notes for anything non-obvious (JSON-LD vs CSS strategy, CDN pattern, discount logic, etc.). List 2–3 real URLs used during `parser_tester` validation in "Tested against". Set Status to **Functional** if all active parsers passed; otherwise **Draft**.
