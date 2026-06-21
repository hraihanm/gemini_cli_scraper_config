---
name: greenfield-scrape
description: Greenfield Phase 1 site discovery. Output schema derived from this invocation (prose, bullets, tables). Usage: /greenfield-scrape url=<url> name=<slug> [out=<dir>] [auto_next=true] — then URLs, caveats, output fields in free text below. Optional: spec=<path> for a file.
---

When the user types `/greenfield-scrape ...`, run **Greenfield site discovery** — force **`project=greenfield`**. The output schema is **not** loaded from a default file: derive it from **this entire invocation** (slash args + everything the user wrote below the slash line), in **any** format (prose, bullets, sections, tables, pasted tickets).

## Preamble
Firmware rules apply via `AGENTS.md`; also `read_file` → `docs/shared/agent-rules-gemini.md`. The **datahen-conventions** and **greenfield-prompt-spec** skills apply (auto-loaded; fall back to the matching `docs/shared/*.md`).

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
