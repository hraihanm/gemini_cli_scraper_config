---
name: menu-parser
description: DHero Phase 5 menu details parser (final phase). Extracts items from a single menu page. Usage: /menu-parser scraper=<name> project=dhero [url=...] [resume-url=...]
---

DHero Phase 5 — menu details parser (**final** phase).

## Preamble
Read these shared rule files before executing anything:
1. `read_file` → `docs/shared/agent-rules-gemini.md`
2. `read_file` → `docs/shared/datahen-conventions.md`
3. `read_file` → `docs/shared/selector-discovery.md`

## Parse args
From the slash command invocation, extract: `scraper=`, `project=` (**dhero**), `url=`, `resume-url=`, `out=`.

## Profile and workflow
1. `read_file` → `profiles/dhero.toml`.
2. Find phase **`menu-parser`** — read its **`workflow`** path (authoritative).
3. `read_file` → that workflow; execute every STEP.

## Auto-chain
**No auto-chain** (terminal phase). Ignore `auto_next` for chaining purposes.
