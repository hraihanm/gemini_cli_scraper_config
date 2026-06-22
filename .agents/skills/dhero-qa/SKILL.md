---
name: dhero-qa
description: "Alias for /qa with project=dhero — QA gate emitting spec.csv, GENERATION_REPORT.md, deploy-readiness.json. Usage: /dhero-qa scraper=<name> [eval-score=N]"
---

`/dhero-qa` is a thin alias for the generic **`/qa`** skill with `project=dhero`.

When invoked, run the `qa` skill exactly as if the user typed `/qa scraper=<name> project=dhero [eval-score=N]` — `read_file` → `.agents/skills/qa/SKILL.md` and follow every step with `project=dhero` (collections `locations` + `items`). All behavior, gates, and artifacts are defined there.
