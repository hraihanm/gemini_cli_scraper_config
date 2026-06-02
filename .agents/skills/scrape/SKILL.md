---
name: scrape
description: Phase 1 site discovery and boilerplate initialization. Usage: /scrape url=<url> name=<slug> [project=dmart-dloc|dhero|...] [spec=<path>] [out=<dir>] [auto_next=true]
---

Phase 1: Site Discovery. Session-independent — use state files and profile only.

## Preamble
Read these shared rule files before executing anything:
1. `read_file` → `docs/shared/agent-rules-gemini.md` (follow ALL rules unconditionally)
2. `read_file` → `docs/shared/datahen-conventions.md`

## Parse args
From the slash command invocation, extract: `url=` (required), `name=` (required), `project=` (default `dmart-dloc`), `spec=`, `out=`, `auto_next=` (default false).

## Load profile and workflow
1. `read_file` → `profiles/<project>.toml` (resolve `<project>` from args).
2. From profile read `pipeline.phases[0]` — note `workflow` path (authoritative — do not assume a hardcoded path).
3. `read_file` → that workflow file.

## Execute
Follow the workflow document **exactly** (all STEPs). Apply template substitutions the workflow defines (`{output_dir}`, `{scraper}`, `{project}`, `<next_phase_from_profile>`, etc.).

## Auto-chain
If `auto_next=true`: close browser, then spawn next phase via **`run_terminal_cmd`** using repo **`scripts/chain.ps1`** (Windows) or **`scripts/chain.sh`** (Unix) with `-Phase`/args set to `pipeline.phases[1].phase`, scraper name, and project. On failure, print the manual `/next-phase ...` line.
