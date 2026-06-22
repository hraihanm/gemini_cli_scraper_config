# Proposal: Knowledge base as hub-and-spokes (separate knowledge from command skills)

**Created:** 2026-06-21
**Status:** Done
**Decisions:** keep `docs/shared/` + add hub (no renumber); collapse all 9 knowledge skills → one `/kb`.
**Scope:** `.agents/skills/` (remove 9 knowledge skills, add 1 `kb` skill), `docs/shared/` (add KB hub), ~12 command skills (reword auto-load language), `AGENTS.md`, `CLAUDE.md`, `scripts/setup-agy.ps1`.

## 1. Background
The user wants to **move knowledge-type skills out of `.agents/skills/`** and manage a knowledge base the way **datahen-assistant** does. Today `.agents/skills/` mixes 13 command skills with 9 knowledge skills, so the AGY/Cursor slash-command list is cluttered with non-commands.

The datahen-assistant model (studied for this proposal):
- **One** bootstrap skill `cursor/datahen-kb/SKILL.md` with `disable-model-invocation: true` (manual `/datahen-kb`, not auto-invoked).
- A **hub** `DATAHEN_KB_HUB.md` — cheat sheet + task→doc routing table + best-practice notes.
- **Numbered flat spoke docs** `datahen/NN-*.md` + `workflows/` + `reference/` + `projects/` subfolders, loaded selectively by stable path.
- Principle (their own words): *"Hub + spokes: one short hub + focused files per domain. Stable paths so citations stay valid. Load only what the task needs."*

## 2. Current State
- **9 knowledge skills** in `.agents/skills/` are each 6-line thin pointers to `docs/shared/*.md`: `browser-mcp-tools`, `datahen-conventions`, `datahen-ruby-parsers`, `dhero-output-schema`, `greenfield-prompt-spec`, `output-hash-rules`, `parser-testing`, `playwright-refs`, `selector-discovery`.
- **13 command skills** are real orchestration (scrape, navigation/details/restaurant/menu parsers, api-*, greenfield-scrape, qa, dhero-qa, run-pipeline).
- The **actual knowledge already lives in `docs/shared/*.md`** — the skills only shim it for AGY semantic auto-load + a `/<name>` command.
- Reference audit (knowledge docs are reachable without their skill):
  | doc | non-self refs | also in AGENTS.md "Extended playbooks" |
  |---|---|---|
  | agent-rules-gemini | 21 | firmware (always prepended) |
  | datahen-conventions | 11 | yes |
  | selector-discovery | 5 | — (refs in command skills/phase docs) |
  | dhero-output-schema | 2 | — |
  | greenfield-prompt-spec | 2 | — |
  | browser-mcp-tools / datahen-ruby-parsers / output-hash-rules / parser-testing / playwright-refs | 1 each | yes |
  → **No doc orphans** when its skill is removed.
- `CLAUDE.md` "Two-Layer Model" documents knowledge-as-skill. `setup-agy.ps1` syncs skill dirs generically (one cosmetic echo names knowledge skills, line ~86). ~12 command skills contain "knowledge skills (X, Y) auto-load by semantic match" wording.

## 3. Problem(s)
1. Slash-command surface is polluted: 9 of 22 `/<name>` entries are not commands.
2. Two represented sources of truth (skill shim + `docs/shared/*.md`) for the same knowledge → drift risk and duplicated maintenance.
3. No KB **index/hub** — an agent (or human) has no single map of what knowledge exists and when to load it. datahen-assistant has one; this repo doesn't.
4. Knowledge skills rely on AGY semantic auto-load, which is implicit and unversioned; the explicit `read_file docs/shared/X.md` references in command skills already cover the pipeline flow.

## 4. Proposal
Adopt the datahen-assistant hub-and-spokes model. **Keep `docs/shared/*.md` as the spokes** (stable paths already referenced 50+ times — do NOT renumber/move them), add a hub, collapse 9 knowledge skills → 1.

1. **Create `docs/shared/KB_HUB.md`** — the index: a task→doc routing table (e.g. "writing a parser → datahen-conventions + datahen-ruby-parsers"; "selectors → selector-discovery + browser-mcp-tools + playwright-refs"; "dhero output → dhero-output-schema"; "QA → parser-testing + output-hash-rules"), a one-line description per spoke, links to `docs/workflows/phases/` and the field specs, and a short "how to maintain the KB" section (hub+spokes, stable paths, one fact per file).
2. **Create one skill `.agents/skills/kb/SKILL.md`** — thin bootstrap that `read_file`s `docs/shared/KB_HUB.md` then the matching spoke(s). Mirror datahen-assistant's `disable-model-invocation: true` so `/kb` is a **manual** entry point, not auto-invoked (verify AGY honors the key; if not, keep a terse description and accept semantic match).
3. **Delete the 9 knowledge skill directories** from `.agents/skills/`.
4. **Reword the ~12 command skills**: replace "the X / Y knowledge skills apply (auto-load by semantic match)" with explicit "`read_file` → `docs/shared/X.md`, `docs/shared/Y.md` as needed (index: `docs/shared/KB_HUB.md`)". This makes knowledge loading explicit and removes dependence on removed skills.
5. **Update `AGENTS.md`** — point the knowledge sections at `docs/shared/KB_HUB.md` as the index; keep the existing Extended-playbooks path list.
6. **Update `CLAUDE.md`** "Two-Layer Model" — Layer 2 becomes **command skills only**; knowledge is the `docs/shared/` KB (hub + spokes), loaded via `read_file` or `/kb`. Update the "knowledge skills are thin pointers" wording.
7. **Update `setup-agy.ps1`** — fix the cosmetic echo (drop the knowledge-skill names; mention `/kb`).

### Explicitly NOT doing
- **No renumbering / moving** `docs/shared/*.md` (datahen uses `NN-` prefixes; this repo's descriptive names are already stable and heavily cited — renaming would break 50+ references for cosmetic parity).
- Not touching `agent-rules-gemini.md` content (firmware, always in effect via AGENTS.md).

## 5. Implementation Order
| # | Step | Effort | Risk |
|---|---|---|---|
| 1 | Write `docs/shared/KB_HUB.md` (hub + routing + maintenance notes) | M | Low |
| 2 | Add `.agents/skills/kb/SKILL.md` | S | Low |
| 3 | Reword ~12 command skills (auto-load → explicit read_file + hub) | M | Low |
| 4 | Update AGENTS.md + CLAUDE.md + setup-agy.ps1 echo | S | Low |
| 5 | Delete 9 knowledge skill dirs | S | Low |
| 6 | Verify: every `docs/shared/*.md` still has a non-skill referencer; re-run setup-agy mentally (generic sync); grep for dangling `/skill` mentions | S | Low |

## 6. Implementation Result (2026-06-21)
- **Hub:** `docs/shared/KB_HUB.md` — task→doc routing table, per-spoke one-liners, links to phase docs/field specs, and a "maintaining this KB" section.
- **One skill:** `.agents/skills/kb/SKILL.md` (`disable-model-invocation: true` — manual `/kb` bootstrap → reads hub then the needed spokes).
- **Deleted 9 knowledge skills:** browser-mcp-tools, datahen-conventions, datahen-ruby-parsers, dhero-output-schema, greenfield-prompt-spec, output-hash-rules, parser-testing, playwright-refs, selector-discovery. `.agents/skills/` is now **13 commands + `kb`**.
- **Reworded 12 command-skill preambles:** "knowledge skills auto-load by semantic match" → explicit `read_file → docs/shared/<spoke>.md` + hub pointer.
- **Docs:** `AGENTS.md` (KB index pointer + Layering now distinguishes commands vs KB), `CLAUDE.md` (Two-Layer Model → skills-commands-only + `docs/shared/` KB row; "Locations" updated), `scripts/setup-agy.ps1` echo, `scripts/prompt-smoke.ps1` (fixed 3 stale paths: `.agents/workflows/*` + deleted skill → current skill paths + `KB_HUB.md`).
- **Verified:** every `docs/shared/*.md` still has ≥1 non-skill referrer (no orphans); zero dangling refs to deleted skills (as paths or `/commands`); `prompt-smoke.ps1` passes; all remaining SKILL.md frontmatter intact.
- **Not done (per decision):** no renumber/move of `docs/shared/` spokes.

**Follow-up:** re-run `pwsh -File scripts/setup-agy.ps1` + restart `agy`/Cursor so the removed skills disappear and `/kb` registers.

---

*Decisions resolved via AskUserQuestion; implemented same session.*
