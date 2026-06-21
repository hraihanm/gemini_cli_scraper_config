---
name: restaurant-details-parser
description: "DHero Phase 3 restaurant details parser. project must be dhero. Usage: /restaurant-details-parser scraper=<name> project=dhero [url=...] [resume-url=...] [auto_next=true]"
---

When the user types `/restaurant-details-parser ...`, run **DHero Phase 3 — restaurant details**. Session-independent.

## Preamble
Firmware rules apply via `AGENTS.md`; also `read_file` → `docs/shared/agent-rules-gemini.md`. The **datahen-conventions** and **selector-discovery** skills apply (auto-loaded; fall back to the matching `docs/shared/*.md`).

## Parse args
From the invocation, extract: `scraper=` (required), `project=` (must be **`dhero`**), `url=`, `resume-url=`, `out=`, `auto_next=`.

## Load profile and phase doc
1. `read_file` → `profiles/dhero.toml`.
2. Find the pipeline phase **`restaurant-details-parser`** — read its **`workflow`** path (authoritative).
3. `read_file` → that phase doc; execute every STEP.

## Auto-chain (in-session)
If `auto_next=true`: read the next `pipeline.phases[]` entry (usually **`menu-listings-parser`**) and begin it **in this same session** via its state file — no new process. On failure, print the manual `/<next.command> scraper=<scraper> project=dhero` line.
