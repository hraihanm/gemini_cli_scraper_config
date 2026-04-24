#!/usr/bin/env bash
# Quick sanity check: required agent files exist.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
missing=0
for rel in \
  .gemini/system.md \
  docs/shared/agent-rules-gemini.md \
  docs/shared/datahen-conventions.md \
  docs/workflows/phases/01-site-discovery.md \
  profiles/dmart-dloc.toml \
  .gemini/commands/scrape.toml \
  scripts/chain.sh; do
  if [[ ! -f "$ROOT/$rel" ]]; then echo "FAIL: missing $rel"; missing=1; fi
done
if [[ "$missing" -ne 0 ]]; then exit 1; fi
echo "OK: all required paths present under $ROOT"
# cd "$ROOT" && gemini -y -i '/scrape url=https://example.com name=smoke_test project=dmart-dloc auto_next=false'
