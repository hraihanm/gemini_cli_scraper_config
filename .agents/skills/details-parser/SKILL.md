---
name: details-parser
description: Phase 3 detail parser (product-style). Usage: /details-parser scraper=<name> [project=dmart-dloc|...] [url=<detail_url>] [spec=<path>] [auto_next=true]
---

When the user types `/details-parser ...`, run **Phase 3: Details parser**. Session-independent.

## Preamble
Firmware rules apply via `AGENTS.md`; also `read_file` → `docs/shared/agent-rules-gemini.md`. The **datahen-conventions**, **selector-discovery**, and **output-hash-rules** skills apply (auto-loaded; fall back to `read_file` of the matching `docs/shared/*.md`).

## Parse args
From the invocation, extract: `scraper=`, `project=` (default `dmart-dloc`), `url=`, `spec=`, `collection=`, `resume-url=`, `out=`, `auto_next=`.

## Load profile and phase doc
1. `read_file` → `profiles/<project>.toml`.
2. Find the pipeline phase for **`details-parser`** — read its `workflow` path from the profile (authoritative). Note whether this is the **last** phase.
3. `read_file` → that phase doc.

## Execute
Follow the phase doc **exactly**.

## Auto-chain (in-session)
Only if this is **not** the last phase and `auto_next=true`: read the next `pipeline.phases[]` entry and begin it **in this same session** via its state file — no new process. Otherwise emit the final summary only. On failure, print the manual `/<next.command> ...` line.
