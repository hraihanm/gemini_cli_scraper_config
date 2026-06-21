---
name: menu-listings-parser
description: DHero Phase 4 menu listings parser. Discovers menu category/page URLs and queues them. Usage: /menu-listings-parser scraper=<name> project=dhero [url=...] [resume-url=...] [auto_next=true]
---

When the user types `/menu-listings-parser ...`, run **DHero Phase 4 — menu listings parser**.

## Preamble
Firmware rules apply via `AGENTS.md`; also `read_file` → `docs/shared/agent-rules-gemini.md`. The **datahen-conventions** and **selector-discovery** skills apply (auto-loaded; fall back to the matching `docs/shared/*.md`).

## Parse args
From the invocation, extract: `scraper=`, `project=` (must be **`dhero`**), `url=`, `resume-url=`, `out=`, `auto_next=`.

## Load profile and phase doc
1. `read_file` → `profiles/dhero.toml`.
2. Find the pipeline phase **`menu-listings-parser`** — read its **`workflow`** path (authoritative).
3. `read_file` → that phase doc; execute every STEP.

## Auto-chain (in-session)
If `auto_next=true`: begin **`menu-parser`** (the next `pipeline.phases[]` entry) **in this same session** via its state file — no new process. On failure, print the manual `/menu-parser scraper=<scraper> project=dhero` line.
