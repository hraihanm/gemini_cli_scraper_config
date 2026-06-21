---
name: api-navigation-parser
description: API Phase 2 navigation and listings parsers. Usage: /api-navigation-parser scraper=<name> [project=dmart-dloc] [auto_next=true]
---

When the user types `/api-navigation-parser ...`, run **API Phase 2** — generic.

## Preamble
Firmware rules apply via `AGENTS.md`; also `read_file` → `docs/shared/agent-rules-gemini.md`. The **datahen-conventions** and **selector-discovery** skills apply (auto-loaded; fall back to the matching `docs/shared/*.md`).

## Parse args
From the invocation, extract: `scraper=`, `project=`, `out=`, `auto_next=`.

## Load profile and phase doc
1. `read_file` → `profiles/<project>.toml`.
2. In **`api_pipeline.phases`**, find **`api-navigation-parser`** — read its **`workflow`** path (authoritative).
3. `read_file` → that phase doc; execute exactly.

## Auto-chain (in-session)
If `auto_next=true`: read the next `api_pipeline.phases[]` entry and begin it **in this same session** via its state file — no new process. On failure, print the manual `/<next.command> ...` line.
