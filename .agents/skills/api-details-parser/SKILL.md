---
name: api-details-parser
description: "API Phase 3 detail parser. Usage: /api-details-parser scraper=<name> [project=dmart-dloc] [url=...] [spec=...] [auto_next=true]"
---

When the user types `/api-details-parser ...`, run **API Phase 3** — generic.

## Preamble
Firmware rules apply via `AGENTS.md`; also `read_file` → `docs/shared/agent-rules-gemini.md`. The **datahen-conventions**, **selector-discovery**, and **output-hash-rules** skills apply (auto-loaded; fall back to the matching `docs/shared/*.md`).

## Parse args
From the invocation, extract: `scraper=`, `project=`, `url=`, `spec=`, `auto_next=`.

## Load profile and phase doc
1. `read_file` → `profiles/<project>.toml`.
2. In **`api_pipeline.phases`**, find **`api-details-parser`** — read its **`workflow`** path (authoritative). Note whether this is the **last** API phase.
3. `read_file` → that phase doc; execute exactly.

## Auto-chain (in-session)
If this is the **last** API phase, do not chain — emit the final summary. Otherwise, if `auto_next=true`, read the next `api_pipeline.phases[]` entry and begin it **in this same session** via its state file — no new process.
