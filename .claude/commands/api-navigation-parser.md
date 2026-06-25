
When the user types `/api-navigation-parser ...`, run **API Phase 2** — generic.

## Preamble
Firmware rules apply via `AGENTS.md`; also `read_file` → `docs/shared/agent-rules-gemini.md`. Load KB spokes as needed (index: `docs/shared/KB_HUB.md`): `read_file` → `docs/shared/datahen-conventions.md`, `docs/shared/selector-discovery.md`.

## Parse args
From the invocation, extract: `scraper=`, `project=`, `out=`, `auto_next=`.

## Load profile and phase doc
1. `read_file` → `profiles/<project>.toml`.
2. In **`api_pipeline.phases`**, find **`api-navigation-parser`** — read its **`workflow`** path (authoritative).
3. `read_file` → that phase doc; execute exactly.

## Auto-chain (in-session)
If `auto_next=true`: read the next `api_pipeline.phases[]` entry and begin it **in this same session** via its state file — no new process. On failure, print the manual `/<next.command> ...` line.
