# Scraper Generator — Draft Architecture & PRD Outline

## Goal

Build a robust, resilient **scraper generator** that, given a website homepage URL and a structured "what to scrape" spec, produces a working Datahen parser. The system uses a Gemini CLI-based orchestrator and lightweight subagents (Gemini Pro for orchestrator, Gemini Flash for subagents). Agents communicate via the filesystem as persistent state. Subagents may use Playwright (via MCP) to interact with the website. The output is a parser artifact (Datahen parser package) and metadata + test results.

---

## High-level overview
  
1. **Input**: homepage URL + structured scrape-spec (JSON/YAML) describing target data fields, selection hints, pagination expectations, auth needs, and output format.
2. **Orchestrator (Gemini Pro)**: top-level coordinator. Takes input, validates it, creates a work plan, spawns subagents, aggregates results, runs end-to-end validation, and emits final artifact & report.
3. **Subagents (Gemini Flash)**: specialized workers that perform narrow tasks (site reconnaissance, selector synthesis, extraction tests, pagination handling, auth/cookie handling, transform rules, packaging into Datahen format). Each subagent executes sequentially in an orchestrated workflow.
4. **Communication / Persistence**: file-based state stored on disk (or in an attachable shared volume). Each task writes state files (JSON) and logs to dedicated directories. Atomic file writes + advisory locks used.
5. **Browser Automation (Playwright via MCP)**: subagents that need to interact with pages do so through Playwright MCP; orchestrator provides MCP credentials/endpoint details.
6. **Output**: Datahen parser package + test cases (sample inputs/outputs), coverage report, reproducible run logs, and a PRD-style report.

---

## Why filesystem-based state

* Survivability: if orchestrator or a subagent crashes, the filesystem stores progress and enables resume/retry.
* Observability: operators can inspect files to understand state.
* Simplicity: no external queueing system required for initial MVP.

Trade-offs: requires careful concurrency control (locking) and garbage collection of stale state files.

---

## Components & Responsibilities

### 1) Orchestrator (Gemini Pro)

* Validate incoming spec and URL.
* Create workspace directory structure for the run.
* Determine sequence of subagents to spawn based on spec complexity.
* Spawn subagents (Gemini Flash) via CLI with arguments pointing to workspace & task descriptor file.
* Monitor subagent exit codes and outputs.
* Aggregate results, run final validations (synthetic data run + full site run if allowed), and build Datahen package.
* Push artifacts to artifact store (optional) and return final status.

### 2) Subagent templates (Gemini Flash)

Each subagent is a focused script/agent that consumes a task JSON and writes results JSON.
Suggested subagents:

* **Recon**: crawl site sitemap/robots, collect sample pages for patterns, detect SPA vs MPA, JS-heavy pages.
* **FieldDiscovery**: given sample pages, propose CSS/XPath selectors for each requested field; propose fallbacks and scoring.
* **PaginationHandler**: detect if pagination exists; propose pagination strategy (next-link, API, infinite scroll) and a sample iterator.
* **AuthHandler**: handle login flows (form-based, token-based); optionally record steps to replay with Playwright.
* **TransformSuggester**: propose data transforms (date parsing, numeric cleaning, currency, normalization).
* **TestRunner**: run candidate parsers against sample pages, produce accuracy/coverage metrics.
* **Packager**: assemble Datahen parser package with metadata, tests, and README.

Each subagent MUST:

* Consume `task.json` in its working folder.
* Write `result.json` and `log.txt` atomically.
* Use exit codes to communicate success/failure.

### 3) Shared libraries / helpers

* **State manager**: atomic write helpers, lock manager (file lock), state schema validator.
* **Playwright MCP client**: an adapter to acquire browsers and run scripted flows inside subagents.
* **Selector synthesizer**: utilities to create robust CSS/XPath selectors from DOM samples.

---

## Workspace & File layout (per-run)

```
/workspaces/run-<uuid>/
  input.json             # original input spec
  plan.json              # orchestrator plan (list of tasks)
  tasks/
    000_recon/
      task.json
      result.json
      log.txt
      samples/            # html snapshots, screenshots
    010_field_discovery/
    020_pagination/
    030_auth/
    900_packaging/
  artifacts/
    datahen_package.tar.gz
    test_report.json
  locks/
  meta.json              # run metadata, status
  logs/
```

Naming conventions: numeric prefix to ensure ordering. `meta.json` contains top-level state machine state.

---

## Task / State JSON schemas (examples)

### input.json (brief)

```json
{
  "homepage": "https://example.com",
  "spec": {
    "name": "example-products",
    "fields": [
      {"id":"title","type":"string","hint":"product title"},
      {"id":"price","type":"currency","hint":"price"},
      {"id":"image","type":"url","hint":"main image"}
    ],
    "pagination": {"expected": true},
    "auth": {"required": false}
  },
  "options": {"max_pages": 100, "headless": true}
}
```

### task.json (for subagent)

```json
{
  "task_id": "000_recon",
  "input_file": "../input.json",
  "timeout_s": 300,
  "workdir": ".",
  "params": { ... }
}
```

### result.json (subagent output)

```json
{
  "task_id":"000_recon",
  "status":"ok",
  "samples":["samples/page1.html","samples/page2.html"],
  "meta": {"is_spa": false, "sitemap_found": true}
}
```

---

## Locking & Atomic Writes

* Use advisory file locks (flock or lockfile) before writing `result.json` or `meta.json`.
* Write to a temporary file + atomic rename for each file write.
* Keep `locks/` directory as markers for currently running tasks.
* Orchestrator should mark tasks `in_progress` and `completed` in `meta.json`.

---

## Playwright MCP integration

* Subagents that need browsers call a small local `mcp_client` library.
* `mcp_client` uses the Playwright MCP API, requests a browser, runs a Playwright script, obtains snapshots and page HTML, and returns them to the subagent.
* Security: orchestrator provides scoped credentials (short-lived tokens) to subagents.
* For resiliency, each Playwright session should have its own snapshot directory stored under the task's `samples/`.

---

## Selector synthesis & robustness

* For every candidate selector, store: `selector`, `method` (css/xpath), `score` (uniqueness, stability across samples), `example_html_snippet`.
* Prefer data-attributes, semantic tags, and text-anchored selectors.
* Provide fallback selectors with decreasing scores.

---

## Pagination strategies

* **Next-page link**: CSS/XPath look for rel="next" or "next" text, or incremental page params.
* **Cursor/API**: detect XHR calls when scrolling; use developer tools traces from Playwright to discover API endpoints.
* **Infinite scroll**: emulate scroll in Playwright and capture XHR calls or appended DOM blocks.

Subagent should return a `pager.json` describing the strategy and a small runner that yields page URLs or XHR payloads.

---

## Authentication handling

* Basic forms: replayable with username/password in Playwright script.
* Token flows: capture token from network trace if the site uses it; store capture steps.
* Captchas: detect and mark as `manual_intervention_required`.
* NEVER persist real user credentials in plain text. Use secret store integration or ephemeral test accounts.

---

## Packaging into Datahen parser

* Conform to Datahen expected structure (config, extractor rules, transforms).
* Include `tests/` with sample pages and expected outputs.
* Include `README.md` with run instructions, known limitations, and suggested rate limits.
* Output a `datahen_package.tar.gz` in `artifacts/`.

---

## Testing & Validation

* Unit tests: run simple unit checks on synthesized selectors (does selector match expected sample?).
* Integration tests: run the Datahen parser against a subset of live pages (with politeness/rate limits) and produce precision/recall metrics.
* Regression tests: store baseline outputs to compare and detect drift.

---

## Observability & Telemetry

* `logs/` contain agent stdout/stderr and structured tracing events.
* `test_report.json` lists field-level precision/recall, number of pages scraped, errors.
* Emit metrics: successful_runs, failed_runs, avg_time_per_task, selector_success_rate.

---

## Error handling & retries

* Subagents should retry transient network errors with backoff (Playwright-level). Non-transient failures must be flagged.
* Orchestrator decides retry policy per task; avoid infinite retries.
* If a subagent crashes and leaves partial `result.json`, orchestrator can either resume from that state or restart the task.

---

## Security considerations

* Run Playwright in sandboxed environment (unprivileged user).
* Limit outbound network to necessary domains if possible.
* Avoid storing secrets; if needed, use system secret manager and provide short-lived tokens to subagents.
* Scan outputs for PII leakage before publishing.

---

## CLI / Commands (examples)

* Start orchestrator run (local):

  ```bash
  gemini orchestrator run --input input.json --workspace /workspaces/run-<uuid>
  ```
* Subagent invocation (spawned by orchestrator):

  ```bash
  gemini subagent run --task tasks/000_recon/task.json --workspace /workspaces/run-<uuid>
  ```
* Check status (simple):

  ```bash
  cat /workspaces/run-<uuid>/meta.json
  tail -f /workspaces/run-<uuid>/logs/orchestrator.log
  ```

---

## Example workflow (step-by-step)

1. User provides `input.json` with URL + spec.
2. Orchestrator performs `Recon` to gather samples and detect site type.
3. Orchestrator schedules `FieldDiscovery` to propose selectors.
4. Orchestrator runs `PaginationHandler` and `AuthHandler` if needed.
5. Orchestrator runs `TestRunner` to verify field extraction on samples.
6. Orchestrator runs `Packager` to assemble Datahen artifact.
7. Orchestrator returns `artifacts/datahen_package.tar.gz` and `test_report.json`.

---

## MVP vs Future Enhancements

**MVP**

* File-based orchestrator + sequential subagents.
* Playwright MCP integration for sampling pages.
* Field discovery for basic CSS selectors.
* Packaging + basic validation tests.

**Future**

* Parallel subagent execution with dependency tracking.
* Central state DB (SQLite/Postgres) for querying runs.
* UI dashboard to inspect runs and re-run tasks.
* Auto-maintenance: automatic re-check and re-generate parsers when site changes.
* Smart selector repair using ML models trained on historical runs.

---

## Deliverables for PRD

1. Architecture diagram & component responsibilities.
2. File-based state protocol (schemas, locking rules).
3. Subagent definitions & task schemas.
4. Playwright MCP integration spec and security guidelines.
5. Example CLI commands and run flow.
6. Acceptance criteria and test plan.
7. Roadmap & milestones (MVP, v1, v2).

---

## Acceptance criteria (examples)

* Given a valid homepage + spec, system produces a Datahen parser package and test report within defined resource limits.
* Field-level extraction precision & recall >= 85% on sample pages for MVP-supported field types.
* System recovers from a subagent crash and can resume or cleanly rerun the failed task.

---

## Next steps (how I can help)

* Iterate on the subagent list and refine task schemas.
* Design concrete `task.json` and `result.json` schemas for each subagent.
* Produce a PRD-ready markdown with diagrams for stakeholder review.

*End of draft.*
