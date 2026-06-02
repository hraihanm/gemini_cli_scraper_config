---
name: api-navigation-parser
description: API Phase 2 navigation and listings parsers. Usage: /api-navigation-parser scraper=<name> [project=dmart-dloc] [auto_next=true]
---

API Phase 2 — generic.

## Preamble
Read these shared rule files before executing anything:
1. `read_file` → `docs/shared/agent-rules-gemini.md`
2. `read_file` → `docs/shared/datahen-conventions.md`
3. `read_file` → `docs/shared/selector-discovery.md`

## Parse args
From the slash command invocation, extract: `scraper=`, `project=`, `out=`, `auto_next=`.

## Profile and workflow
1. `read_file` → `profiles/<project>.toml`.
2. In **`api_pipeline.phases`**, find **`api-navigation-parser`** — read its **`workflow`** path.
3. `read_file` → workflow; execute exactly.

## Auto-chain
Chain to next API phase when `auto_next=true` (use **`scripts/chain.ps1`** / **`scripts/chain.sh`**).
