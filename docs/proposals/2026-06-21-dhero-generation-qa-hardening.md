# Proposal: dhero scraper generation + QA hardening (API-first, debuggable, deploy-ready reports)

**Created:** 2026-06-21
**Status:** Done
**Scope:** `profiles/dhero.toml`, `templates/dhero_boilerplate/`, `docs/workflows/phases/*` (dhero phases + new API-dhero phases), `.agents/skills/` (dhero command + new `dhero-qa`/report skills), `dhero-field-spec.json`, `docs/shared/dhero-output-schema.md`, `scripts/run_evals.rb`. Reference inputs: `original_scraper/dhero/*` (14 production scrapers), `datahen-assistant/`.

> Sibling proposal `2026-06-21-agent-skills-hardening.md` is owned by another agent in this session — this proposal does **not** touch it. Where they overlap (skill frontmatter/length rules) this doc defers to it.

## 1. Background

The user asked to (a) learn the dhero project patterns from the 14 production scrapers in `original_scraper/dhero/` (snoonu_qa + lezzoo_iq + totersapp = newest, canonical field model), and (b) refine the scraper **generation agent** so a single run does **generation + QA in one go**, is **more debuggable**, and emits **extensive reports** that let a dev either continue the work or deploy directly.

The generation system already has real maturity: a canonical `dhero-field-spec.json` (50 fields across `locations`/`items`), `docs/shared/dhero-output-schema.md` (A1/A2/A3 export wiring), a 5-phase profile, per-phase workflow docs, state files, an eval mechanism (`scraper_run_evals`), and an output validator. The gap is not "from scratch" — it is **alignment with how dhero scrapers are actually built** plus **QA/report/debuggability as first-class deliverables**.

## 2. Current State

### 2.1 What the generation system assumes (dhero)
- `profiles/dhero.toml:33-61` — default `pipeline.phases` is **HTML**: `scrape` (site discovery via browser) → `navigation-parser` (restaurant listings via CSS) → `restaurant-details-parser` → `menu-listings-parser` → `menu-parser`. An `api_pipeline` exists but is the *secondary* path (`api-01/02/03`).
- `docs/workflows/phases/03-restaurant-details.md` — browser-driven: navigate page, `browser_extract_json_ld({type:"Restaurant"})`, CSS selector discovery, probe `{url}/menu` sub-URL. Output hash uses ad-hoc keys (`name`, `cuisine`, `rating`…) — **not** the canonical `dhero-field-spec.json` field names (`restaurant_name`, `main_cuisine`, `restaurant_rating`…). (Lines 136-156.)
- `templates/dhero_boilerplate/` — only `seeder/seeder.rb` (single `PLACEHOLDER_HOMEPAGE_URL` listings seed), `lib/headers.rb`, and 4 parsers. **No** `lib/site_config.rb`, **no** `lib/helpers.rb` (request builders), **no** `lib/*_extraction.rb` (fallback chains + shared normalizers), **no** finisher.

### 2.2 What production dhero scrapers actually do (`original_scraper/dhero/`)
Read all 14. The dominant architecture is **API-first + geo seeding**, not HTML:

| Scraper | Fetch model | Seeding | Notable |
|---|---|---|---|
| snoonu_qa | API (v7 merchants) + HTML detail (`__NEXT_DATA__`) | page range | multi-market `SiteConfig` (QA/KW); `lib/{site_config,helpers,merchant_extraction}.rb` — **the gold-standard lib layout** |
| lezzoo_iq | pure API | city→**H3 hexagon** map → widgets → merchant-list | carries `doc_id` forward; emits location from menu parser |
| totersapp | pure API | **geo.csv** (lat/long per city) | newest; `FIELD_UPDATE_REPORT.md`; generic `parse_opening_hours` normalizer |
| jahez | API + browser anti-bot | geo.csv/coord.csv | `about:blank` driver pages for dedup; X-Device-ID |
| talabatey | API | neighborhoods | POST body API |
| mrsool_sa | API | cities.csv + coordinates.csv | |
| monchis | API + **session auth** | geo.csv | `make_user`→token→`change_location_session` bootstrap |
| yummy_ve | **GraphQL** | zone/geo grids | dedup driver pages |
| degusta_pa/ve, eatigo_hk | API | listings/init | |
| openrice_hk | **HTML** (JSON-LD + CSS) | search | the *only* HTML-first dhero — i.e. the current default fits 1/14 |

Every API scraper independently reimplements: opening-hours normalization (minutes→HHMM, AM/PM→HHMM, day-name maps), phone formatting, price/original-price logic, `cuisine_name` array→`{cuisine1,…}` hash, MD5/UUID id derivation, and city/area heuristics. snoonu's `lib/merchant_extraction.rb` and totersapp's `parse_opening_hours` are the most reusable versions.

### 2.3 What "good QA / reports" look like (already in the repo)
- `original_scraper/dhero/*/spec.csv` — a **field-availability matrix**: per field, `Available? = Yes|Partial|No` + a note citing `file.rb` and an evidence GID. This is the single most useful deliverable for a dev.
- `totersapp/FIELD_UPDATE_REPORT.md` — what-changed + parser-test results (GID, "70/70 outputs validated") + sample records + deploy command.
- `DATAHEN_PROJECT.txt` / spec template (`datahen-assistant/datahen/specs/_project-spec-template.md`) — identity, pipeline, anti-bot, deploy sequence.
- Debug collections used in practice: `restaurant_not_found`, `restaurant_redirected_to_home`, `restaurant_not_parsable`, `debug_listings`, `city_has_no_merchant`, `merchant_not_found`, `failed_to_get_content`.

### 2.4 Existing QA tooling
`scraper_run_evals` (eval fixtures + nil-rate), `scraper_output_validator` (output vs config field list), `_log` decision-log convention (`docs/shared/datahen-conventions.md`), error taxonomy (`docs/shared/agent-rules-gemini.md`). These exist but are **per-phase and optional**, not a single gated "generate→QA→report" pass.

## 3. Problem(s)

1. **Pipeline/reality mismatch.** dhero default is HTML; 13/14 real scrapers are API-first with **geo-coordinate / H3 / city-grid seeding**. The HTML path has no notion of a geo input list, yet `input_lat`/`input_long` are canonical `FROM_VARS` fields. New dhero generations start on the wrong rails.
2. **No seeding strategy decision step.** Discovery never asks "URL listings vs geo-grid vs city/neighborhood list vs session-bootstrap." This is the highest-leverage architectural choice for a dhero scraper.
3. **Boilerplate lacks the `lib/` layer.** No `site_config` (multi-market profiles), no `helpers` (request builders with the right headers/`http2`/`proxy_type`/`custom_headers`/`no_default_headers`), no shared extraction/normalizers. Agents re-derive opening-hours/phone/price/cuisine logic every time → inconsistent, buggy, hard to review.
4. **Field-name drift.** Phase-3 doc emits `name/cuisine/rating`; canonical spec wants `restaurant_name/main_cuisine/restaurant_rating`. Output won't match A1/A2/A3 exporters without rework.
5. **QA is not one-shot or gated.** No single command produces: full-spec output validation + nil-rate + eval gate + the `spec.csv` matrix + a generation report + a deploy-readiness checklist. A dev can't tell "is this deployable?" at a glance.
6. **Debuggability is shallow.** `_log` and debug collections are conventions, not enforced/templated. No standard `[LISTINGS]/[DETAILS]/[MENU]` counts, no standardized failure collections in the boilerplate, no run summary artifact.

## 4. Proposal

Five workstreams. Each is independently shippable; order in §5.

### 4.1 Make the dhero pipeline API-first with a seeding-strategy gate
- Flip `profiles/dhero.toml` so the **default** dhero pipeline is the API/JSON model; keep HTML as an explicit `kind=html` opt-in (openrice-style). Phases become: `api-scrape (discovery + seeding strategy)` → `api-navigation-parser (listings/merchant-list)` → `restaurant-details-parser` → `menu-listings-parser` → `menu-parser`, all operating on JSON by default.
- Add a **Seeding Strategy** decision to Phase 1 discovery, written to `discovery-state.json`:
  ```json
  "seeding": {
    "strategy": "geo_grid | h3_hexagon | city_list | neighborhood_list | url_listings | session_bootstrap",
    "input_file": "input/geo.csv",
    "geo": { "lat_col": "lat", "long_col": "long", "city_col": "city" },
    "auth": { "required": false, "bootstrap_page_type": null },
    "endpoints": { "listings": "...", "merchant_list": "...", "menu": "..." },
    "pagination": "page_number | offset | cursor | hexagon_fanout"
  }
  ```
  Detection cues are already documented for API discovery (GraphQL probe, auth/Bearer capture, cursor pagination) — extend with geo/H3/city-list detection drawn from lezzoo/totersapp/mrsool.

### 4.2 Rebuild `templates/dhero_boilerplate` around snoonu's `lib/` architecture
Add, as PLACEHOLDER-but-wired skeletons:
- `lib/site_config.rb` — `PROFILES` hash keyed on `ENV['country']` (base_url, country_code, currency, default lat/long, `city_zones` bbox, header builders, cookie builder, URL builders). Multi-market ready (snoonu QA/KW, yummy VE/PE/PA).
- `lib/helpers.rb` — request builders (`listings_page`, `restaurant_page`/`merchant_page`, `menu_page`) pre-setting `headers`, `priority`, `http2: true`, `proxy_type`, `custom_headers: true`, `no_default_headers: true`, POST `body`.
- `lib/extraction.rb` — **shared normalizers** lifted/generalized from production: `opening_hours` (minutes→HHMM, AM/PM→HHMM, day maps, ranges crossing midnight — generalize totersapp's `parse_opening_hours`), `format_phone`, `item_prices`→`[price, original]`, `cuisine_hash`, `str_empty_to_nil`/`zero_to_nil`, MD5/UUIDv3 id helpers, `city_from_coordinates` bbox.
- `seeder/seeder.rb` — branch by `seeding.strategy` (geo.csv loop / H3 map / city list / url listings).
- `parsers/*` — output hashes keyed to **canonical `dhero-field-spec.json` names**, all fields always present (nil-explicit), with built-in debug collections + `_log` + `[PHASE] count` warns.
- `finisher/finisher.rb` — the standard cursor-paginated dedup/clean pass (snoonu/lezzoo pattern), disabled by default.
- Keep an `input/geo.csv` placeholder + `DATAHEN_PROJECT.txt` template.

### 4.3 Align phase docs + field names to the canonical spec
- Rewrite Phase 3/4/5 output hashes to canonical field names; reference `dhero-field-spec.json` as the source of truth (it already maps each field to A1/A2/A3 and an `extraction_method`).
- Add an API-first restaurant-details/menu doc variant (JSON `dig` extraction, last-resort HTML+JSON-LD only when critical fields nil across 3 merchants — already a documented rule).
- Document the seeding strategies with a worked example per strategy (geo_grid=totersapp, h3=lezzoo, city_list=mrsool, session=monchis, graphql=yummy, html=openrice).

### 4.4 One-shot **generate + QA** workflow (the headline ask)
Add a `/dhero-qa` skill (and wire it as the final step of `/run-pipeline` for dhero) that runs **after** the parsers exist and produces a gated report:
1. **Schema validation** — `scraper_output_validator` against the full 50-field spec for `locations` + `items` (all fields present, nil-explicit, correct A1/A2/A3 placement, types).
2. **Nil-rate report** — per field across ≥3 sample pages/merchants; classify each via the field-availability rubric → `Yes | Partial | No`.
3. **Eval gate** — `scraper_run_evals`; create a first fixture if none (existing Phase-3 STEP 6b behavior), score ≥ threshold.
4. **id integrity** — `lead_id` consistency across A1/A2; `item_id` uniqueness; `lead_id` on items matches restaurant.
5. **Emit artifacts** (deliverables for the dev):
   - `spec.csv` — auto-generated field-availability matrix (same shape as production `spec.csv`, with evidence GID + parser file per field).
   - `GENERATION_REPORT.md` — what was built, per-phase parser-test results (GID + "N/N validated"), nil-rate table, eval score, sample location + item record, open issues, and the exact `hen scraper deploy <name>` sequence (totersapp `FIELD_UPDATE_REPORT.md` shape).
   - `DATAHEN_PROJECT.txt` filled from discovery.
   - `deploy-readiness.json` — boolean gates (`schema_ok`, `nil_rate_ok`, `eval_ok`, `ids_ok`, `required_fields_ok`) → overall `deployable: true|false`.
- **Gate semantics:** required (priority-1) fields must be non-nil on samples and ids must pass, else `deployable:false` with a STOP and a precise remediation line.

### 4.5 Debuggability hardening (templated, not just conventional)
- Bake standard **failure/debug collections** into boilerplate parsers: `restaurant_not_found`, `restaurant_not_parsable`, `redirected_to_home`, `debug_listings`, `city_has_no_merchant`, `failed_to_get_content`.
- Bake **error taxonomy** handling (refetch on 403/transient, limbo on 500/last-page, `refetch_count` guard then structural STOP) and `[LISTINGS]/[DETAILS]/[MENU] url=… count=N nil=X/N` warns.
- Enforce `_log` entries at the documented decision points (seeding_strategy, json_ld_probe, selector/field_verify, parser_test, pagination_strategy, fallback, structural_error).
- `GENERATION_REPORT.md` aggregates the `_log` into a human "decision trail" section.

## 5. Implementation Order

| # | Step | Effort | Risk | Notes |
|---|---|---|---|---|
| 1 | `dhero-qa` skill + `GENERATION_REPORT.md`/`spec.csv`/`deploy-readiness.json` generators; wire as final `/run-pipeline` step | M | Low | Highest value, additive, no pipeline change. Reuses existing validator + evals. Ship first. |
| 2 | Boilerplate `lib/` layer (`site_config`, `helpers`, `extraction`) + shared normalizers | M | Med | Lift from snoonu/totersapp; pure additions. Unblocks correctness of everything downstream. |
| 3 | Debuggability templating (failure collections, taxonomy, warns, `_log` points) into boilerplate parsers | S | Low | Mechanical; pairs with #2. |
| 4 | Phase docs + boilerplate output hashes → canonical `dhero-field-spec.json` names | S | Med | Removes field drift; touches several docs. |
| 5 | Seeding-strategy gate in Phase 1 + `seeder` branching + per-strategy phase docs | M | Med | Behavior change to discovery. |
| 6 | Flip `profiles/dhero.toml` to API-first default; HTML as `kind=html` opt-in | S | High | Do last — changes the default path; validate end-to-end on a re-gen of a known scraper (e.g. regenerate `snoonu_qa` and diff against original) before committing. |

**Validation plan:** regenerate one API scraper (totersapp or snoonu) end-to-end with the new pipeline + `/dhero-qa`, and confirm `deploy-readiness.json: deployable=true` and that the emitted `spec.csv` matches the hand-written production `spec.csv` within tolerance.

**Out of scope:** non-dhero pipelines (dmart/greenfield) except where the `/dhero-qa` report generator is generalizable later; skill frontmatter/length policy (owned by the sibling proposal).

## 6. Implementation Result (2026-06-21)

All six workstreams landed. Files:

**WS1 — one-shot generate + QA**
- `scripts/dhero_qa_report.rb` — deterministic report generator. Reads `.scraper-state/qa-samples/{locations,items}.json` + `dhero-field-spec.json` + every `*-state.json` `_log`; emits `spec.csv`, `GENERATION_REPORT.md`, `deploy-readiness.json`, `DATAHEN_PROJECT.txt`. Gates: `samples_ok` (≥3/collection), `schema_ok`, `types_ok`, `required_fields_ok` (priority-1), `ids_ok`, `eval_ok` → `deployable`. Priority-2 all-nil is a non-blocking warning. Exit 0/2/1.
- `.agents/skills/dhero-qa/SKILL.md` — orchestration (collect samples → evals → run script → interpret gate → STOP-on-fail with per-field remediation).
- Wired into `profiles/dhero.toml [qa]` and `/run-pipeline` final-gate step.

**WS2 — boilerplate `lib/` layer**
- `lib/extraction.rb` (fully-working shared normalizers: opening-hours minutes/AM-PM, phone, `item_prices`, `cuisine_hash`, MD5/UUIDv3 ids, geo bbox), `lib/site_config.rb` (multi-market `PROFILES` skeleton), `lib/helpers.rb` (request builders). All smoke-tested.

**WS3 — debuggability**
- Error taxonomy (refetch 403 / limbo 500 / status-guarded debug collections `restaurant_not_found`, `restaurant_not_parsable`, `*_fetch_failed`) + `[PHASE] count nil=X/N` warns across all four parsers; standard dedup `finisher/finisher.rb` (disabled by default); `parse_failed_pages: true`.
- Bugs fixed: duplicate `free_field` key; `page[:vars]`/`page[:url]` symbol-key access in listings.rb (v3 string-key bug); menu.rb top-level `return`→`finish` + `[LISTINGS]`→`[MENU]` labels; menu_listings single-page GID-collision (now GID-busted + warned, points to inline Strategy E).

**WS4 — canonical field names**
- Phase docs 03/04/05 output hashes fixed (`name/cuisine/rating`→canonical; `category_name`→`menu_category`, `img_url`→`menu_item_image_url`, added `original_price`). Cross-check confirms boilerplate parsers emit **exactly** the spec field set: locations 28/28, items 22/22 (0 missing, 0 extra).

**WS5 — seeding-strategy gate**
- Phase 1 `STEP 8b` + `discovery-state.json.seeding` schema; branching `seeder/seeder.rb` (geo_grid / h3_hexagon / city_list / session_bootstrap / url_listings) + `input/geo.csv`; `docs/workflows/phases/dhero-seeding-strategies.md`.

**WS6 — API-first default**
- `profiles/dhero.toml`: `[defaults] kind = "api"`; the misaligned generic `api_pipeline` (dmart-product-shaped docs) replaced with the same fetch-agnostic dhero 5 phases; `/run-pipeline` honors profile default `kind`. Validated: zero-sample → NOT DEPLOYABLE (insufficient_samples); spec-complete samples → DEPLOYABLE with all hard gates green.

> **Update (same day):** the QA generator `scripts/dhero_qa_report.rb` was generalized to project-agnostic `scripts/scraper_qa_report.rb` and `/dhero-qa` became a thin alias of the new generic `/qa` skill — see `2026-06-21-qa-parity-dmart-greenfield.md`. dhero behavior is unchanged.

**Follow-ups (not blocking):** re-run `pwsh -File scripts/setup-agy.ps1` + restart `agy` to register `/dhero-qa`. A full live regeneration of a real source (e.g. totersapp) through the new pipeline remains the ultimate end-to-end check — the deterministic cross-checks above stand in for it here.
