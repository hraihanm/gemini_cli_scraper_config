
When the user types `/greenfield-scrape ...`, run **Greenfield site discovery** — force **`project=greenfield`**. The output schema is **not** loaded from a default file: derive it from **this entire invocation** (slash args + everything the user wrote below the slash line), in **any** format (prose, bullets, sections, tables, pasted tickets).

## Preamble
Firmware rules apply via `AGENTS.md`; also `read_file` → `docs/shared/agent-rules-gemini.md`. Load KB spokes as needed (index: `docs/shared/KB_HUB.md`): `read_file` → `docs/shared/datahen-conventions.md`, `docs/shared/greenfield-prompt-spec.md`.

## User brief (flexible)
Read the invocation plus **all narrative text under the command**. From it, extract: start/listing URLs, caveats, crawl constraints, refresh cadence, and **every output field** into `field-spec.json` per the greenfield-prompt-spec rules. Only use a disk spec if the user put **`spec=<path>`** on the slash line.

## Parse args
From the invocation, extract: `url=` (required), `name=` (required), `project=greenfield` (force if unset), optional `spec=` (advanced file override), `out=`, `auto_next=` (default false).

## Load profile and phase doc
1. `read_file` → `profiles/greenfield.toml`.
2. From the profile read `pipeline.phases[0].workflow` (authoritative).
3. `read_file` → that phase doc.

## Execute
Follow the phase doc **exactly**.

## Auto-chain (in-session)
If `auto_next=true`: read `pipeline.phases[1]` from the profile and begin it **in this same session** via its state file, with **`project=greenfield`** — no new process. On failure, print the manual `/<next.command> scraper=<name> project=greenfield` line.
