# CLAUDE.MD — [YOUR PROJECT NAME]

**Project:** [YOUR PROJECT TITLE]
**Institution:** [YOUR INSTITUTION]
**Field:** [YOUR FIELD — Economics, Finance, Political Science, etc.]
**Branch:** main

---

## Core Principles

- **Plan first** — enter plan mode before non-trivial tasks; save plans to `quality_reports/plans/`
- **Verify after** — compile/run and confirm output at the end of every task
- **Single source of truth** — `paper/main.tex` is authoritative; talks and supplements derive from it
- **Quality gates** — nothing ships below 80/100
- **Worker-critic pairs** — every creator has a paired critic; critics never edit files
- **[LEARN] tags** — corrections and preferences saved automatically via Claude Code memory

Cross-session context in [MEMORY.md](MEMORY.md); plans, specs, and logs in [quality_reports/](quality_reports/).

---

## Getting Started

```bash
# Start fresh on a new project
/new-project [topic]

# Or enter mid-pipeline (e.g., you already have data)
/strategize [research question]
/analyze [dataset or goal]
```

---

## Folder Structure

```
[YOUR-PROJECT]/
├── CLAUDE.md                    # This file
├── MEMORY.md                    # Cross-session learnings
├── .claude/                     # Project-specific rules only (global skills auto-load)
├── Bibliography_base.bib        # Centralized bibliography
├── paper/                       # Main manuscript (single source of truth)
│   ├── main.tex                 # Primary paper file
│   ├── sections/                # Section .tex files
│   ├── figures/                 # Generated figures (.pdf, .png)
│   ├── tables/                  # Generated tables (.tex)
│   ├── talks/                   # Beamer presentations
│   ├── quarto/                  # RevealJS presentations
│   ├── preambles/               # LaTeX headers
│   ├── supplementary/           # Appendix and supplements
│   └── replication/             # Replication package for deposit
├── scripts/                     # Analysis code
│   ├── R/                       # R scripts (if applicable)
│   ├── stata/                   # Stata .do files (if applicable)
│   └── python/                  # Python scripts (if applicable)
├── quality_reports/             # Plans, session logs, reviews, scores
│   ├── plans/
│   ├── session_logs/
│   └── specs/
├── explorations/                # Research sandbox
├── templates/                   # (inherited from global ~/.claude/templates/)
└── master_supporting_docs/      # Reference papers and data docs
```

**Data folder:** [EXTERNAL PATH — e.g., /Users/you/pCloud Drive/projects/your-project/data/]
Data is NOT committed to the repo. Configure the path below.

---

## Data Configuration

```
DATA_FOLDER: [FULL PATH TO EXTERNAL DATA FOLDER]
RAW_DATA:    [DATA_FOLDER]/raw/
CLEAN_DATA:  [DATA_FOLDER]/cleaned/
```

**Mirror rule (if applicable):** [DESCRIBE IF SCRIPTS NEED TO BE MIRRORED ELSEWHERE]

---

## Commands

```bash
# Paper compilation (latexmk handles multi-pass + biber automatically)
cd paper && latexmk main.tex

# Talk compilation
cd paper/talks && latexmk talk.tex

# Stata batch mode (if using Stata)
/Applications/Stata/StataMP.app/Contents/MacOS/stata-mp -b do scripts/stata/SCRIPT.do

# Run via wrapper (Stata, with external data folder):
cat > /tmp/stata_run.do << 'EOF'
cd "[DATA_FOLDER]"
do "[PROJECT_PATH]/scripts/stata/SCRIPT.do"
EOF
/Applications/Stata/StataMP.app/Contents/MacOS/stata-mp -b do /tmp/stata_run.do
```

---

## Quality Thresholds

| Score | Gate | Meaning |
|-------|------|---------|
| 80 | Commit | Good enough to save |
| 90 | PR | Ready for co-author review |
| 95 | Submission | All components ≥ 80 |

---

## Skills Quick Reference

| Command | What It Does |
|---------|-------------|
| `/new-project [topic]` | Full pipeline: idea → paper (orchestrated) |
| `/discover [mode] [topic]` | Literature search, data discovery, ideation, interview |
| `/strategize [mode] [question]` | Identification strategy, pre-analysis plan, theory section |
| `/analyze [dataset]` | End-to-end data analysis (R/Python/Julia) |
| `/stata-analysis [goal]` | End-to-end Stata analysis pipeline |
| `/write [section]` | Draft paper sections |
| `/review [file/--flag]` | Quality reviews: paper, code, peer simulation |
| `/revise [report]` | R&R cycle: classify + route referee comments |
| `/talk [mode] [format]` | Create or compile Beamer/Quarto presentations |
| `/submit [mode]` | Journal targeting → package → final gate |
| `/checkpoint [--flag]` | Session handoff: memory + SESSION_REPORT |
| `/event-study-expert [question]` | DiD/DDD methodology (if applicable) |
| `/commit [msg]` | Stage, quality-check, commit |

---

## Research Context

**Research question:** [YOUR RESEARCH QUESTION]

**Identification strategy:** [DiD / RDD / IV / Structural / Descriptive]

**Key identifying assumption:** [WHAT MUST HOLD]

**Current status:** [PHASE — Discovery / Strategy / Execution / Peer Review / Submission]

---

## Current Project State

| Component | File | Status | Notes |
|-----------|------|--------|-------|
| Paper | `paper/main.tex` | [draft/submitted/R&R] | [Description] |
| Analysis | `scripts/[R or stata]/` | [complete/in-progress] | [Description] |
| Replication | `paper/replication/` | [not started/ready] | [Description] |
| Talk | `paper/talks/` | [not started/in-progress] | [Description] |
