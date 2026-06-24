---
name: datahen-kb
description: Load DataHen knowledge base context from the shared hub. Use when the user invokes /datahen-kb, says "read DataHen KB", "read this first" for DataHen, or starts DataHen scraper/hen work.
disable-model-invocation: true
---

# DataHen knowledge base (Cursor)

Thin bootstrap for the shared KB in **datahen-assistant**. Substantive docs stay in the repo — do not duplicate them here.

## 1. Resolve repo path

Read **`~/.config/datahen-assistant/repo-path`** (one line, absolute path, no trailing slash).

If missing, tell the user to run:

```bash
bash /path/to/datahen-assistant/scripts/install-cursor-datahen-kb-skill.sh /path/to/datahen-assistant
```

Set **`REPO_ROOT`** to that path.

## 2. Read (in order)

1. **`{REPO_ROOT}/agents/bootstrap.md`** — session rules, `hen parser try`, symptom table, deploy/QA finish
2. **`{REPO_ROOT}/DATAHEN_KB_HUB.md`** — cheat sheet (skim; details live in topic files)
3. **Topic files below** — load what matches the task (do not read all `datahen/*.md`)
4. **Scraper repo:** `DATAHEN_PROJECT.txt` (+ optional lines in `DATAHEN_PROJECT.md`)

## 3. Task routing — also read

| Task | Topic files |
|------|-------------|
| Writing / editing Ruby (parsers, seeders, `lib/`) | `datahen/02-seeder-parser-finisher.md` + **`datahen/17-ruby-version-local-vs-workers.md`** (plain Ruby checklist) |
| `hen parser try`, local debug | `datahen/07-local-debug-cli.md` + **`14`** if `config.yaml` has `input_vars`/`env_vars` + `17` if try ≠ cloud |
| Job `input_vars` / `env_vars` / secrets | `datahen/14-variables-secrets.md` (+ **`07`** §1 before try/exec) |
| Deploy, git branch, finish QA fix on live job | `datahen/16-git-deploy-branches-and-agent-safety.md` |
| Client QA feedback / “is issue X fixed?” / export wrong | **`datahen/workflows/22-qa-feedback-triage.md`** + `datahen/projects/dhero-output-schema.md` + `16` §4 |
| Patch bad output rows (`hen finisher exec`, no config change) | **`datahen/13-finisher-qa.md`** § Ad-hoc output patch + `05` § Patch outputs |
| Debug collections (per-page count + list in `outputs`) | **`datahen/04-outputs-exporters-schemas.md`** § Debug collections |
| Empty job, seeder crash, stats / reparse | `bootstrap.md` §5 + `datahen/05-operations-debugging.md` |
| E‑commerce listings → details | `datahen/06-ecommerce-listings-details-patterns.md` |

Full index → `{REPO_ROOT}/datahen/00-agent-guide.md`

## 4. Cursor-specific

- **Tool shells are isolated** — chain `dht <dht_type> && export debug=true && … && hen …` in **one** command; never assume a prior step exported `DATAHEN_TOKEN` or **`input_vars`**.
- **Before `hen parser try` / `exec` or seeder try/exec:** read `config.yaml` `input_vars` / `env_vars` and **`export` each name** (e.g. `export country=KW`) in the same command — local Ruby does not inherit job vars. See `07` §1.
- **Before deploy:** `ruby -c` on changed Ruby files; grep for Rails helpers / Ruby 3 syntax — see `17` § pre-deploy.
- Continue with the user’s request using loaded context.
