# Proposal: Enterprise-Grade, Platform-Agnostic Agent via the SKILL.md Layering Rationale

**Created:** 2026-06-12
**Status:** Draft
**Scope:** `.agents/skills/`, `.agents/plugins/`, `profiles/`, `docs/workflows/phases/`, `docs/shared/`, `scripts/`, CI

## 1. Background

The project drives scraping agents (currently Antigravity CLI) through a layered
instruction architecture: SKILL.md slash commands → TOML profiles → workflow docs →
shared rules → boilerplate templates → MCP tools. The user wants to evolve this into
(a) an enterprise-grade setup and/or (b) a general, platform-agnostic agent system,
using the SKILL.md rationale (progressive disclosure: name+description always loaded,
body loaded on invocation, heavy knowledge in referenced files).

## 2. Current State

The layering is already ~80% platform-agnostic:

- **Skills are thin adapters.** `.agents/skills/scrape/SKILL.md` contains zero domain
  logic — it parses args, loads `profiles/<project>.toml`, reads the workflow path from
  `pipeline.phases[N].workflow`, and executes that doc. Domain knowledge lives in
  `docs/workflows/phases/*.md` (13 files) and `docs/shared/*.md` (10 files).
- **Profiles are declarative.** `profiles/dhero.toml` defines pipeline phases, template
  dir, field spec, scope — adding a project requires no new skill logic.
- **Templates are platform-neutral Ruby** (`templates/*_boilerplate/`).
- **Tools are a separate layer** (playwright-mcp-mod, MCP config in
  `.agents/mcp_config.json`), with `npm run check-drift` guarding tool-doc sync.

## 3. Problem(s)

1. **Triple skill duplication with confirmed drift.** Each skill exists in 3 copies:
   `.agents/skills/<name>/SKILL.md`, flat `.agents/skills/<name>.md` (added for native
   workspace loading, commit 4004fa8), and
   `.agents/plugins/gemini_cli_testbed/skills/<name>/SKILL.md`. The dir and flat copies
   of `scrape` already differ today. No single source of truth, no drift check.
2. **Platform leakage into the knowledge layer.** 18 occurrences of Antigravity tool
   names (`read_file`, `run_terminal_cmd`, `write_file`) in 4 workflow docs
   (`01-site-discovery.md`, `greenfield-01-site-discovery.md`, `api-01-scrape.md`,
   `api-03-details.md`). Porting to Claude Code / another runner requires editing the
   knowledge layer, not just the adapter layer.
3. **Persona file is platform-named.** `AGENTS.md` mixes durable methodology (PARSE,
   ref-vs-selector protocol) with Antigravity-specific tool call syntax.
4. **No validation gates.** Nothing lints SKILL.md frontmatter, verifies that every
   `workflow =` path in profile TOMLs exists, or that every skill named in a pipeline
   has a SKILL.md. A typo ships silently.
5. **Evals exist but are not enforced.** `scraper_run_evals` and `_log` decision
   entries exist, but no CI/exit gate consumes them.

## 4. Proposal

### 4.1 Single source of truth + build step (kills duplication)

Create `skills-src/<name>.md` as the only hand-edited copy. A build script
(`scripts/build-skills.ps1`, extending `setup-agy.ps1`) emits all platform targets:

```
skills-src/scrape.md
  └─ build ─→ .agents/skills/scrape/SKILL.md        (agy dir form)
            → .agents/skills/scrape.md              (agy flat form)
            → .agents/plugins/.../skills/scrape/SKILL.md
            → .claude/skills/scrape/SKILL.md        (future: Claude Code)
```

Generated copies get a `<!-- GENERATED from skills-src/scrape.md — do not edit -->`
header. Extend `check-drift` to fail if a generated copy differs from its source build.

### 4.2 Tool-verb indirection (purges platform leakage)

Add `docs/shared/tool-map.md` defining abstract verbs and per-platform bindings:

| Abstract verb | Antigravity | Claude Code |
|---|---|---|
| READ_FILE | `read_file` | `Read` |
| WRITE_FILE | `write_file` | `Write` |
| RUN_COMMAND | `run_terminal_cmd` | `Bash` / `PowerShell` |

Rewrite the 18 occurrences in the 4 workflow docs to abstract verbs (e.g.
"READ_FILE → `profiles/<project>.toml`"). Each platform's persona file states its
binding once. Workflow docs become runner-portable; MCP tool names
(`browser_grep_html` etc.) stay literal since MCP is itself the cross-platform layer.

### 4.3 Split persona: durable vs platform

Split `AGENTS.md` into `docs/shared/persona-core.md` (PARSE methodology, ref-protocol,
expertise — platform-free) and a thin per-platform `AGENTS.md` / `CLAUDE.md` shim that
includes the core by reference plus the platform's tool-map binding.

### 4.4 Validation gates (enterprise-grade floor)

`scripts/validate-agent-config.ps1` (run in CI / pre-commit):
- every `workflow =` and `boilerplate_dir` path in `profiles/*.toml` exists
- every `command =` in a profile has a matching `skills-src/<name>.md`
- SKILL.md frontmatter has `name` + `description`; name matches directory
- generated skill copies match the build output (drift check)
- `.agents/.env` is gitignored; `.env.example` has no real keys

### 4.5 Eval gate (enterprise-grade ceiling)

Per pipeline phase, keep eval fixtures (3 sample pages, already convention) under
`evals/<project>/<phase>/` and make `scraper_run_evals` score a required gate before a
phase is marked verified — agent must write the score into the state file `_log`.

### 4.6 Generalization beyond scraping (optional, later)

The pattern (skill = arg-parse + profile-lookup + workflow-execute) is domain-free.
A new domain = new profile TOML + workflow docs + boilerplate template. If desired,
add one generic `/phase project=X n=N` skill, keeping current names as aliases.

## 5. Implementation Order

| # | Step | Effort | Risk |
|---|---|---|---|
| 1 | `skills-src/` + build script + regenerate the 3 copy sets | ~2h | Low — mechanical; reconcile the existing scrape drift first |
| 2 | Drift check for generated skills in `check-drift` | ~30m | Low |
| 3 | `validate-agent-config.ps1` (path/frontmatter/profile checks) | ~1–2h | Low |
| 4 | Tool-map + rewrite 18 occurrences in 4 workflow docs | ~1h | Medium — verify agy still executes phases correctly after the verb rewrite |
| 5 | Persona split (AGENTS.md → persona-core + shim) | ~1h | Medium — regression-test one full dhero pipeline run |
| 6 | Eval gate wiring | ~2h | Medium |
| 7 | Generic `/phase` skill (optional) | ~1h | Low |

Steps 1–3 deliver the enterprise floor (single source, validation, no silent drift).
Steps 4–5 deliver platform agnosticism. Step 6 delivers measurable quality. Each step
is independently shippable.
