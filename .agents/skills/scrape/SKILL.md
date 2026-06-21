---
name: scrape
description: "Phase 1 site discovery and boilerplate initialization. Usage: /scrape url=<url> name=<slug> [project=dmart-dloc|dhero|...] [spec=<path>] [out=<dir>] [auto_next=true]"
---

When the user types `/scrape ...`, run **Phase 1: Site Discovery**. Session-independent — drive everything from state files and the project profile.

## Preamble
Firmware rules are always in effect via `AGENTS.md`. Also `read_file` → `docs/shared/agent-rules-gemini.md` and follow ALL rules unconditionally. The **datahen-conventions** skill applies (auto-loaded by semantic match; if not present, `read_file` → `docs/shared/datahen-conventions.md`).

## Parse args
From the invocation, extract: `url=` (required), `name=` (required), `project=` (default `dmart-dloc`), `spec=`, `out=`, `auto_next=` (default false).

## Load profile and phase doc
1. `read_file` → `profiles/<project>.toml` (resolve `<project>` from args).
2. From the profile read `pipeline.phases[0]` — note its `workflow` path (authoritative — do not hardcode).
3. `read_file` → that phase doc.

## Execute
Follow the phase doc **exactly** (all STEPs). Apply the template substitutions it defines (`{output_dir}`, `{scraper}`, `{project}`, `<next_phase_from_profile>`, etc.).

## Auto-chain (in-session)
If `auto_next=true`: close the browser, then read `pipeline.phases[1]` from the profile and **immediately begin that phase in this same session** using its state file — do **not** spawn a new process or shell script. If the next phase fails, stop and print the manual `/<pipeline.phases[1].command> scraper=<name> project=<project>` line for the user.
