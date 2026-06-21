---
name: navigation-parser
description: "Phase 2 navigation parser generation. Usage: /navigation-parser scraper=<name> [project=dmart-dloc|dhero|...] [resume-url=<url>] [out=<dir>] [auto_next=true]"
---

When the user types `/navigation-parser ...`, run **Phase 2: Navigation parsers**. Session-independent.

## Preamble
Firmware rules apply via `AGENTS.md`; also `read_file` → `docs/shared/agent-rules-gemini.md`. The **datahen-conventions** and **selector-discovery** skills apply (auto-loaded; fall back to `read_file` of `docs/shared/datahen-conventions.md` and `docs/shared/selector-discovery.md`).

## Parse args
From the invocation, extract: `scraper=` (required), `project=` (default `dmart-dloc`), `resume-url=`, `out=`, `auto_next=`.

## Load profile and phase doc
1. `read_file` → `profiles/<project>.toml`.
2. In `pipeline.phases`, locate the entry whose `command` (or `phase`) equals **`navigation-parser`** — use its `workflow` path from the profile (authoritative; do not assume a fixed index).
3. `read_file` → that phase doc.

## Execute
Follow the phase doc **exactly**.

## Auto-chain (in-session)
If `auto_next=true`: read the next `pipeline.phases[]` entry after the current one and begin it **in this same session** via its state file — no new process. On failure, print the manual `/<next.command> scraper=<scraper> project=<project>` line.
