# API Phase 3: Detail API parser

**version:** 1.0.0

**Profile:** `[[api_pipeline.phases]]` — final API parser phase.

## Goal

Fill `parsers/details.rb` (or project detail parser) using JSON paths / `JSON.parse(content)` patterns. Batch field discovery by **response region** (identity, pricing, media, stock, spec). Respect output hash rules.

## Rules

- Locale-aware numeric parsing for prices stored as strings.
- **Category fallback:** use `vars['category_name']` when path-based category is nil.
- After `parser_tester`, **nil-guard** required commercial fields.
- Write `detail-selectors.json` with `_notes` and optional `price_locale`.

## Steps (summary)

0. **Listings-only guard** — read `navigation-selectors.json` (or API state file). If `details_parser_needed == false`: this phase is a no-op. Display:
   ```
   ⏭  Details phase skipped — listings parser handles all fields (details_parser_needed: false).
   Verify config.yaml has details parser disabled: true.
   ```
   Then stop. Do not edit any parser files.

1. Load navigation/API state, `field-spec.json`, existing detail parser.
2. JSON-LD or meta fallbacks only if API payload lacks fields; otherwise prefer API fields.
3. Batched grep / inspect: group FIND fields; minimize redundant `browser_*` when working from saved JSON files (`read_file` on downloaded samples).
4. Edit parser; test on ≥3 samples; update field-spec.
5. Write `detail-selectors.json` + `_notes`; phase status; session audit with real counts.
6. If last API phase: final completion message — no chain.
