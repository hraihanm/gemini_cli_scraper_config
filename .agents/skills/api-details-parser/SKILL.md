---
name: api-details-parser
description: API Phase 3 detail parser. Usage: /api-details-parser scraper=<name> [project=dmart-dloc] [url=...] [spec=...] [auto_next=true]
---

API Phase 3 — generic.

## Preamble
Read these shared rule files before executing anything:
1. `read_file` → `docs/shared/agent-rules-gemini.md`
2. `read_file` → `docs/shared/datahen-conventions.md`
3. `read_file` → `docs/shared/selector-discovery.md`
4. `read_file` → `docs/shared/output-hash-rules.md`

## Parse args
From the slash command invocation, extract: `scraper=`, `project=`, `url=`, `spec=`, `auto_next=`.

## Profile and workflow
1. `read_file` → `profiles/<project>.toml`.
2. In **`api_pipeline.phases`**, find **`api-details-parser`** — read its **`workflow`** path.
3. `read_file` → workflow; execute exactly.

## Auto-chain
If this is the **last** API phase, do not chain. Otherwise respect `auto_next` + chain script.
