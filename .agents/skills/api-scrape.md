---
name: api-scrape
description: API Phase 1 boilerplate and API endpoint discovery. Usage: /api-scrape url=<url> name=<scraper> [project=dmart-dloc] [spec=...] [out=...] [auto_next=true]
---

API Phase 1 — generic, session-independent.

## Preamble
Read these shared rule files before executing anything:
1. `read_file` → `docs/shared/agent-rules-gemini.md`
2. `read_file` → `docs/shared/datahen-conventions.md`

## Parse args
From the slash command invocation, extract: `url=`, `name=`, `project=` (default `dmart-dloc`), `spec=`, `out=`, `auto_next=`.

## Profile and workflow
1. `read_file` → `profiles/<project>.toml`.
2. In **`api_pipeline.phases`**, find the entry whose `command` or `phase` equals **`api-scrape`** — read its **`workflow`** path (authoritative).
3. `read_file` → that workflow file; execute every STEP.

## Auto-chain
If `auto_next=true` and a next `api_pipeline.phases` entry exists: `browser_close` then **`run_terminal_cmd`** → `pwsh -NoProfile -File scripts/chain.ps1 -Phase <next.command> -Scraper <name> -Project <project>` (or `bash scripts/chain.sh <next.command> <name> <project> true` on Unix). Use `<next.command>` from the following array element's `command` field.
