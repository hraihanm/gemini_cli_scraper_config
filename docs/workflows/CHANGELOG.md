# Workflow & command prompt changelog

## 2.1.0 — 2026-05-01

- **Greenfield pipeline:** `profiles/greenfield.toml`, `templates/greenfield_boilerplate/`, workflows `greenfield-01` … `greenfield-03`, shard `docs/shared/greenfield-prompt-spec.md`, slash command `/greenfield-scrape`. Schema is **message-only** by default (no `field_spec` in profile); optional `spec=` path on the command line.

## 2.0.0 — 2026-04-23

- **State files:** Merged human prose into JSON `_notes` (Phase 1–4 + API stubs); deprecated parallel `*-knowledge.md` for new runs (legacy files still readable for migration).
- **Reliability:** Canonical Gemini tool names (`read_file`, `write_file`, `run_terminal_cmd`); removed `ReadManyFiles` / `WriteFile` guidance; documented `.gemini/settings.json` ignore flags.
- **Auto-chain:** `scripts/chain.ps1` / `scripts/chain.sh` replace hand-built nested PowerShell strings.
- **Accuracy:** Pagination fallback chain + `pagination_warning`; listings URL dedup; multi-page selector verification; batched field discovery by region; locale-aware price + category vars fallback; nil-guard after `parser_tester`.
- **Commands:** Generic TOMLs use `@{...}` injection; `dmart-*` / `dhero-*` / `dmart-api-*` are thin aliases; added `/api-scrape`, `/api-navigation-parser`, `/api-details-parser`.
- **Firmware:** `.gemini/system.md` slimmed to ~firmware-only; playbooks moved under `docs/shared/*.md`.
- **Observability:** Session audits require real `tool_call_counts` (or `tool_call_counts_incomplete`).
