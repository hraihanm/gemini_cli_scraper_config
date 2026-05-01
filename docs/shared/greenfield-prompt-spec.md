# Greenfield: spec from the message (no default spec file)

For **`project=greenfield`**, treat **`field-spec.json` as derived from the same chat turn** as the command: the slash line (e.g. `url=`, `name=`) plus **everything the user wrote below it**. There is **no** profile default CSV/JSON — do not require or assume a spec on disk.

Optional: if the user passes **`spec=<path>`** on the slash line, you may still load that file (see `greenfield-01` STEP 4). Otherwise, **only** the message body + args.

## Accept any reasonable briefing format

Infer the contract from whatever the user provides. All of the following are valid:

- **Loose prose** — paragraphs that mention source name, country, URLs, caveats, and what to extract.
- **Labeled sections** — e.g. `Source:`, `URLs:`, `Caveats:`, `Required:`, `Output:`, `Notes:` (headings or bold lines).
- **Bullets** — one field or URL per line.
- **Markdown tables** — `Field | Type | Description` (or two-column).
- **Pasted tickets / specs** — Jira-style blocks; pull out URLs, constraints, and column meanings.

Parse **URLs** (start URLs, search portals, docs links) into `discovery-state.json` / `_notes` as needed; parse **output fields** into `field-spec.json`.

## Building `field-spec.json`

1. **Fields** — For every output column the user wants, add a `fields[]` entry: `name` (machine key, snake_case if they gave “nice” names), `type` (`str` / `int` / `float` / `boolean` from their wording), `extraction_method` (`FIND` vs `PROCESS` — e.g. scrape timestamp = `PROCESS`), `notes` (short copy of their description / caveat).
2. **Required vs optional** — If they mark “required” / “recommended”, set `extraction_method` and encode optional fields the same way but note optional in `notes`.
3. **Order** — Preserve the order fields appear in the message (required block first if separated).
4. **Missing values** — In root `_notes`, state: Ruby **`nil`** → JSON **`null`**, not `""`.
5. **Nothing extractable** — If you cannot identify **any** output field from the full message, **stop** and ask the user to list fields (or pass `spec=`). Do **not** invent a spec from boilerplate.

Use `"source_file": "prompt"` (or `"prompt+brief"`) in `field-spec.json` when the spec is message-derived.

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
      "notes": "from user brief",
      "selectors": [],
      "verified": false
    }
  ],
  "_notes": "Caveats, URLs, cadence — copied/summarized from user message"
}
```

If the user later adds a `spec=` file path, re-run Phase 1 with that arg or replace `field-spec.json` per Phase 1 branch rules.
