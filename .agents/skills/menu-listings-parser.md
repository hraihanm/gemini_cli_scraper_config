---
name: menu-listings-parser
description: DHero Phase 4 menu listings parser. Discovers menu category/page URLs and queues them. Usage: /menu-listings-parser scraper=<name> project=dhero [url=...] [resume-url=...] [auto_next=true]
---

DHero Phase 4 — menu listings parser.

## Preamble
Read these shared rule files before executing anything:
1. `read_file` → `docs/shared/agent-rules-gemini.md`
2. `read_file` → `docs/shared/datahen-conventions.md`
3. `read_file` → `docs/shared/selector-discovery.md`

## Parse args
From the slash command invocation, extract: `scraper=`, `project=` (must be **`dhero`**), `url=`, `resume-url=`, `out=`, `auto_next=`.

## Profile and workflow
1. `read_file` → `profiles/dhero.toml`.
2. Find pipeline phase **`menu-listings-parser`** — read its **`workflow`** path (authoritative).
3. `read_file` → that workflow; execute every STEP.

## Auto-chain
Chain to `menu-parser` when `auto_next=true`.
