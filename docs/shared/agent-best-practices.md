# Production-grade enterprise AI agents — best practices

Reference for designing and reviewing **this scraper-generation system** (and agent
systems generally). The through-line: a production agent is a **system around** an
LLM — deterministic validation, explicit state, gates, observability, and
guardrails — where the model is one swappable, fallible component.

## The 10 principles

1. **Push work out of the LLM into deterministic code.** The model decides and
   orchestrates; tools compute and validate. Anything with a correct answer
   (schema checks, math, ID uniqueness, gates) belongs in code. Give the model
   typed tools with narrow contracts, not free-form shell.
2. **Evals and gates are the agent's test suite.** Regression fixtures
   (input→expected) run on every prompt/model/tool change; quality gates block
   promotion on objective criteria. Gate on *required* things; surface the rest
   as warnings. Track the score over time — treat prompt/model bumps like code.
3. **Context engineering > prompt engineering.** Hub-and-spokes knowledge loaded
   on demand by stable path; one source of truth per fact; checkpoint long-running
   work into explicit state files so it survives context limits and is resumable.
4. **Observability — every decision inspectable.** Structured decision logs, traces
   per tool call, token/cost per run, run IDs, and a human-readable run report so a
   person can take over without re-deriving context. Failure/debug records, never
   silent drops.
5. **Failure handling and idempotency.** Error taxonomy — transient (retry+backoff)
   vs. structural (STOP, surface) vs. data-gap (log, continue). Idempotent ops +
   dedup keys. Bounded retries, then a clean stop with a precise resume instruction.
6. **Guardrails, least privilege, human-in-the-loop.** Confirm before
   irreversible/outward-facing actions; least-privilege tools and scoped secrets;
   treat fetched content as untrusted **data, not instructions** (prompt-injection
   defense); a clear autonomous-vs-approval policy.
7. **Decomposition — many narrow skills over one mega-agent.** Single-purpose
   skills/sub-agents with clear interfaces and validated handoff contracts beat one
   giant prompt; they are far more testable and debuggable.
8. **Cost, latency, model routing.** Cheap-before-expensive tool ordering; route by
   difficulty (small models for routine steps, frontier for hard reasoning); cache
   aggressively; budget cost/latency per run.
9. **Versioning, reproducibility, governance.** Pin and version prompts, model IDs,
   specs, and tool schemas in run metadata. Data governance: PII handling,
   retention, region, audit trails.
10. **Treat the agent like a product.** CI smoke/eval tests on the agent's own
    assets, staged rollout, monitoring with alerting on quality/cost/error drift,
    and a feedback loop from production failures back into evals.

## How this system measures up (2026-06-21)

| # | Principle | Status | Evidence / gap |
|---|---|---|---|
| 1 | Deterministic over LLM | 🟢 Strong | `scripts/scraper_qa_report.rb`, `parser_tester`, validators do the judging — not the model |
| 2 | Evals & gates | 🟡 Partial | `scraper_run_evals` + `deploy-readiness.json` exist; **gaps:** eval gate optional not mandatory, fixtures sparse, not CI-wired |
| 3 | Context engineering | 🟢 Strong | hub-and-spokes KB (`docs/shared/KB_HUB.md`), per-phase state files, profiles |
| 4 | Observability | 🟡 Partial | `_log` decision trail, debug collections, `GENERATION_REPORT.md`; **gap:** no per-run token/cost/latency telemetry; session-audit counts are self-reported |
| 5 | Failure handling / idempotency | 🟢 Strong | refetch/limbo/data-gap taxonomy, `_id` dedup, finishers, debug collections |
| 6 | Guardrails / least privilege / HITL | 🟡 Partial | deploy confirms, dev-branch + no-delete rules; **gap:** no explicit prompt-injection rule for scraped content; secret/PII handling not codified |
| 7 | Decomposition | 🟢 Strong | narrow command skills, phased pipeline, Phase-2→3 contract checks |
| 8 | Cost / latency / routing | 🟠 Thin → 🗓 Planned | cheap-before-expensive tool rule + per-run telemetry now in `deploy-readiness.json._meta`; **planned:** model routing + cost budgets (see below) |
| 9 | Versioning / repro / governance | 🟡 Partial | proposal discipline, versioned field specs; **gap:** model/prompt IDs not pinned into run metadata; no data-governance doc |
| 10 | Lifecycle as product | 🟠 Thin | `prompt-smoke.ps1`, setup script; **gap:** CI not wired to run smoke+evals; no drift monitoring/alerting |

## Done (2026-06-21)

Implemented via `docs/proposals/2026-06-21-production-hardening-ci-evals-guardrails.md`:
- **CI (#1,#10):** `scripts/ci-check.sh` + `.github/workflows/agent-ci.yml` (syntax, required files, profile/spec validity, best-effort evals).
- **Mandatory eval gate (#2):** `scraper_qa_report.rb --require-eval` (missing score blocks); `/qa` + `/run-pipeline` enforce it.
- **Telemetry + version pinning (#4,#9):** `deploy-readiness.json._meta.versions` (field_spec_version, git_commit, model, agy_version) + `.telemetry` (tool_calls/elapsed/cost).
- **Prompt-injection guardrail (#6 in chat / principle #6):** firmware rule "Untrusted Content" in `docs/shared/agent-rules-gemini.md`.

## Planned

- **Cost / model routing (principle #8):** route routine edits to a smaller/faster
  model and reserve a frontier model for discovery/reasoning; set a per-run cost
  budget and alert on breach. Partly a harness/`agy` concern (model selection lives
  outside the repo), so deferred until the telemetry above gives a cost baseline to
  optimize against. Track via a future proposal.
- **Drift monitoring (#10):** alert when eval score / nil-rate / cost regress
  across runs (needs a place to persist run history beyond per-scraper reports).
