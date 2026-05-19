# Claude Code Workflow Setup Summary
**Date:** 2026-05-19

---

## What was done

### 1. Understood the architecture

- **`~/.claude/`** — where Claude Code loads skills, rules, agents, hooks. Device-local, not synced.
- **`/Users/anke/pCloud Drive/claude/shared/`** — source of truth for all skills/rules/agents/hooks. Synced across devices via pCloud. Tracked in GitHub at `askessler/claude-workflow`.
- **Symlinks** connect the two: `~/.claude/skills`, `~/.claude/rules`, `~/.claude/agents`, `~/.claude/hooks` all point directly into the pCloud shared folder. This means edits to the shared folder take effect in Claude Code immediately — no copying needed.

This setup was already in place on the primary device. The bootstrap script (see below) replicates it on new devices.

---

### 2. Files added / changed (all in shared pCloud folder)

| File | What changed |
|------|-------------|
| `.claude/rules/agent-dispatch.md` | **New.** Mandates Task-based dispatch for worker-critic pairs (strategist→critic, coder→critic, etc.). Running them inline is a protocol violation. |
| `.claude/rules/orchestrator-research.md` | Added `scripts/**/*.do` and `paper/figures/**` paths so the simplified orchestrator loop auto-activates for Stata scripts, not just R. Added Stata verification checklist. |
| `.claude/skills/stata-analysis/SKILL.md` | Phase 0: now explicitly loads `anthropic-skills:stata` reference files before writing code. Phase 2: fixed Stata binary (`stata-se` not `stata-mp`) and log path. Phase 3: dispatches `coder-critic` via Task with explicit rubric. Phase 4: removed stale mirror path to archived folder. |
| `.claude/skills/paper-notes/SKILL.md` | Added (statement-centric Obsidian vault workflow). |
| `scripts/bootstrap-claude.sh` | **New.** One-time setup script for new devices (see below). |

---

### 3. Bootstrap script — run once on each new device

```bash
bash "/Users/anke/pCloud Drive/claude/shared/scripts/bootstrap-claude.sh"
```

This creates symlinks from `~/.claude/{skills,rules,agents,hooks}` → pCloud shared folder. Safe to re-run — skips correct symlinks, backs up existing local directories with a timestamp.

After running: restart Claude Code to pick up the changes.

**Verify with:**
```bash
ls -la ~/.claude/ | grep -E "skills|rules|agents|hooks"
```
Each should show `->` pointing to the pCloud shared folder.

---

### 4. GitHub commits

| Hash | Message |
|------|---------|
| `048862c` | Improve agent dispatch, orchestrator coverage, and stata-analysis skill |
| `e5df492` | Add bootstrap script for new device setup |

Remote: `https://github.com/askessler/claude-workflow`

---

## How it works going forward

1. Edit skills/rules in the pCloud shared folder (any device)
2. pCloud syncs changes to all other devices automatically
3. Claude Code on any device reads them via the symlinks in `~/.claude/`
4. Push to GitHub when you want to version/checkpoint

No sync script needed. The symlinks make `~/.claude/` and the pCloud shared folder the same thing.
