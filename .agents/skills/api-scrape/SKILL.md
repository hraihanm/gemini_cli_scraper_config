---
name: api-scrape
description: "API Phase 1 boilerplate and API endpoint discovery. Usage: /api-scrape url=<url> name=<scraper> [project=dmart-dloc] [spec=...] [out=...] [auto_next=true]"
---

When the user types `/api-scrape ...`, run **API Phase 1** — generic, session-independent.

## Preamble
Firmware rules apply via `AGENTS.md`; also `read_file` → `docs/shared/agent-rules-gemini.md`. Load KB spokes as needed (index: `docs/shared/KB_HUB.md`): `read_file` → `docs/shared/datahen-conventions.md`.

## Parse args
From the invocation, extract: `url=`, `name=`, `project=` (default `dmart-dloc`), `spec=`, `out=`, `auto_next=`.

## Load profile and phase doc
1. `read_file` → `profiles/<project>.toml`.
2. In **`api_pipeline.phases`**, find the entry whose `command` or `phase` equals **`api-scrape`** — read its **`workflow`** path (authoritative).
3. `read_file` → that phase doc; execute every STEP.

## Auto-chain (in-session)
If `auto_next=true` and a next `api_pipeline.phases` entry exists: `browser_close`, then read that next entry and begin it **in this same session** via its state file — no new process or chain script. On failure, print the manual `/<next.command> scraper=<name> project=<project>` line.
