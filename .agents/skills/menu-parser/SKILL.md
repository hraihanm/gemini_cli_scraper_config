---
name: menu-parser
description: "DHero Phase 5 menu details parser (final phase). Extracts items from a single menu page. Usage: /menu-parser scraper=<name> project=dhero [url=...] [resume-url=...]"
---

When the user types `/menu-parser ...`, run **DHero Phase 5 — menu details parser** (the **final** phase).

## Preamble
Firmware rules apply via `AGENTS.md`; also `read_file` → `docs/shared/agent-rules-gemini.md`. Load KB spokes as needed (index: `docs/shared/KB_HUB.md`): `read_file` → `docs/shared/datahen-conventions.md`, `docs/shared/selector-discovery.md`.

## Parse args
From the invocation, extract: `scraper=`, `project=` (**dhero**), `url=`, `resume-url=`, `out=`.

## Load profile and phase doc
1. `read_file` → `profiles/dhero.toml`.
2. Find the phase **`menu-parser`** — read its **`workflow`** path (authoritative).
3. `read_file` → that phase doc; execute every STEP.

## Phase report (required before marking done)
After all state files are written and parser tests pass: write `.scraper-state/reports/05-menu-parser.md`.
Follow the two-zone schema in `docs/shared/phase-report-spec.md` (template: `templates/phase-report-template.md`).
Zone 1 = structured table (required rows). Zone 2 = free narrative.

## Auto-chain
**None** — this is the terminal phase. Ignore `auto_next`. Emit the final summary only.
