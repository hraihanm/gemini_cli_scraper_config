# Parser testing (`parser_tester` MCP)

**version:** 1.0.0

## Mandatory rules

1. Use the **`parser_tester`** MCP tool for all parser validation.
2. **Forbidden**: `hen parser try` (not available in this environment).
3. **Order**: test with downloaded HTML (`html_file` or `auto_download: true`) before live `url` tests.
4. **`scraper_dir`**: always an **absolute** path to `generated_scraper/<scraper_name>/` under `<workspace_root>`.

## Path placeholders

Replace `<workspace_root>` with the project root (e.g. `D:\DataHen\projects\gemini_cli_testbed` on Windows).

Example `scraper_dir`:

```
<workspace_root>/generated_scraper/<scraper_name>
```

Windows example:

```
D:\DataHen\projects\gemini_cli_testbed\generated_scraper\my_scraper
```

## Modes

- **`auto_download: true`** — capture HTML from the active browser tab (efficient after `browser_navigate`).
- **`html_file`** — offline validation with a saved file (absolute path).
- **`vars`** — JSON string for data-flow tests.
- **`url`** — only after HTML-based tests succeed.
- **`quiet: true`** — confirmatory runs; **`quiet: false`** — debugging.

## After testing

Use `puts pages.to_json` / `puts outputs.to_json` for inspection. **`save_pages` / `save_outputs`** are for production server memory management, not local debugging.

## Optional

- `scraper_output_validator(scraper_dir, outputs_json)` — field coverage vs `config.yaml`.
