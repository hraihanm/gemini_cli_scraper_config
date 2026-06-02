---
name: restaurant-details-parser
description: DHero Phase 3 restaurant details parser. project must be dhero. Usage: /restaurant-details-parser scraper=<name> project=dhero [url=...] [resume-url=...] [auto_next=true]
---

DHero Phase 3 — restaurant details (session-independent).

## Preamble
Read these shared rule files before executing anything:
1. `read_file` → `docs/shared/agent-rules-gemini.md`
2. `read_file` → `docs/shared/datahen-conventions.md`
3. `read_file` → `docs/shared/selector-discovery.md`

## Parse args
From the slash command invocation, extract: `scraper=` (required), `project=` (must be **`dhero`**), `url=`, `resume-url=`, `out=`, `auto_next=`.

## Profile and workflow
1. `read_file` → `profiles/dhero.toml`.
2. Find pipeline phase **`restaurant-details-parser`** — read its **`workflow`** path (authoritative).
3. `read_file` → that workflow; execute every STEP.

## Auto-chain
Chain via **`scripts/chain.ps1`** / **`scripts/chain.sh`** when `auto_next=true` (next phase is usually **`menu-listings-parser`**).
