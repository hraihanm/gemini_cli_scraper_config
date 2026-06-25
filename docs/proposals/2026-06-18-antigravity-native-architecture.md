# Proposal: Antigravity CLI Native Architecture (Workflows + Skills)

**Created:** 2026-06-18
**Status:** Done
**Scope:** `.agents/` (skills → split into `workflows/` + knowledge `skills/`), `docs/shared/`, `scripts/setup-agy.ps1`, `scripts/chain.*`, `.gemini/`, `GEMINI.md`, `.antigravitycli/`, `CLAUDE.md`, `AGENTS.md`, `.gitignore`

## 1. Background

Gemini CLI (`gemini`) was deprecated 2026-06-18; the replacement is **Antigravity CLI** (`agy`). The first migration (`docs/proposals/2026-06-02-antigravity-cli-migration.md`, Done) was a literal 1:1 port — Gemini TOML slash commands became `.agents/skills/<name>/SKILL.md`, and `GEMINI.md` + `.gemini/system.md` merged into `AGENTS.md`. It did not adopt Antigravity's **native three-layer model**, and subsequent commits left the repo internally inconsistent.

Official docs (codelabs.developers.google.com "Authoring Antigravity Skills" and "Autonomous AI Developer Pipelines"; Medium "Configuring MCP Servers and Skills for Antigravity CLI and IDE") establish three distinct layers:

| Layer | Path | Role | Loaded |
|---|---|---|---|
| **AGENTS.md** | repo root | persona + firmware rules | always (prepended to every prompt) |
| **Skills** | `.agents/skills/<name>/SKILL.md` | reusable knowledge | on-demand, semantic match on `description` |
| **Workflows** | `.agents/workflows/*.md` | slash commands that orchestrate & chain skills in one session | on `/<name>` |

SKILL.md frontmatter: `name` (optional, lowercase-hyphen) + `description` (mandatory trigger phrase; only frontmatter is indexed, body loads on activation). Workflow frontmatter: `description` + body describing the orchestration for `/<cmd>`.

## 2. Current State

- **No `.agents/workflows/` directory exists.** Phase entry-points are modeled as *skills* (`.agents/skills/scrape/SKILL.md:1`, etc.) that parse args, `read_file` a `profiles/<project>.toml`, then `read_file` a `docs/workflows/phases/NN-*.md` doc.
- **Multi-phase chaining is external.** Each skill's `## Auto-chain` section spawns the next phase via `run_terminal_cmd` calling `scripts/chain.ps1` / `scripts/chain.sh` — a fresh `agy` process per phase (e.g. `.agents/skills/scrape/SKILL.md:25`).
- **Triplicate skill copies.** Every skill exists three times: `.agents/skills/<n>.md` (flat), `.agents/skills/<n>/SKILL.md`, and `.agents/plugins/gemini_cli_testbed/skills/<n>/SKILL.md`.
- **Self-contradiction.** `scripts/setup-agy.ps1:11-12` states *"Workspace skills live ONLY in `.agents/skills/<name>/SKILL.md` (no flat `*.md`, no `plugin.json` at `.agents/` root)"* — yet commit `4004fa8` re-added the flat files and `.agents/plugin.json` exists.
- **Leftover Gemini-era artifacts:** `.gemini/`, `GEMINI.md`, `.antigravitycli/` (empty).
- **Knowledge docs** live in `docs/shared/*.md` (10 files) and are pulled in via explicit `read_file` from skill preambles — not exposed as Antigravity skills at all.

## 3. Problems

1. The native orchestration layer (`workflows/`) is unused; orchestration is bolted onto skills + shell scripts.
2. External per-phase `agy` re-invocation is heavier and less reliable than native in-session chaining; couples the pipeline to OS-specific scripts.
3. Triplicate skill copies risk double-registration in the Skills panel and guarantee drift; the setup script's own contract is violated.
4. Reusable knowledge is invisible to Antigravity's semantic skill router — no on-demand loading benefit.
5. Dead Gemini artifacts confuse the active toolchain.

## 4. Proposal

### 4.1 Three-layer split

- **Workflows** (`.agents/workflows/*.md`) — 10 phase commands + `run-pipeline.md`. Each owns arg parsing, profile lookup, which knowledge skills/phase-docs to read, execution, and **in-session** chaining. Replaces the skill routers + chain scripts.
- **Skills** (`.agents/skills/<name>/SKILL.md`) — one per reusable `docs/shared/*.md` knowledge doc (except `agent-rules-gemini.md`, which is firmware referenced by AGENTS.md). Frontmatter carries a strong semantic `description`; the body is a thin pointer to the canonical `docs/shared/X.md` so there is exactly **one source of truth** and existing cross-references keep working.
- **AGENTS.md** — unchanged role (persona + firmware); refs updated.

### 4.2 In-session chaining (replaces chain.ps1/sh)

Workflow `## Auto-chain` becomes:

> When the phase completes and `auto_next=true`, read the next entry in `profiles/<project>.toml` `pipeline.phases[]` (or `api_pipeline.phases[]`), and immediately begin that phase **in this same session** using its state file — do not spawn a new process. If a phase fails, stop and surface the manual `/<next-phase> ...` line.

`run-pipeline.md` runs the whole `pipeline.phases[]` array end-to-end in one session.

### 4.3 Single canonical source

Author once under `.agents/skills` + `.agents/workflows`. `scripts/setup-agy.ps1` syncs both to global paths and stages the plugin `skills/` at install time. The staged `.agents/plugins/gemini_cli_testbed/skills/` is `.gitignore`d (generated). The `.agents/plugins/gemini_cli_testbed/plugin.json` manifest is the only plugin manifest; root `.agents/plugin.json` is removed.

### 4.4 Removals

`scripts/chain.ps1`, `scripts/chain.sh`, `.gemini/`, `GEMINI.md`, `.antigravitycli/`, all flat `.agents/skills/*.md`, all phase-router `.agents/skills/*/SKILL.md`, checked-in `.agents/plugins/.../skills/**`, `.agents/plugin.json`.

## 5. Implementation Order

| Step | Action | Effort | Risk |
|---|---|---|---|
| 0 | This proposal (`In Progress`) | S | — |
| 1 | Create `.agents/workflows/` (10 phases + run-pipeline) | M | Low |
| 2 | Create knowledge `.agents/skills/<name>/SKILL.md` (semantic pointers) | M | Low |
| 3 | Delete triplicate skills + root `plugin.json` | S | Low |
| 4 | Delete `chain.*`, `.gemini/`, `GEMINI.md`, `.antigravitycli/`; clean refs | S | Low |
| 5 | Update `setup-agy.ps1` (sync workflows+skills) + `.gitignore` | S | Med (global path verify) |
| 6 | Update `CLAUDE.md` + `AGENTS.md` | M | Low |
| 7 | Verify (`agy plugin validate`, `git grep`, drift check); flip to `Done` | S | Low |

### Open items
- Global skills path (`~/.gemini/antigravity-cli/skills/` vs `~/.gemini/config/skills/`) — docs disagree; verify empirically with `agy inspect`/`--help` before finalizing the script.
- Confirm `agy` auto-discovers workspace `.agents/workflows/` as slash commands; if not, rely on the plugin-install path (setup script already does this).
