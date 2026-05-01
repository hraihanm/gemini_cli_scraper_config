# Proposal: Greenfield (prompt-driven) scraping pipeline

**Created:** 2026-05-01  
**Status:** Done  
**Scope:** `profiles/greenfield.toml`, `templates/greenfield_boilerplate/`, `docs/workflows/phases/greenfield-*.md`, `docs/shared/greenfield-prompt-spec.md`, `.gemini/commands/greenfield-scrape.toml`, `.gemini/README.md`, `docs/workflows/CHANGELOG.md`

## 1. Background

Retail-oriented profiles (`dmart-dloc`, `dhero`) assume e‑commerce boilerplate and field-spec shapes. One-off or government/registry sources need the same browser and parser tooling without locking to those templates; the **user prompt** should carry URLs, caveats, and output schema.

## 2. Current State

- `/scrape` loads `profiles/<project>.toml` and phase workflows; default `project=dmart-dloc`.
- Phase docs assume category/listing product flows and copy `templates/dmart_dloc_boilerplate` (or dhero).
- No first-class path for **search-only portals**, **master search-string lists**, or **prompt-defined JSON/CSV schemas**.

## 3. Problem(s)

- Agents must remember to pass a non-retail profile or fight retail-centric defaults.
- Site-discovery validation (`has_categories`, `sample_urls.listings`) is awkward for search-primary sites.
- Field spec is file-first; prompt-embedded tables are not formalized.

## 4. Proposal

1. Add **`profiles/greenfield.toml`**: same three HTML phases (`scrape` → `navigation-parser` → `details-parser`) but workflows point to **`greenfield-0*.md`**; `template.boilerplate_dir` = `templates/greenfield_boilerplate`.
2. Add **`templates/greenfield_boilerplate`**: copy of dmart v3 layout with **lean CSV/export fields** and README stating intent (replace exporters + details output in Phase 3 from spec).
3. Add **`docs/shared/greenfield-prompt-spec.md`**: rules for building `.scraper-state/field-spec.json` from **flexible message text** (prose, bullets, tables); **no** default spec file on disk; optional `spec=` on the slash line only when the user wants a file.
4. Add **`docs/workflows/phases/greenfield-01-site-discovery.md`** (and 02, 03): override Steps 2–4 and validation of Phase 1 for search portals, seed lists, and `_notes`; defer to base phase docs where unchanged.
5. Add **`.gemini/commands/greenfield-scrape.toml`**: `project=greenfield` default and pointers to greenfield docs; still use `/navigation-parser` and `/details-parser` with `project=greenfield`.
6. Document in **`.gemini/README.md`** and **CHANGELOG**.

## 5. Implementation Order

| Step | Effort | Risk |
|------|--------|------|
| Boilerplate + profile | Low | Low — isolated directory |
| greenfield-01..03 workflows | Medium | Medium — agent must follow overrides |
| Shared prompt-spec shard | Low | Low |
| Slash command + README | Low | Low |
