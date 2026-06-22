#!/usr/bin/env bash
# ============================================================================
# ci-check.sh — deterministic checks for the agent's own assets.
# Runs locally and in CI (.github/workflows/agent-ci.yml calls this exact file).
#   - ruby -c on all boilerplate parsers/libs + scripts
#   - required canonical files exist (mirrors prompt-smoke.ps1)
#   - profiles/*.toml parse (tomllib)
#   - root field specs are valid JSON
# Exit non-zero on any failure. No gems required (ruby -c is parse-only).
# ============================================================================
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2
fail=0
note() { printf '%s\n' "$*"; }
bad()  { printf 'FAIL: %s\n' "$*"; fail=1; }

note "== ruby -c (parsers, libs, scripts) =="
ruby_files=$(find templates scripts -name '*.rb' 2>/dev/null | sort)
for f in $ruby_files; do
  if ruby -c "$f" >/dev/null 2>err.txt; then :; else bad "ruby syntax: $f"; cat err.txt; fi
done
rm -f err.txt

note "== required canonical files =="
required=(
  "AGENTS.md"
  "CLAUDE.md"
  "docs/shared/agent-rules-gemini.md"
  "docs/shared/KB_HUB.md"
  "docs/shared/datahen-conventions.md"
  "docs/workflows/phases/01-site-discovery.md"
  "profiles/dmart-dloc.toml"
  "profiles/dhero.toml"
  "profiles/greenfield.toml"
  ".agents/skills/scrape/SKILL.md"
  ".agents/skills/qa/SKILL.md"
  ".agents/skills/run-pipeline/SKILL.md"
  ".agents/skills/kb/SKILL.md"
  "scripts/scraper_qa_report.rb"
  ".agents/mcp_config.json"
)
for r in "${required[@]}"; do [ -f "$r" ] || bad "missing file: $r"; done

note "== profiles/*.toml parse =="
if command -v python3 >/dev/null 2>&1; then
  for t in profiles/*.toml; do
    python3 - "$t" <<'PY' || bad "TOML parse: $t"
import sys
try:
    import tomllib
except ModuleNotFoundError:
    import tomli as tomllib  # py<3.11
tomllib.load(open(sys.argv[1], "rb"))
PY
  done
else
  note "  (python3 not found — skipping TOML parse)"
fi

note "== field specs valid JSON =="
for j in field-spec.json dhero-field-spec.json; do
  [ -f "$j" ] || continue
  ruby -rjson -e 'JSON.parse(File.read(ARGV[0]))' "$j" >/dev/null 2>&1 || bad "JSON parse: $j"
done

note "== SKILL.md frontmatter has description =="
for s in .agents/skills/*/SKILL.md; do
  grep -q '^description:' "$s" || bad "missing description: $s"
done

if [ "$fail" -eq 0 ]; then note ""; note "OK: all CI checks passed."; else note ""; note "CI checks FAILED."; fi
exit "$fail"
