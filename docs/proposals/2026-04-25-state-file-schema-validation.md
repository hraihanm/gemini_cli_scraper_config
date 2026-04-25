# Proposal: State-File Schema Validation

**Created:** 2026-04-25
**Status:** Draft
**Scope:** `docs/workflows/phases/*.md`, `schemas/state/`, optionally `../playwright-mcp-mod/src/tools/mod/`

---

## 1. Background

State files in `.scraper-state/` are the inter-phase contract: Phase 1 writes `discovery-state.json`; Phase 2 reads it to discover navigation selectors; Phase 3 reads both to build detail parsers. If Phase 1 produces a differently-shaped JSON (a field missing, an array where an object is expected), Phase 2 silently reads `nil` and generates broken parser code — with no error at the handoff point.

---

## 2. Current State

| File | Written by | Read by | Schema enforced? |
|---|---|---|---|
| `discovery-state.json` | Phase 1 | Phase 2, 3 | No |
| `navigation-selectors.json` | Phase 2 | Phase 3 | No |
| `phase-status.json` | All phases | All phases | No |
| `browser-context.json` | Phase 1 | Phase 2 (resume) | No |
| `field-spec.json` | Phase 1 (copied) | Phase 3 | No |

Phase status is set to `"completed"` by the agent's own judgement. There is no cross-check that the output file contains the fields the next phase depends on.

Known failure mode (`02-navigation-parser.md:40`):
> Parse: `has_categories`, `has_subcategories`, `sample_urls`, `popup_handling` strategy…

If any of these are absent or mis-typed, the phase continues without error and produces malformed parsers.

---

## 3. Problems

1. **Silent nil propagation** — a missing key in `discovery-state.json` causes the next phase to use a nil value for a CSS selector or URL pattern without any warning.
2. **Self-certified completion** — agents mark phases as `"completed"` before checking that their output satisfies the next phase's required fields.
3. **No minimum viable output definition** — nowhere in the docs is the minimum set of required fields for each state file explicitly listed.
4. **Legacy format drift** — old runs may have `discovery-knowledge.md` (pre-v2.0 format) without `_notes` in JSON. Workflows have migration notes, but no validator checks which format is present.

---

## 4. Proposal

### 4.1 Approach: Validation Tables in Workflow Docs (no new tooling)

Add a **Required Output Contract** table to each workflow markdown. The agent validates its own output against this table before writing `phase-status = "completed"`. This requires zero new tooling — the agent reads the table at runtime as part of following the workflow.

This is intentionally simpler than adding a new MCP tool or JSON Schema system. The goal is to block bad handoffs, not to build a formal schema registry.

### 4.2 Required Output Contracts

#### `discovery-state.json` (written by Phase 1)

| Field | Type | Required | Notes |
|---|---|---|---|
| `scraper_name` | string | Yes | matches `name=` arg |
| `target_url` | string | Yes | exact URL navigated |
| `has_categories` | boolean | Yes | |
| `has_subcategories` | boolean | Yes | |
| `has_listings` | boolean | Yes | |
| `navigation_depth` | integer | Yes | 1 = flat, 2 = cat+listings, 3 = cat+subcat+listings |
| `sample_urls` | object | Yes | must have at least `listings: [...]` with ≥1 URL |
| `popup_handling` | object or null | Yes | null if no popups detected |
| `fetch_type` | string | Yes | `"browser"` or `"standard"` |
| `_notes` | string | Yes | human-readable summary of findings |

Blocking rule: Phase 1 MUST NOT write `phase-status = "completed"` until all Required fields above are non-null.

#### `navigation-selectors.json` (written by Phase 2)

| Field | Type | Required | Notes |
|---|---|---|---|
| `scraper_name` | string | Yes | |
| `project` | string | Yes | |
| `categories_selector` | string or null | Conditional | Required if `has_categories = true` |
| `listings_selector` | string | Yes | CSS selector for product links |
| `pagination_selector` | string or null | Yes | null if infinite scroll or no pagination |
| `pagination_strategy` | string | Yes | `"next_button"`, `"url_pattern"`, `"count"`, `"none"` |
| `_notes` | string | Yes | human-readable summary |

Blocking rule: Phase 2 MUST NOT write `phase-status = "completed"` until `listings_selector` is verified via `browser_verify_selector`.

#### `phase-status.json` contract

Add `validated_output: true` field to each phase entry when the agent completes the output contract check:

```json
{
  "phase_status": {
    "site_discovery": {
      "status": "completed",
      "completed_at": "<ISO timestamp>",
      "validated_output": true
    }
  }
}
```

### 4.3 Workflow Changes

Add a **STEP 0: Validate Output Contract** section to the END of each workflow markdown (before the auto-chain step):

```markdown
## STEP N: Validate Output Contract

Before writing `phase-status = "completed"`, verify your output file contains:

| Field | Present? | Non-null? |
|---|---|---|
| `scraper_name` | | |
| `sample_urls.listings[0]` | | |
| ... | | |

If any Required field is missing or null: **STOP — do not mark phase complete**. Fix the gap first (re-navigate the site if needed). Report what is missing.

Only after all Required fields are confirmed: write `"status": "completed"` and `"validated_output": true` in `phase-status.json`.
```

### 4.4 Optional Future: MCP Validator Tool

If the agent-based validation proves insufficient (agents skip the check), escalate to a `scraper_validate_state` MCP tool in `../playwright-mcp-mod/src/tools/mod/`:

- Takes `scraper_dir` (absolute path) and `phase` (`"discovery"` | `"navigation"` | `"details"`)
- Reads the relevant state file
- Checks required fields against hardcoded schema
- Returns `{valid: bool, missing: [...], warnings: [...]}`

This tool would be called as the first step of the next phase (Phase 2 validates Phase 1's output before proceeding), making it impossible to proceed with corrupt state.

---

## 5. Implementation Order

| Step | Change | Effort | Risk |
|---|---|---|---|
| 1 | Add Required Output Contract table to `01-site-discovery.md` | Low | None |
| 2 | Add Required Output Contract table to `02-navigation-parser.md` | Low | None |
| 3 | Add Required Output Contract table to `03-details-parser.md` and `03-restaurant-details.md` | Low | None |
| 4 | Add `validated_output` field to `phase-status.json` schema in all workflows | Low | None |
| 5 | Add STEP 0 "read and validate prior phase output" to Phase 2 and Phase 3 workflow docs | Medium | Low — agent-enforced only |
| 6 | (Optional) `scraper_validate_state` MCP tool | High | Medium — requires build + deploy of playwright-mcp-mod |

Steps 1–5 can be done in one pass across the four workflow markdown files. Step 6 is a separate initiative if agent-based validation proves unreliable.
