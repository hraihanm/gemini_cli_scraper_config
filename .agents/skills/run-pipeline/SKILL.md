---
name: run-pipeline
description: "Run a full scraper pipeline end-to-end, spawning each phase as a fresh agent session. Usage: /run-pipeline project=<dhero|dmart-dloc|greenfield|...> url=<url> name=<slug> [kind=html|api] [model=<model>] [spec=<path>] [out=<dir>]"
---

Orchestrate the full pipeline by spawning each phase as a **fresh `agent` subprocess** — one session per phase, no inline chaining. The user watches progress in this session; each phase runs cold with zero accumulated context from prior phases. State files are the only handoff.

## Preamble

`read_file` → `docs/shared/agent-rules-gemini.md` (firmware rules, error taxonomy).
`read_file` → `docs/shared/KB_HUB.md` (spoke index — load spokes as needed between phases).
`read_file` → `docs/shared/pagination-network-exhaustion.md` (pagination mandate — gate-check after list phases).

## Parse args

Extract from invocation:
- `project=` — REQUIRED
- `url=` — REQUIRED (passed to Phase 1)
- `name=` — REQUIRED (scraper slug)
- `kind=` — optional; default from profile `[defaults] kind` else `html`
- `model=` — optional; default `claude-sonnet-4-6`
- `spec=` — optional; passed through to Phase 1
- `out=` — optional; default from profile

## Load profile

`read_file` → `profiles/<project>.toml`. Resolve `kind` and select phase array:
- `kind=html` → `pipeline.phases[]`
- `kind=api` → `api_pipeline.phases[]`
- dhero: both arrays are identical; default `kind=api` is safe.

## Orchestration loop

Print the pipeline plan upfront:
```
🗂  Pipeline: <project> → <name>
   Phase 1: <label>
   Phase 2: <label>
   ...
   QA gate
```

Then for each phase in order:

### 1. Print progress banner
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⏳ Spawning Phase <N>/<total>: <label>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 2. Build the agent command

**Phase 1 (index 0):**
```
agent -p --yolo --trust --model <model> "/<command> project=<project> url=<url> name=<name>[  spec=<spec>][ out=<out>]"
```

**All other phases:**
```
agent -p --yolo --trust --model <model> "/<command> scraper=<name> project=<project>"
```

### 3. Invoke via `run_terminal_cmd`

Run the command. This blocks until the subprocess exits. Do NOT proceed until it exits.

### 4. Gate-check phase-status.json

After the subprocess exits, `read_file` → `generated_scraper/<name>/.scraper-state/phase-status.json`.

Look up the phase's status key (e.g. `site_discovery`, `navigation_discovery`, `restaurant_details`, `menu_listings_discovery`, `menu_details`).

**If `status == "completed"`:**
```
✅ Phase <N> complete — <label>
```
Continue to next phase.

**If status is anything else (or file missing):**
```
⛔ Phase <N> FAILED — <label>
   Status: <status or "file missing">
```
Write a `structural_error` `_log` entry in the phase's state file if possible. Print the manual resume command:
```
agent --yolo "/<command> scraper=<name> project=<project> auto_next=true"
```
**STOP** — do not proceed to the next phase.

### 5. Pagination gate (after any list phase)

After a phase that produces a list-surface state file (`discovery-state.json`, `navigation-state.json`, `menu-listings-state.json`), `read_file` that state file and verify `pagination_surfaces` is present with at least one entry. If missing or all entries have `strategy:"none"` with empty `evidence`: print a warning but do not block (log it as `pagination_warning` in the orchestrator summary).

---

## QA gate

After the final phase succeeds, run the QA gate the same way:
```
agent -p --yolo --trust --model <model> "/qa scraper=<name> project=<project> --require-eval"
```

Read `generated_scraper/<name>/deploy-readiness.json` after it exits. If `deployable: false`: print blocking items and treat as pipeline failure.

---

## README

After QA passes, run:
```
agent -p --yolo --trust --model <model> "Write the scraper README at generated_scraper/<name>/README.md using templates/scraper-readme-template.md for scraper <name> project <project>"
```

---

## Final summary

Print:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Pipeline complete: <name> (<project>)
Phases: <N>/<N> completed
QA: deployable=<true|false>
Blocking: <list or "none">
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Pagination mandate

Before marking any list phase gate-check as passed, verify `pagination_surfaces` in that phase's state file. `strategy:"none"` with empty `evidence` is a pipeline warning — log it in the summary. Full protocol: `docs/shared/pagination-network-exhaustion.md`. For dhero: apply to both restaurant list (Phase 1) and menu categories (Phase 4). Never re-queue the same URL for a different `page_type` — distinct per-category API URLs or URL-buster suffixes required to avoid DataHen GID deduplication.

---

## Error handling

- **Subprocess non-zero exit + phase-status missing**: treat as structural failure, STOP.
- **`deployable: false` from QA**: surface `_blocking` items, do not report success.
- **Any phase failure**: print resume command as `agent --yolo "/<command> scraper=<name> project=<project> auto_next=true"` so the user can watch that phase interactively.
