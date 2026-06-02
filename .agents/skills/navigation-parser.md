---
name: navigation-parser
description: Phase 2 navigation parser generation. Usage: /navigation-parser scraper=<name> [project=dmart-dloc|dhero|...] [resume-url=<url>] [out=<dir>] [auto_next=true]
---

Phase 2: Navigation parsers. Session-independent.

## Preamble
Read these shared rule files before executing anything:
1. `read_file` → `docs/shared/agent-rules-gemini.md`
2. `read_file` → `docs/shared/datahen-conventions.md`
3. `read_file` → `docs/shared/selector-discovery.md`

## Parse args
From the slash command invocation, extract: `scraper=` (required), `project=` (default `dmart-dloc`), `resume-url=`, `out=`, `auto_next=`.

## Profile and workflow
1. `read_file` → `profiles/<project>.toml`.
2. In `pipeline.phases`, locate the entry whose `command` (or `phase`) equals **`navigation-parser`** — use its `workflow` path from the profile (authoritative; do not assume a fixed index).
3. `read_file` → that workflow file.

## Execute
Follow the workflow **exactly**.

## Auto-chain
If `auto_next=true`: use **`scripts/chain.ps1`** / **`scripts/chain.sh`** per `docs/shared/agent-rules-gemini.md` with next `pipeline.phases[current_index+1].phase`, scraper, project.
