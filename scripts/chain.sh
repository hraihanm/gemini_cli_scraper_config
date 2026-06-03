#!/usr/bin/env bash
# Spawn next Antigravity CLI (agy) phase. Usage:
#   ./scripts/chain.sh navigation-parser mysite dmart-dloc true
set -euo pipefail
PHASE="${1:?phase}"
SCRAPER="${2:?scraper}"
PROJECT="${3:?project}"
AUTO="${4:-true}"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG="$REPO_ROOT/.agents/auto-chain.log"
LINE="/$PHASE scraper=$SCRAPER project=$PROJECT auto_next=$AUTO"
STAMP="$(date -Iseconds)"

echo "[$STAMP] chain.sh cwd=$REPO_ROOT cmd=$LINE" >>"$LOG"

cd "$REPO_ROOT"
if command -v agy >/dev/null 2>&1; then
  # Detach so the parent session can finish
  nohup agy --dangerously-skip-permissions --prompt-interactive "$LINE" >>"$LOG" 2>&1 &
  echo "Started: agy --dangerously-skip-permissions --prompt-interactive \"$LINE\" (see $LOG)"
else
  echo "AUTO_CHAIN_FAILED: agy not in PATH. Run manually:"
  echo "  agy --dangerously-skip-permissions --prompt-interactive \"$LINE\""
  exit 1
fi
