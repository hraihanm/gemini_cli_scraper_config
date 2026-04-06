# Proposal: Rebuild Mode

**Created:** 2026-03-26
**Status:** In Progress
**Scope:** `.gemini/commands/dmart-rebuild.toml` (new)

---

## 1. Background

Scrapers break when websites update — redesigns change selectors, APIs version-bump, pagination shifts, logic needs adjustment. Currently there's no rebuild command. You either hand-edit blind or re-run the full 3-phase pipeline from scratch.

## 2. Current State

- Phase commands always start fresh — no way to pass an existing scraper as context
- No command reads an existing parser and updates it against the live site
- `generated_scraper/<name>/` already contains everything needed as reference

## 3. Problem(s)

- Re-running the full pipeline re-discovers everything, including things that didn't change
- No structured path for "read the old parser, navigate the site, fix what broke"

## 4. Proposal

### Command

```
/dmart-rebuild scraper=<name> [phase=details|navigation|all]
```

| Param | Default | Description |
|---|---|---|
| `scraper` | required | Existing scraper name in `generated_scraper/` |
| `phase` | `details` | Which parser(s) to update: `details`, `navigation` (listings+categories), `all` |

### Workflow

1. Read existing parser(s) and state files as context
2. Navigate the live site
3. Check what still works, find what broke
4. Update the parser — selectors, logic, whatever needs changing
5. Back up original before writing: `parsers/_backup_YYYYMMDD/`
6. Test with parser_tester

The agent decides what to change. No artificial separation of "selectors only" vs "logic" — just fix what's broken.

### What is always preserved

- `config.yaml` — never touched
- `lib/helpers.rb` — never touched
- `evals/` fixtures — never touched

### HTML vs API

Auto-detected from `discovery-state.json`. One command handles both.

## 5. Implementation Order

1. Write `dmart-rebuild.toml` — single TOML, all phases
