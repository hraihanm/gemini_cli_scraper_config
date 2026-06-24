# Proposal: Cursor CLI Orchestration — Per-Phase Fresh Sessions

**Created:** 2026-06-24
**Status:** Done
**Scope:** `docs/shared/agent-rules-gemini.md`, `.agents/skills/run-pipeline/SKILL.md`

---

## 1. Background

Gemini CLI has been deprecated. Antigravity CLI (agy) is deferred. The team is moving to
**Cursor CLI** (`agent`) as the primary agent runner. The existing auto-chaining design ran
all pipeline phases in one agy session (`auto_next=true` = in-session chaining). This caused
context window accumulation across 5 phases, leading to degraded instruction-following, missed
probes, and hallucinated completions by Phase 4-5.

---

## 2. Current State

`docs/shared/agent-rules-gemini.md` Auto-Chaining Rules (lines 98-128):

> "Antigravity CLI runs the whole pipeline in **one session**. Chaining is **in-session** —
> do **not** spawn a new `agy` process or shell script."
> Step B: "Begin the next phase in this same session"

`/run-pipeline` SKILL.md "Execute all phases":
> "Run that phase to completion exactly as its dedicated skill would… continue to the next
> entry **in this same session**"

Both are wired to in-session chaining — directly opposed to fresh-context-per-phase.

---

## 3. Problem(s)

1. In-session chaining accumulates context across phases — each phase adds tool call outputs,
   browser snapshots, and intermediate reasoning to the window. Phase 5 runs with the full
   weight of Phases 1-4 still in context.
2. Long sessions degrade instruction-following — the agent shortcuts probes ("looks fine"),
   misses required state file fields, and skips checklist items.
3. agy-specific language throughout — references to `agy --dangerously-skip-permissions`
   are invalid in a Cursor CLI environment.

---

## 4. Proposal

### 4.1 New auto-chaining rule (agent-rules-gemini.md)

Replace in-session chaining with **subprocess chaining**:

When `auto_next=true`:
1. `browser_close()` — close browser before exiting
2. Invoke next phase as a fresh `agent` subprocess:
   ```
   agent -p --yolo --trust "/<next_phase> scraper=<name> project=<project> auto_next=true"
   ```
3. **Exit this session** — do not continue in the current context window

Resume command (on failure) uses same pattern:
```
agent --yolo "/<failed_phase> scraper=<name> project=<project> auto_next=true"
```
(interactive, so user can watch and intervene)

### 4.2 /run-pipeline as orchestrator

`/run-pipeline` becomes a thin orchestrator that:
1. Reads the profile phase array
2. For each phase: invokes `agent -p --yolo --trust "/<command> ..."` via `run_terminal_cmd`
3. After each subprocess exits: reads `phase-status.json` to gate-check completion
4. On failure: STOP, print the failed phase's resume command, exit
5. After all phases: runs QA gate the same way, then writes README

The user starts one interactive Cursor composer session with `/run-pipeline`, watches
progress phase by phase, and each phase runs as a cold, focused subprocess.

---

## 5. Implementation Order

| Step | File | Change |
|---|---|---|
| 1 | `docs/shared/agent-rules-gemini.md` | Replace Auto-Chaining section with Cursor CLI subprocess pattern |
| 2 | `.agents/skills/run-pipeline/SKILL.md` | Replace inline "Execute all phases" with orchestrator loop |
| 3 | Proposal → Done | Update status |
