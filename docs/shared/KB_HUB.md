# Knowledge Base — hub & routing

Condensed, task-scoped knowledge for the scraper-generation agent. **Hub + spokes:**
this file is the index; the spokes are the focused docs under `docs/shared/`. Load
**only what the task needs** by `read_file` on the stable path. Modeled on
datahen-assistant's `DATAHEN_KB_HUB.md`.

> Skills in `.agents/skills/` are **commands** (`/scrape`, `/qa`, `/run-pipeline`, …).
> Knowledge is **not** a skill — it lives here. Use `/kb` to load this hub, or
> `read_file` a spoke directly. Firmware rules (`docs/shared/agent-rules-gemini.md`)
> are always in effect via `AGENTS.md`.

---

## Task → load these spokes

| When you are… | Read |
|---|---|
| Writing/editing any parser, seeder, `lib/` | `docs/shared/datahen-conventions.md` + `docs/shared/datahen-ruby-parsers.md` |
| Discovering CSS selectors | `docs/shared/selector-discovery.md` + `docs/shared/browser-mcp-tools.md` + `docs/shared/playwright-refs.md` |
| Using browser/network MCP tools | `docs/shared/browser-mcp-tools.md` |
| Filling a product output hash (dmart/greenfield) | `docs/shared/output-hash-rules.md` + `field-spec.json` |
| Working any dhero output (locations/items) | `docs/shared/dhero-output-schema.md` + `dhero-field-spec.json` |
| Building a greenfield spec from the chat prompt | `docs/shared/greenfield-prompt-spec.md` |
| Testing parsers | `docs/shared/parser-testing.md` |
| Running the QA gate / deploy readiness | `.agents/skills/qa/SKILL.md` + `scripts/scraper_qa_report.rb` |
| Designing/reviewing the agent system itself | `docs/shared/agent-best-practices.md` |
| Popups, error taxonomy, auto-chaining, `_log` | `docs/shared/agent-rules-gemini.md` (firmware) |

## Spokes (one line each)

| Spoke | Contents |
|---|---|
| `docs/shared/agent-rules-gemini.md` | **Firmware** — popup sequence, error taxonomy, auto-chaining, `_log` decision log. Always in effect. |
| `docs/shared/datahen-conventions.md` | DataHen V3 parser conventions: top-level scripts, reserved vars, `save_*`, state-file `_log` schema. |
| `docs/shared/datahen-ruby-parsers.md` | Extended Ruby patterns: pagination, dedup, begin/rescue error handling. |
| `docs/shared/selector-discovery.md` | Selector discovery order: `grep_html` → `inspect_element` → `verify_selector`/`evaluate`. |
| `docs/shared/browser-mcp-tools.md` | Playwright MCP Mod tool reference + cheap-before-expensive protocol. |
| `docs/shared/playwright-refs.md` | Playwright snapshot refs (`ref=e123`) are NOT CSS selectors. |
| `docs/shared/output-hash-rules.md` | E-commerce output hash: all spec fields present, nil-explicit, canonical names. |
| `docs/shared/dhero-output-schema.md` | DHero A1/A2/A3 export wiring; `locations` + `items` field reference. |
| `docs/shared/greenfield-prompt-spec.md` | Deriving `field-spec.json` from the user's chat message. |
| `docs/shared/parser-testing.md` | `parser_tester` MCP usage; `quiet` modes; 3-sample rule. |
| `docs/shared/agent-best-practices.md` | 10 production-agent principles + this system's maturity/gap table. |

## Other knowledge surfaces (load by stable path)

- **Pipeline phase docs** — `docs/workflows/phases/*.md` (per-phase step-by-step; read by command skills via the profile `workflow` path).
- **Seeding strategies (dhero)** — `docs/workflows/phases/dhero-seeding-strategies.md`.
- **Field specs** — `field-spec.json` (dmart/greenfield `products`, 49 fields), `dhero-field-spec.json` (locations 28 + items 22).
- **Profiles** — `profiles/<project>.toml` (pipeline phases + `[qa]` gate).
- **Proposals / decisions** — `docs/proposals/*.md`.

---

## Maintaining this KB

1. **Hub + spokes.** This file is the only index. Each spoke is one focused domain — keep them short and task-scoped.
2. **One source of truth.** Knowledge lives in a spoke, never duplicated into a skill. Command skills `read_file` the spoke; they do not restate it.
3. **Stable paths.** Reference spokes by their `docs/shared/<name>.md` path from skills, AGENTS.md, and phase docs so citations stay valid. Renaming a spoke = update every referrer (grep first).
4. **Add a spoke** when a topic is referenced from ≥2 places or is too large to inline. Create `docs/shared/<topic>.md`, add a row to both tables above, and link it from the relevant command skill/phase doc.
5. **Retire a spoke** only after grep shows no remaining referrers.
6. **Firmware vs knowledge.** Rules the agent must always follow → `agent-rules-gemini.md` (prepended via AGENTS.md). Reference material loaded on demand → a spoke here.
