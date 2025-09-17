# Practical Gemini CLI: Structured approach to bloated `GEMINI.md`

*Author:* **Prashanth Subrahmanyam**  
*Published:* 24‑Jul‑2025 | 6 min read  

---

## TL;DR

- A single, massive `GEMINI.md` quickly becomes *context‑bloat* and *rot*.
- The solution is to split the instruction set into **gated modes** that load only the relevant portion of the prompt at any time.
- Use XML‑style tags (`<PROTOCOL:PLAN>`, `<PROTOCOL:IMPLEMENT>` …) to create isolated, machine‑parsable blocks.
- Keep a minimal **`SYSTEM.md`** (firmware layer) and let `GEMINI.md` hold high‑level strategy.

---

## 1. The Problem

I started with a huge `GEMINI.md` that contained:

| Feature | Description |
|---------|-------------|
| PRAR workflow (Perceive → Reason → Act → Refine) | One monolithic rulebook for every task |
| Tech‑stack decision guide | All possible scenarios in one file |

The result: an assistant that was **confused, slow, and often incorrect**.  
Why? Because:

- **Context Bloat:** Too much irrelevant information dilutes focus.
- **Context Rot:** Longer history → poorer performance; the model forgets earlier instructions.

Also, Gemini CLI can’t read files outside its project root, so I couldn’t keep separate “instruction” folders without copying them everywhere.

---

## 2. Gated Execution Through Delayed Instructions

### Core Idea  
Treat `GEMINI.md` like an **IF‑ELSE** statement:

```
IF in phase X
   THEN load only the instructions for that phase
   ELSE stay in current state
```

This ensures the model receives *only* what it needs at each step.

---

## 3. Modes of Operation (the “Gates”)

| Mode | Trigger | What It Does |
|------|---------|--------------|
| **Default State** | Initial | Listens for commands |
| **Explain Mode** | Ask for explanation/investigation | Runs `<PROTOCOL:EXPLAIN>` |
| **Plan Mode** | Request a plan | Runs `<PROTOCOL:PLAN>` |
| **Implement Mode** | After plan approval | Runs `<PROTOCOL:IMPLEMENT>` |

The model can’t jump from one gate to another without explicit user permission (e.g., it won’t enter Implement Mode until you approve the plan).

---

## 4. Protocol Blocks – The “Delayed Instructions”

Each mode has its own **`<PROTOCOL:...>`** block inside `GEMINI.md`.  
Example:

```markdown
<PROTOCOL:PLAN>
# Plan‑mode instructions go here
...
</PROTOCOL:PLAN>
```

When the assistant enters a mode, it loads only the text within that block. This keeps context tight and prevents instruction bleed.

---

## 5. The PRAR Workflow (Gated Execution Path)

| Phase | Mode | Protocol |
|-------|------|----------|
| **Perceive & Understand** | Explain Mode | `<PROTOCOL:EXPLAIN>` |
| **Reason & Plan** | Plan Mode | `<PROTOCOL:PLAN>` |
| **Act & Implement** | Implement Mode | `<PROTOCOL:IMPLEMENT>` |

This structured path guarantees:

1. The assistant *understands* the problem first.
2. It *creates a transparent plan* before acting.
3. It *awaits your approval* before making changes.

---

## 6. Why XML‑Style Tags Work

| Benefit | Explanation |
|---------|-------------|
| **Unambiguous Readability** | The assistant can do a fast string match (`<PROTOCOL:PLAN>`) instead of parsing natural language headers. |
| **Strict Context Scoping** | Each block is hermetically sealed; the model ignores other blocks while in a given mode. |
| **Modularity & Maintainability** | Edit one protocol without affecting others; add new modes (e.g., `<PROTOCOL:TEST>`) easily. |
| **Scalability** | The pattern scales like a `switch` statement, turning a text file into an executable rulebook. |

---

## 7. Resulting Setup

- **`SYSTEM.md`** – Firmware layer with safety rules (absolute paths, destructive‑command checks, etc.).
- **`GEMINI.md`** – Strategic layer containing the PRAR workflow and protocol blocks.

You can find the latest versions in these gists:

| File | Link |
|------|------|
| `GEMINI.md` | <https://gist.github.com/ksprashu/6ff099d07eea9b768631a230a7527a52> |
| `SYSTEM.md` | <https://gist.github.com/ksprashu/cb37b20dd21594822bd5ec9f0cf8c5e7> |

> **Note:** These files have evolved through weeks of experimentation. They may need tweaking for your own use case.

---

## 8. Take‑aways

1. **Don’t dump everything into one prompt** – it breeds bloat and rot.
2. **Use gated, mode‑based execution** to keep context relevant.
3. **Leverage simple tags** (`<PROTOCOL:...>`) for machine‑parsable instruction blocks.
4. **Separate firmware (SYSTEM.md) from strategy (GEMINI.md)** for clarity and safety.

---

## 9. Further Reading

This post is part of the *Practical Gemini CLI* series.  
If you found it useful, check out more deep dives:

- [Practical Gemini CLI – Deep Dive & Customisations](https://medium.com/google-cloud/practical-gemini-cli-a-series-of-deep-dives-and-customisations-30afc4766bdf)

---