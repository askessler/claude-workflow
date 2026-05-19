#!/bin/bash
# bootstrap-claude.sh
# Run once on a new device to symlink ~/.claude subdirectories to the pCloud
# shared folder. After this, all skills, rules, agents, and hooks stay in sync
# automatically via pCloud — no further action needed.
#
# Usage:
#   bash "/Users/anke/pCloud Drive/claude/shared/scripts/bootstrap-claude.sh"
#
# Safe to re-run: existing symlinks are left untouched.

set -euo pipefail

SHARED="/Users/anke/pCloud Drive/claude/shared/.claude"
CLAUDE="$HOME/.claude"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "=== Claude Code Bootstrap ==="
echo "Shared source: $SHARED"
echo "Target:        $CLAUDE"
echo ""

# Subdirectories to symlink
DIRS=(skills rules agents hooks)

for dir in "${DIRS[@]}"; do
    target="$CLAUDE/$dir"
    source="$SHARED/$dir"

    # Skip if source doesn't exist
    if [ ! -d "$source" ]; then
        echo "  SKIP  $dir  (source not found: $source)"
        continue
    fi

    # Already a symlink pointing to the right place — nothing to do
    if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
        echo "  OK    $dir  (symlink already correct)"
        continue
    fi

    # Real directory — back it up, then replace with symlink
    if [ -d "$target" ] && [ ! -L "$target" ]; then
        backup="$CLAUDE/${dir}.bak.$TIMESTAMP"
        echo "  BACKUP $dir → ${dir}.bak.$TIMESTAMP"
        mv "$target" "$backup"
    fi

    # Broken or wrong symlink — remove it
    if [ -L "$target" ]; then
        echo "  REMOVE stale symlink: $dir"
        rm "$target"
    fi

    # Create symlink
    ln -s "$source" "$target"
    echo "  LINK  $dir → $source"
done

echo ""
echo "Done. Restart Claude Code to pick up the changes."
echo ""
echo "To verify:"
echo "  ls -la ~/.claude/ | grep -E 'skills|rules|agents|hooks'"
