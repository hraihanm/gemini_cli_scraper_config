# Greenfield: output schema from the user prompt

When **`spec=` is omitted** in `/greenfield-scrape` (or `/scrape project=greenfield`), build `.scraper-state/field-spec.json` from the **same conversation** that contains the scraping brief.

## Rules

1. **Required vs optional** — Mirror the prompt: mark required columns as `extraction_method: "FIND"` (or `"PROCESS"` for derived fields like `date` / scrape timestamp).
2. **Types** — Map prompt types to field-spec types: `string` → `str`, `integer` → `int`, `float` → `float`, `datetime` → `str` (note ISO-8601 in dev_notes).
3. **Missing values** — Document in `field-spec.json` root or `_notes`: output must use Ruby **`nil`** (serializes as `null`), **not** empty strings.
4. **Canonical order** — Store `fields` in the order listed in the prompt (required block first, then recommended).
5. **No file** — If the brief only gives prose, still emit `field-spec.json` with one object per named output column and `dev_notes` summarizing the prose constraint.

## Minimal JSON shape

```json
{
  "source_file": "prompt",
  "parsed_at": "<ISO8601>",
  "fields": [
    {
      "name": "source",
      "type": "str",
      "extraction_method": "FIND",
      "notes": "bolagsverket_se",
      "selectors": [],
      "verified": false
    }
  ],
  "_notes": "Caveats from user message (search limits, refresh cadence, …)"
}
```

After Phase 1, if the user later provides a CSV path, re-run Phase 1 with `spec=` or manually replace `field-spec.json` via file copy per main discovery workflow.
