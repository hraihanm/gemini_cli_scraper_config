---
name: details-parser
description: Phase 3 detail parser (product-style). Usage: /details-parser scraper=<name> [project=dmart-dloc|...] [url=<detail_url>] [spec=<path>] [auto_next=true]
---

Phase 3: Details parser. Session-independent.

## Preamble
Read these shared rule files before executing anything:
1. `read_file` → `docs/shared/agent-rules-gemini.md`
2. `read_file` → `docs/shared/datahen-conventions.md`
3. `read_file` → `docs/shared/selector-discovery.md`
4. `read_file` → `docs/shared/output-hash-rules.md`

## Parse args
From the slash command invocation, extract: `scraper=`, `project=` (default `dmart-dloc`), `url=`, `spec=`, `collection=`, `resume-url=`, `out=`, `auto_next=`.

## Profile and workflow
1. `read_file` → `profiles/<project>.toml`.
2. Find pipeline phase for **details-parser** — read its `workflow` path from the profile (authoritative). Check if this is the **last** phase.
3. `read_file` → that workflow file.

## Execute
Follow the workflow **exactly**.

## Auto-chain
Only if **not** last phase and `auto_next=true` — chain via **`scripts/chain.ps1`** / **`scripts/chain.sh`** per agent rules; else final summary only.
