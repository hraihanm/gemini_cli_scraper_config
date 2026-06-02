---
name: greenfield-scrape
description: Greenfield Phase 1 site discovery. Output schema derived from this invocation (prose, bullets, tables). Usage: /greenfield-scrape url=<url> name=<slug> [out=<dir>] [auto_next=true] — then URLs, caveats, output fields in free text below. Optional: spec=<path> for a file.
---

Greenfield site discovery — **`project=greenfield`**. Output schema is **not** loaded from a default file: derive it from **this entire invocation** (slash args + everything below the slash line), in **any** format (prose, bullets, sections, tables, pasted tickets).

## Preamble
Read these shared rule files before executing anything:
1. `read_file` → `docs/shared/agent-rules-gemini.md`
2. `read_file` → `docs/shared/datahen-conventions.md`
3. `read_file` → `docs/shared/greenfield-prompt-spec.md`

## User brief (flexible)
Read the slash command invocation plus **all narrative text the user wrote under the command**. From that, extract: start/listing URLs, caveats, crawl constraints, refresh cadence, and **every output field** into `field-spec.json` per `greenfield-prompt-spec.md`. Only use a disk spec if the user put **`spec=<path>`** on the slash line.

## Parse args
From the slash command invocation, extract: `url=` (required), `name=` (required), `project=greenfield` (force if not set), optional `spec=` (advanced file override), `out=`, `auto_next=` (default false).

## Load profile and workflow
1. `read_file` → `profiles/greenfield.toml`.
2. From profile read `pipeline.phases[0].workflow` (authoritative).
3. `read_file` → that workflow file.

## Execute
Follow that workflow **exactly**.

## Auto-chain
If `auto_next=true`: use `scripts/chain.ps1` / `scripts/chain.sh` per `docs/shared/agent-rules-gemini.md` with next `pipeline.phases[1].phase`, scraper name, and **`Project=greenfield`**.
