---
name: export-chat
description: "Export a Cursor Composer chat session to Markdown, including full tool call inputs and outputs. Usage: /export-chat [session name or ID]"
---

Export a Cursor Composer session to a readable Markdown file with complete tool call I/O.

## How it works

Reads directly from Cursor's SQLite state database (`AppData/Roaming/Cursor/User/globalStorage/state.vscdb`).
Reconstructs the full conversation: user messages, assistant responses, and every tool call with its input and output.

## Steps

1. **If no session name given** — list recent sessions:
   ```
   run_terminal_cmd: python D:\DataHen\projects\gemini_cli_testbed\scripts\export_cursor_chat.py
   ```
   Show the list to the user and ask which session to export.

2. **If session name or ID given** — export it:
   ```
   run_terminal_cmd: python D:\DataHen\projects\gemini_cli_testbed\scripts\export_cursor_chat.py "<name or id>"
   ```
   Output path: `exported/<date>-<slug>.md` in the gemini_cli_testbed project dir.

3. **Custom output path** — use `--out`:
   ```
   run_terminal_cmd: python D:\DataHen\projects\gemini_cli_testbed\scripts\export_cursor_chat.py "<name>" --out "<path>"
   ```

## Output format

- User messages as `## 👤 User`
- Assistant responses as `## 🤖 Assistant`
- Tool calls as collapsible `<details>` blocks with JSON input + output (truncated at 8KB)

## Notes

- The script opens the DB read-only — no risk of corrupting Cursor's state.
- Sessions from all projects appear in the list, not just the current one.
- If Cursor is actively writing to the DB (session in progress), wait until the session ends before exporting to get the complete output.
- Override DB path: set `CURSOR_GLOBAL_DB` env var.
