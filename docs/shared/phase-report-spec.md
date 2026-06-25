# Phase Report Spec

Every phase must write a report to `.scraper-state/reports/<phase-slug>.md` before marking complete.

## File path

```
generated_scraper/<scraper>/.scraper-state/reports/<phase-slug>.md
```

Phase slugs:
- `01-scrape` (site discovery / HTML scrape)
- `02-navigation-parser`
- `03-restaurant-details`
- `04-menu-listings`
- `05-menu-parser`
- `06-details-parser` (dmart/greenfield)
- `qa`

## Two-zone structure

The report has two zones, in order. **Do not mix them.**

---

### Zone 1 — Structured Summary (top)

A Markdown table with fixed rows. **Every row is required.**
Use `n/a` only when the field genuinely cannot apply (e.g. "Eval score" on a phase with no evals).
Use `none observed` or `none` for negative results — never leave a cell blank.

Required rows (copy from `templates/phase-report-template.md`):
- Pagination surfaces found
- Popup / modal handling
- Extraction method
- Selectors verified
- Parser test iterations
- Parser test result
- Eval score
- Expensive tool uses
- Structural errors
- Data gaps (non-blocking)
- Key decisions (inline or as sub-table)
- Next phase ready
- Blockers for next phase

---

### Zone 2 — Agent Narrative (bottom)

Freeform Markdown under `## Agent Narrative`. No required fields.
Write what would help a developer understand what happened here — surprises, judgment calls,
things to watch in the next phase, retrospective notes.

This section exists specifically so the agent is not forced to compress every observation
into a structured field. Write as much or as little as is useful.

---

## What NOT to put in Zone 1

- Opinions, uncertainty, hedging — those go in Zone 2
- "See state file for details" — Zone 1 should be self-contained summaries
- Long prose — one-line values only

## What NOT to put in Zone 2

- Data that belongs in Zone 1 (selector counts, test results, timestamps)
- Repetition of Zone 1 rows

---

## Writing instructions for the agent

1. At phase end, after all state files are written and parser tests pass:
   - Create `.scraper-state/reports/` directory if it doesn't exist
   - Copy the template structure from `templates/phase-report-template.md`
   - Fill Zone 1 from what you observed during the session (tool calls, test results, decisions)
   - Write Zone 2 as a short but honest narrative — what surprised you, what you'd do differently
2. Write the file with `write_file` to an absolute path
3. Reference the report in any summary message to the user

## QA integration

The `/qa` skill reads all reports under `.scraper-state/reports/` and appends a
**Phase Audit** section to `GENERATION_REPORT.md`, with one row per phase:

| Phase | Status | Parser result | Key decision | Narrative excerpt |
|---|---|---|---|---|
| 01-scrape | ✅ | n/a | geo_grid seeding strategy | Location modal … |
| 03-restaurant | ✅ | 3/3 pass | JSON-LD Product schema | All addresses nil … |
