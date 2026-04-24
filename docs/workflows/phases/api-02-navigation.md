# API Phase 2: Navigation / listings API parsers

**version:** 1.0.0

**Profile:** `[[api_pipeline.phases]]` — workflow for API navigation parser phase.

## Goal

Implement or fix parsers that consume **API JSON** for categories/listings (no HTML CSS for primary data). Ensure pagination via API params is detected and vars flow to detail API pages.

## Rules

- Top-level Ruby scripts only (`docs/shared/datahen-conventions.md`).
- **`parser_tester`** with saved JSON bodies or `auto_download` where applicable.
- Write `navigation-selectors.json` (or API-specific state file name your profile expects) including **`_notes`**, `pagination_warning` if only first page is reachable, and **URL deduplication** for queued detail URLs.

## Steps (summary)

1. Load discovery/API state + `field-spec.json` + existing parsers.
2. For each navigation parser file (except final detail parser): discover JSON paths or small CSS wrappers if responses are HTML-wrapped; test with `parser_tester`.
3. Pagination fallback chain for APIs: offset/limit → page param → cursor → next URL from response body. Never silently single-page.
4. Smoke-test `datahen_run` steps if available.
5. Persist selector/path JSON + `_notes`; update `phase-status.json`; session audit with real tool counts.
6. Auto-chain to API details phase when `auto_next=true`.
