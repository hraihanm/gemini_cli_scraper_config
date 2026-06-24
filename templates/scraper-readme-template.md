# Scraper: {name}

## Summary

| Field | Value |
|-------|-------|
| **Site** | [{domain}]({base_url}) |
| **Country** | {country_iso} — {country_name} |
| **Language** | {language_code} |
| **Currency** | {currency_code_lc} |
| **Type** | {HTML \| API \| API/GraphQL \| DHero} |
| **Pipeline** | {e.g. categories → listings → details} |
| **Details parser** | {Active \| Disabled — reason} |
| **Status** | {Draft \| Functional \| Production} |
| **Generated** | {YYYY-MM-DD} |

## Pipeline

- **seeder** — {what it seeds}
- **categories** — {what it parses and queues}
- **listings** — {pagination strategy; what it emits}
- **details** — {if active; omit row if disabled}

## Key implementation notes

- {Any non-obvious decisions: auth, fieldset flags, store/chain IDs, pagination quirks}
- {Image CDN pattern, dedup guards, MeasurementExtractor usage, etc.}
- {JSON-LD / meta / CSS extraction priority if HTML scraper}

## Tested against

- `{url_1}`
- `{url_2}`
- `{url_3}`
