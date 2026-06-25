# Proposal: Standardized Phase Report Artifacts

**Created:** 2026-06-25
**Status:** In Progress
**Scope:** `.scraper-state/reports/`, `templates/phase-report-template.md`, all phase skills, `/qa` skill

---

## 1. Background

Each scraper phase produces state files but no human-readable session summary.
The existing `session-audit-*.json` is sparse and machine-targeted.
When reviewing a scraper's history — or handing it off — there is no single document that answers:
"What did the agent do in Phase 2, what did it decide, and what was surprising?"

---

## 2. Current State

| Artifact | Location | Gap |
|---|---|---|
| `session-audit-*.json` | `.scraper-state/` | Sparse; no narrative; not linked from QA report |
| `GENERATION_REPORT.md` | scraper root | QA-only; no per-phase breakdown |
| `deploy-readiness.json` | scraper root | Machine gate only |
| `*-state.json` | `.scraper-state/` | Decisions buried in `_log` array; not surfaced |

---

## 3. Problem

- No predictable place to see what happened in a phase (tool counts, decisions, test results)
- No place for the agent to write observations freely — it's forced into structured fields or silence
- Reviewing a 6-phase pipeline means reading 6 state files and reconstructing what happened
- Human handoff has no single narrative document

---

## 4. Proposal

### Two-zone report per phase

Every phase writes **one Markdown file** to `.scraper-state/reports/<phase>.md`.

**Zone 1 — Structured header** (formal, predictable, parseable by scripts):

A fenced block at the top with a fixed set of fields in a Markdown table or key-value list.
Always present, always in the same position.

**Zone 2 — Agent narrative** (free-form, unconstrained):

Everything below the structured block. The agent writes what it observed, what surprised it,
what it's worried about for the next phase, what shortcuts it took, and what it'd do differently.
No schema — this is for humans, not machines.

### File layout

```
generated_scraper/<scraper>/.scraper-state/reports/
  01-scrape.md
  02-navigation-parser.md
  03-restaurant-details.md
  04-menu-listings.md
  05-menu-parser.md
  qa.md
```

### Template

See `templates/phase-report-template.md` for the canonical structure.

### Integration points

- Each phase **skill** writes the report at phase end (before marking complete)
- The `/qa` skill reads all phase reports and includes a "Phase Audit" section in `GENERATION_REPORT.md`
- `GENERATION_REPORT.md` links to each phase report

---

## 5. Implementation Order

| Step | File | Effort |
|---|---|---|
| 1 | `templates/phase-report-template.md` — canonical template | Low |
| 2 | `docs/shared/phase-report-spec.md` — schema spec + instructions for agent | Low |
| 3 | Add row to `docs/shared/KB_HUB.md` | Trivial |
| 4 | Update phase skills to write report at end | Medium |
| 5 | Update `/qa` to aggregate phase reports in `GENERATION_REPORT.md` | Medium |
