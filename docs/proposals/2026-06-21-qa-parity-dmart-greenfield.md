# Proposal: QA + debuggability parity for dmart & greenfield

**Created:** 2026-06-21
**Status:** Done
**Scope:** `scripts/dhero_qa_report.rb` → generalized `scripts/scraper_qa_report.rb`; new `.agents/skills/qa/SKILL.md` (generic) + `/dhero-qa` becomes a thin delegate; `profiles/dmart-dloc.toml`, `profiles/greenfield.toml`, `profiles/dhero.toml` `[qa]` wiring; `templates/dmart_dloc_boilerplate/` + `templates/greenfield_boilerplate/` parsers + finisher; bugfix dmart `field_spec` path.

> Extends `2026-06-21-dhero-generation-qa-hardening.md` (the dhero work) to the e-commerce pipelines. Follow-up to the user question "what about dmart? and other greenfield projects."

## 1. Background
The dhero pipeline now has a one-shot generate→QA gate (`/dhero-qa` + `dhero_qa_report.rb`) and hardened boilerplate. dmart-dloc and greenfield (both e-commerce, single `products` collection) have **no QA gate** and weaker boilerplate. User asked to bring them to parity. Chosen scope: **QA + debuggability parity**, with a single generic `/qa` skill (dhero-qa delegating).

## 2. Current State
- `profiles/dmart-dloc.toml` — `field_spec = "spec_full.json"` which **does not exist** (real spec is `field-spec.json`, 49 fields). Phase 1 STEP 4 file-copy would fail. **Bug.**
- `profiles/greenfield.toml` — no default spec; schema built per-run into `.scraper-state/field-spec.json` from the user prompt.
- dmart/greenfield boilerplate `details.rb` emit `_collection:"products"`, `_id:competitor_product_id`, `[DETAILS] nil=X/N` warn — but **no error taxonomy, no debug collections, no finisher** (grep confirms none).
- `scripts/dhero_qa_report.rb` is dhero-hardcoded: collections `['locations','items']`, dhero spec, id integrity via lead_id/item_id.
- No `qa`/`eval`/`validator` skill exists for any project.

## 3. Problems
1. dmart spec-path bug breaks dmart Phase 1.
2. No deploy-readiness gate / report for dmart or greenfield — devs can't tell if a generated e-commerce scraper is deployable.
3. QA generator not reusable across projects (hardcoded collections + dhero spec).
4. dmart/greenfield boilerplate lacks the debuggability dhero now has (error taxonomy, debug collections, finisher).

## 4. Proposal
1. **Generalize the report generator** → `scripts/scraper_qa_report.rb`, **collection-generic**: collections derived from the sample files present (`.scraper-state/qa-samples/<collection>.json`); per collection, spec fields = those with matching `collection` key, or **all fields** when the spec has no `collection` key (single-collection dmart/greenfield → `products`). Generic id integrity: `_id` present + unique per collection (plus priority-1 required non-nil). Same gates: `samples_ok`(≥3), `schema_ok`, `types_ok`, `required_fields_ok`, `ids_ok`, `eval_ok` → `deployable`. Spec source: `.scraper-state/field-spec.json` first (works for greenfield per-run + dmart + dhero).
2. **Generic `/qa` skill** (`.agents/skills/qa/SKILL.md`) — reads `profiles/<project>.toml`, collects ≥3 sample records per collection via `parser_tester`, runs the script, interprets the gate. `/dhero-qa` kept as a thin alias delegating to `/qa project=dhero`.
3. **Wire `[qa]`** into dmart-dloc + greenfield profiles; repoint dhero `[qa].report` to the generic script.
4. **Fix** dmart `field_spec = "field-spec.json"`.
5. **Debuggability parity**: add error taxonomy (refetch 403 / limbo 500 / status-guarded debug collections), `[PHASE] count` warns, and a dedup finisher (disabled by default) to dmart + greenfield boilerplate; register finisher + `parse_failed_pages` in their config.yaml.

**Out of scope (dhero-specific, not ported):** food `lib/extraction` normalizers, seeding-strategy gate, API-first default.

## 5. Implementation Order
1. Generalize script (rename, collection-generic, generic ids) — M / Low.
2. Generic `/qa` skill + dhero-qa delegate + profile `[qa]` wiring — S / Low.
3. dmart spec-path bugfix — S / Low.
4. Debuggability parity in dmart + greenfield boilerplate parsers + finisher + config — M / Low (mechanical).
5. Validate: synthetic single-collection `products` samples → DEPLOYABLE; missing-key/required-nil → blocked; confirm dhero still passes via the generic script.

## 6. Implementation Result (2026-06-21)
- **PA1:** `scripts/dhero_qa_report.rb` → `scripts/scraper_qa_report.rb` — collections derived from `qa-samples/*.json`; spec fields grouped by `collection` key or all-fields fallback (single `products`); generic `_id` integrity (`_id`/lead_id/item_id/competitor_product_id) + dhero cross-collection linkage when both sampled. `--project` arg.
- **PA2:** `.agents/skills/qa/SKILL.md` (generic); `/dhero-qa` rewritten as a thin alias → `/qa project=dhero`; `[qa]` added to dmart-dloc + greenfield profiles, dhero `[qa]` repointed to the generic script; `/run-pipeline` final-gate text generalized to any `[qa]` profile.
- **PA3:** `profiles/dmart-dloc.toml` `field_spec` `spec_full.json` → `field-spec.json` (the referenced file never existed; Phase 1 STEP 4 copy would have failed).
- **PA4:** error taxonomy (refetch 403 / limbo 500 / `*_fetch_failed` + `product_not_found` debug collections) injected into all 4 dmart + 4 greenfield parsers; products-dedup `finisher/finisher.rb` added to both; `finisher` (disabled) + `parse_failed_pages: true` registered in both `config.yaml`.
- **PA5 validation:** dmart single-collection complete → DEPLOYABLE; dmart missing-keys/type-violation/required-nil → NOT DEPLOYABLE with precise `_blocking`; dhero dual-collection regression → still DEPLOYABLE via the generic script; all 8 e-commerce parsers + 2 finishers + QA script syntax-clean; both configs valid YAML.

**Not ported (dhero-specific):** food `lib/extraction` normalizers, seeding-strategy gate, API-first default.
**Follow-up:** re-run `pwsh -File scripts/setup-agy.ps1` + restart `agy` to register `/qa`.
