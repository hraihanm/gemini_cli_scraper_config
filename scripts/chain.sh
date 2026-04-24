#!/usr/bin/env bash
# Spawn next Gemini CLI phase. Usage:
#   ./scripts/chain.sh navigation-parser mysite dmart-dloc true
set -euo pipefail
PHASE="${1:?phase}"
SCRAPER="${2:?scraper}"
PROJECT="${3:?project}"
AUTO="${4:-true}"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG="$REPO_ROOT/.gemini/auto-chain.log"
LINE="/$PHASE scraper=$SCRAPER project=$PROJECT auto_next=$AUTO"
STAMP="$(date -Iseconds)"

echo "[$STAMP] chain.sh cwd=$REPO_ROOT cmd=$LINE" >>"$LOG"

cd "$REPO_ROOT"
if command -v gemini >/dev/null 2>&1; then
  # Detach so the parent session can finish
  nohup gemini -y -i "$LINE" >>"$LOG" 2>&1 &
  echo "Started: gemini -y -i \"$LINE\" (see $LOG)"
else
  echo "AUTO_CHAIN_FAILED: gemini not in PATH. Run manually:"
  echo "  gemini -y -i \"$LINE\""
  exit 1
fi
