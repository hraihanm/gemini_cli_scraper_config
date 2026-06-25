
# Knowledge base bootstrap

Thin entry point to the KB. The substantive knowledge lives in `docs/shared/` — do not duplicate it here.

## Steps
1. `read_file` → `docs/shared/KB_HUB.md` — the index + task→doc routing table.
2. From the routing table, `read_file` only the spoke(s) the current task needs (e.g. `docs/shared/selector-discovery.md` for selectors, `docs/shared/dhero-output-schema.md` for dhero output).
3. Firmware rules (`docs/shared/agent-rules-gemini.md`) are already in effect via `AGENTS.md` — re-read only if you need the popup/error-taxonomy/`_log` detail.
4. Continue with the user's request using the loaded context.

> `disable-model-invocation` keeps `/kb` a **manual** entry point. Command skills (`/scrape`, `/qa`, …) load the specific spokes they need directly via `read_file`, so you rarely need `/kb` mid-pipeline.
