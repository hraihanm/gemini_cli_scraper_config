#!/usr/bin/env python3
"""
export_cursor_chat.py — export a Cursor Composer session to Markdown.

Reads directly from Cursor's SQLite state database and reconstructs the
full conversation including tool call inputs and outputs.

Usage:
    python scripts/export_cursor_chat.py                        # list sessions
    python scripts/export_cursor_chat.py <composer_id_or_name> # export one
    python scripts/export_cursor_chat.py <id> --out <file.md>  # custom output path

Examples:
    python scripts/export_cursor_chat.py
    python scripts/export_cursor_chat.py "Snoonu KW QA scraper"
    python scripts/export_cursor_chat.py a8953290 --out exported/qa-session.md
"""

import sqlite3
import json
import sys
import os
import re
from datetime import datetime, timezone
from pathlib import Path

DB_PATH = Path(os.environ.get(
    "CURSOR_GLOBAL_DB",
    Path.home() / "AppData/Roaming/Cursor/User/globalStorage/state.vscdb"
))

USER_TYPE  = 1
ASST_TYPE  = 2
# Note: there is no separate tool bubble type. Tool calls are type-2 bubbles
# with toolFormerData populated and empty text.


def open_db():
    if not DB_PATH.exists():
        sys.exit(f"DB not found: {DB_PATH}\nSet CURSOR_GLOBAL_DB env var to override.")
    return sqlite3.connect(f"file:{DB_PATH}?mode=ro", uri=True)


def list_sessions(con):
    row = con.execute(
        "SELECT value FROM ItemTable WHERE key='composer.composerHeaders'"
    ).fetchone()
    if not row:
        sys.exit("No composer sessions found in DB.")
    headers = json.loads(row[0])
    composers = headers.get("allComposers", [])
    print(f"{'ID':10}  {'Updated':20}  Name")
    print("-" * 80)
    for c in sorted(composers, key=lambda x: x.get("lastUpdatedAt") or 0, reverse=True)[:40]:
        ts = c.get("lastUpdatedAt")
        dt = datetime.fromtimestamp(ts / 1000, tz=timezone.utc).strftime("%Y-%m-%d %H:%M") if ts else "?"
        cid = c.get("composerId", "")[:8]
        name = (c.get("name") or "Untitled")[:60]
        print(f"{cid:10}  {dt:20}  {name}")


def find_composer(con, query: str):
    row = con.execute(
        "SELECT value FROM ItemTable WHERE key='composer.composerHeaders'"
    ).fetchone()
    headers = json.loads(row[0])
    composers = headers.get("allComposers", [])
    q = query.lower()
    for c in composers:
        cid = c.get("composerId", "")
        name = (c.get("name") or "").lower()
        if cid.startswith(q) or q in name:
            return c
    sys.exit(f"No session matching '{query}'. Run without args to list sessions.")


def fetch_bubble(con, composer_id: str, bubble_id: str) -> dict:
    key = f"bubbleId:{composer_id}:{bubble_id}"
    row = con.execute(
        "SELECT value FROM cursorDiskKV WHERE key=?", (key,)
    ).fetchone()
    if not row:
        return {}
    return json.loads(row[0])


def bubble_text(bubble: dict) -> str:
    """Extract readable text from a bubble."""
    text = bubble.get("text", "")
    if isinstance(text, str) and text.strip():
        return text.strip()
    # Fall back to richText if it's a non-empty string
    rt = bubble.get("richText", "")
    if isinstance(rt, str) and rt.strip():
        return rt.strip()
    return ""


def format_tool_call(bubble: dict) -> str:
    """Format a tool-call bubble (type=15) as markdown."""
    tfd = bubble.get("toolFormerData")
    if not tfd or not isinstance(tfd, dict):
        return ""

    name   = tfd.get("name", "unknown_tool")
    status = tfd.get("status", "?")
    params = tfd.get("params", "")
    result = tfd.get("result", "")

    # Try to pretty-print params JSON
    try:
        params_obj = json.loads(params) if isinstance(params, str) else params
        params_str = json.dumps(params_obj, indent=2, ensure_ascii=False)
    except Exception:
        params_str = str(params)

    # Try to pretty-print result JSON
    try:
        result_obj = json.loads(result) if isinstance(result, str) else result
        result_str = json.dumps(result_obj, indent=2, ensure_ascii=False)
    except Exception:
        result_str = str(result)

    # Truncate very large outputs (>8KB) to keep the export readable
    MAX = 8000
    if len(result_str) > MAX:
        result_str = result_str[:MAX] + f"\n... [truncated {len(result_str)-MAX} chars]"

    lines = [
        f"#### 🔧 `{name}` ({status})",
        "",
        "<details><summary>Input</summary>",
        "",
        "```json",
        params_str[:4000] + ("..." if len(params_str) > 4000 else ""),
        "```",
        "",
        "</details>",
        "",
        "<details><summary>Output</summary>",
        "",
        "```",
        result_str,
        "```",
        "",
        "</details>",
        "",
    ]
    return "\n".join(lines)


def export_session(composer: dict, con, out_path: Path):
    composer_id = composer["composerId"]
    name = composer.get("name") or "Untitled"
    created_ts = composer.get("createdAt")
    created = datetime.fromtimestamp(created_ts / 1000, tz=timezone.utc).strftime(
        "%Y-%m-%d %H:%M UTC"
    ) if created_ts else "unknown"

    # Fetch composerData for the ordered bubble list
    cd_key = f"composerData:{composer_id}"
    cd_row = con.execute(
        "SELECT value FROM cursorDiskKV WHERE key=?", (cd_key,)
    ).fetchone()
    if not cd_row:
        sys.exit(f"No composerData found for {composer_id}")
    cd = json.loads(cd_row[0])

    headers = cd.get("fullConversationHeadersOnly", [])

    lines = [
        f"# {name}",
        "",
        f"**Session ID:** `{composer_id}`  ",
        f"**Created:** {created}  ",
        f"**Exported:** {datetime.now(tz=timezone.utc).strftime('%Y-%m-%d %H:%M UTC')}  ",
        f"**Turns:** {len(headers)}",
        "",
        "---",
        "",
    ]

    for i, header in enumerate(headers):
        btype   = header.get("type")
        bid     = header.get("bubbleId")
        ts      = header.get("createdAt", "")

        bubble = fetch_bubble(con, composer_id, bid)
        if not bubble:
            continue

        if btype == USER_TYPE:
            text = bubble_text(bubble)
            if not text:
                continue
            lines += [
                f"## 👤 User",
                f"*{ts}*",
                "",
                text,
                "",
                "---",
                "",
            ]

        elif btype == ASST_TYPE:
            text = bubble_text(bubble)
            tfd  = bubble.get("toolFormerData")

            if text:
                lines += [
                    f"## 🤖 Assistant",
                    f"*{ts}*",
                    "",
                    text,
                    "",
                ]

            if tfd and isinstance(tfd, dict):
                formatted = format_tool_call(bubble)
                if formatted:
                    lines.append(formatted)

            if not text and not tfd:
                continue

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(lines), encoding="utf-8")
    print(f"Exported {len(headers)} turns -> {out_path}")


def main():
    args = sys.argv[1:]

    # Parse --out flag
    out_path = None
    if "--out" in args:
        idx = args.index("--out")
        out_path = Path(args[idx + 1])
        args = args[:idx] + args[idx + 2:]

    con = open_db()

    if not args:
        list_sessions(con)
        return

    query = " ".join(args)
    composer = find_composer(con, query)
    name_slug = re.sub(r"[^a-z0-9]+", "-", (composer.get("name") or "session").lower()).strip("-")
    ts = datetime.now().strftime("%Y%m%d")

    if out_path is None:
        out_path = Path(f"exported/{ts}-{name_slug}.md")

    export_session(composer, con, out_path)
    con.close()


if __name__ == "__main__":
    main()
