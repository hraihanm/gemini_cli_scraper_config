#!/usr/bin/env bash
# sync-to-claude.sh
# Syncs .agents/skills/<name>/SKILL.md -> .claude/commands/<name>.md
#
# Claude Code reads .claude/commands/<name>.md as the /<name> slash command prompt.
# Strips YAML frontmatter from each SKILL.md and writes the body to .claude/commands/.
# Re-run after adding or editing any skill.
#
# Usage: bash scripts/sync-to-claude.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/.agents/skills"
COMMANDS_DIR="$REPO_ROOT/.claude/commands"

if [ ! -d "$SKILLS_DIR" ]; then
    echo "ERROR: Skills directory not found: $SKILLS_DIR" >&2
    exit 1
fi

mkdir -p "$COMMANDS_DIR"

count=0
for skill_dir in "$SKILLS_DIR"/*/; do
    name="$(basename "$skill_dir")"
    skill_file="$skill_dir/SKILL.md"
    [ -f "$skill_file" ] || continue

    # Strip YAML frontmatter: skip everything up to and including the second --- line
    awk '/^---$/{n++; if(n==2){found=1; next}} found' "$skill_file" \
        > "$COMMANDS_DIR/$name.md"

    echo "  synced: $name -> .claude/commands/$name.md"
    count=$((count + 1))
done

echo ""
echo "Done. Synced $count skills to .claude/commands/"
echo "Restart Claude Code to pick up new/changed commands."
