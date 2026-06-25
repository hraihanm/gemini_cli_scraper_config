# Proposal: Human Handoff Guide in GENERATION_REPORT.md

**Created:** 2026-06-22
**Status:** Done
**Scope:** `scripts/scraper_qa_report.rb` — add `## Human Handoff Guide` section to the generated `GENERATION_REPORT.md`

## 1. Background

The QA report accurately surfaces what was extracted and whether the scraper is deployable, but gives a human editor no guidance on *where to look when something breaks* or *what is most likely to break*. A developer unfamiliar with the generated code must cross-reference the field table, the `_log`, the parser files, and the spec manually to diagnose a regression.

## 2. Current State

`write_report` in `scripts/scraper_qa_report.rb` (line 316) writes six sections:
deploy-readiness gates → sample coverage → per-collection field availability → ID integrity → sample record → decision trail → deploy sequence.

All the raw data needed for a handoff guide already exists in memory:
- `rows[i][:extraction_method]` — how each field is extracted (from spec field metadata)
- `rows[i][:nil_rate]` — how often each field is nil across samples
- `rows[i][:priority]` — field importance
- `log` — decision trail entries including `structural_error`, `selector_verify`, `parser_test` entries

## 3. Problem(s)

1. **No fragility signal.** Fields extracted via CSS selectors are brittle to site redesigns; fields backed by JSON-LD or API JSON are stable. The report lists `extraction_method` in spec.csv but nowhere says "these three fields are most likely to break."
2. **No partial-availability narrative.** Fields with 0 < nil_rate < 1 appear in the availability table as "Partial" but there's no guidance on whether that's expected data-gap or a fragile selector degrading.
3. **No recovery path.** When a field goes nil post-deploy, a human must know the full phase architecture to know which file to edit and which command re-tests it.
4. **Structural errors are buried.** `structural_error` `_log` entries appear in the decision trail table but aren't called out prominently.

## 4. Proposal

Add a `## Human Handoff Guide` section immediately before "Deploy sequence". It contains four sub-sections:

### 4a. Fragile selectors (most likely to break)

Classify each field by extraction_method stability:
- `STABLE` → `json_ld`, `json-ld`, `meta`, `og`, `api`, `json`, `xpath`
- `FRAGILE` → `css`, `selector`, `html`, nil/unknown

Emit a table of FRAGILE fields, sorted by priority ascending (most important first), with nil_rate and a "watch" flag if nil_rate > 0:

```
| Field | Collection | Priority | Nil% | Why fragile |
```

If all fields are STABLE, say so ("All fields backed by structured data — low redesign risk").

### 4b. Partial-availability fields (need monitoring)

Fields where `availability == 'Partial'` (nil_rate > 0, < 1) but not already in `_blocking.required_nil`. These work *sometimes* and may degrade silently. List with nil_rate and priority.

### 4c. Structural errors (already failed — must fix)

Any `_log` entry with `action: 'structural_error'`. Echo them as a bold callout block. If none, say "No structural errors recorded."

### 4d. Recovery quick-reference

Static per-project command table + "where to edit" map derived from collection names:

```
| Symptom                     | File to edit                         | Re-test command                       |
| listings returns 0 results  | parsers/listings.rb (or seeder.rb)   | agy /scrape scraper=<name> ...        |
| detail field nil            | parsers/details.rb (or restaurant_details.rb) | agy /details-parser scraper=<name> |
| menu item missing           | parsers/menu.rb                      | agy /menu-parser scraper=<name>       |
| deploy-readiness wrong      | re-run QA                            | ruby scripts/scraper_qa_report.rb ... |
```

Collection names drive which rows appear (dhero gets locations/items rows; products gets the e-commerce rows).

## 5. Implementation Order

1. Add `fragility_class(method)` helper — S / Low
2. Add `write_handoff_section(io, rows, log, collections, name, project)` — M / Low
3. Call it from `write_report` between the decision trail and deploy sequence — S / Low
4. Verify output renders correctly for a zero-sample run (should still emit the section with "no samples" where nil% would be) — S / Low

No CLI flag needed — the section is always emitted; it adds ~30 lines to the report.
