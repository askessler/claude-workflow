---
name: stata-analysis
description: End-to-end Stata analysis pipeline — Pre-Flight → write .do file → verify → review → mirror. Use when user asks to write a new Stata script, run a regression, add a specification, or modify an existing .do file. Produces numbered .do files in `scripts/stata/` and runs them in batch mode via /tmp/stata_run.do wrapper.
argument-hint: "[script name or description of analysis goal]"
allowed-tools: ["Read", "Grep", "Glob", "Write", "Edit", "Bash", "Task"]
---

# Stata Analysis Workflow

Run an end-to-end Stata analysis: write script → verify → review → mirror.

**Input:** `$ARGUMENTS` — a script name (e.g., `12d_iv.do`) or a description of the analysis goal (e.g., "add IV specification using historical lean as instrument for county partisan lean").

---

## Constraints

- **Follow Stata code conventions** in `.claude/rules/stata-code-conventions.md`
- **Follow quality gates** in `.claude/rules/quality-gates.md` (Stata section)
- **Save all scripts** to `scripts/stata/` with the project's numeric naming convention
- **No mirror needed** — authoritative scripts live in `scripts/stata/`; old mirror path (`vote suppression new/`) is archived
- **Run in batch mode** via the `/tmp/stata_run.do` wrapper — never run interactively
- **Check the log** after every run — do not assume success without reading the output

---

## Workflow Phases

### Phase 0: Pre-Flight Report

**Before writing any code**, produce a Pre-Flight Report. This prevents hallucinated variable names and ensures project conventions are applied.

**Load Stata reference files first.** Use the `Skill` tool to invoke `anthropic-skills:stata` and read the 1–3 reference files most relevant to this task (routing table is in the skill). For regressions: always read `references/difference-in-differences.md` or `references/linear-regression.md`. For inference: read `references/bootstrap-simulation.md`. For panel data: read `references/panel-data.md`. Do this before writing any code.

```
Skill({ skill: "anthropic-skills:stata", args: "[relevant topic, e.g. 'difference-in-differences bootstrap']" })
```

Output block (in your response, before Phase 1):

```markdown
## Pre-Flight Report

**Task:** [one sentence restating what the user asked for]

**Stata references loaded:**
- `anthropic-skills:stata` — [which reference files were read]

**Scripts to read / reference:**
- [list any existing scripts that this one builds on]

**Key variables confirmed:**
- [list variables from the existing panel — confirm exact names from prior scripts]

**Conventions loaded:**
- `.claude/rules/stata-code-conventions.md` — [most relevant rule for this task]
- `.claude/rules/quality-gates.md` (Stata section) — [key quality checklist items]

**Plan:** [3–5 bullet outline of the .do file structure]

**Sample spec:** [which states included/excluded, sample filter conditions]
```

If any variable name cannot be confirmed from existing scripts, note it explicitly before proceeding.

### Phase 1: Write the Script

Write the `.do` file following these standards:

1. **Header block** — purpose, inputs, outputs, date (per `stata-code-conventions.md`)
2. `clear all` + `set more off` at top
3. Open log with `replace`
4. Follow project data folder convention: `cd "/Users/anke/pCloud Drive/papers/vote suppression new"`
5. Section headers using `* ---- Step N: ... ----` style
6. Variable labels on all new variables
7. `i.year` in all regressions (never plain `year`)
8. `vce(cluster state)` for all DDD/DiD regressions
9. `tab _merge` before any `assert _merge` or `drop _merge`
10. Missing value guards on all comparisons
11. Close log

### Phase 2: Run and Verify

Run the script in batch mode:

```bash
cat > /tmp/stata_run.do << 'EOF'
do "/Users/anke/pCloud Drive/papers/vote-suppression/scripts/stata/SCRIPT.do"
EOF
cd "/Users/anke/pCloud Drive/papers/vote-suppression" && \
/Applications/Stata/StataSE.app/Contents/MacOS/stata-se -b do /tmp/stata_run.do
cat "/Users/anke/pCloud Drive/papers/vote-suppression/stata_run.log"
```

**Check the log for:**
- `r(N)` where N ≠ 0 (error codes)
- Any `(N observations dropped)` where N is unexpected
- Dropped variables in regressions (collinearity / identification failure)
- Merge `_merge` distribution
- Actual coefficient values and significance

If verification fails: diagnose the error from the log → fix the script → re-run. Max 2 retries before asking the user.

### Phase 3: Review

Dispatch a `coder-critic` subagent via the Task tool to review the script:

```
Task({
  subagent_type: "coder-critic",
  description: "Review Stata script for quality and correctness",
  prompt: "Review the Stata script at [path to .do file]. Read the script in full and the run log at [path to log]. Score against the following rubric (start at 100, deduct per issue found):

  CRITICAL (-20 each): errors in log, dropped variables due to collinearity, wrong cluster level, hardcoded absolute paths
  MAJOR (-10 each): missing variable labels, unexpected sample size, no missing value guards on comparisons, set.seed absent when bootstrap used
  MINOR (-5 each): style issues, unclear comments, non-standard section headers

  Report: score, list of issues by severity, specific line numbers where possible."
})
```

Wait for the critic's score. If score < 80: fix all Critical and Major issues, re-run (Phase 2), re-dispatch critic. Max 2 rounds before surfacing to user.

If score >= 80: proceed to Phase 4.

### Phase 4: Mirror

No mirror required — the authoritative script location is `scripts/stata/` in the project folder. The old mirror path (`vote suppression new/do files/`) is being archived and should not be used.

### Phase 5: Present Results

Summarize in this format:

```markdown
## Results: [Script name]

**Sample:** N obs, K treated states, M control states, J clusters

**Key coefficients:**
| Coefficient | Estimate | SE | p (SE) | p (Boot) | Boot 95% CI |
|-------------|---------|-----|--------|----------|-------------|
| triple_2022 | ...     | ... | ...    | ...      | ...         |
| triple_2024 | ...     | ... | ...    | ...      | ...         |

**Quality score:** [N]/100
**Issues found:** [list any Critical/Major/Minor]
**Mirror:** ✓ Copied to data folder
```

---

## Script Naming Convention

| Range | Category |
|-------|----------|
| `01–10` | Data import and cleaning |
| `11` | Descriptive statistics |
| `12a–12z` | Main analysis (DiD, DDD, event study, robustness) |
| `13+` | Extensions (COVID, IV, heterogeneous effects) |

New scripts continue from the last used number.

---

## Standard Regression Blocks (Project Templates)

### DDD Event Study (preferred spec)

```stata
* Year-specific DiD and triple indicators
gen did_2012 = treated_s * (year == 2012)
gen did_2016 = treated_s * (year == 2016)
gen did_2022 = treated_s * (year == 2022)
gen did_2024 = treated_s * (year == 2024)

gen triple_2012 = treated_s * (year == 2012) * lean_c
gen triple_2016 = treated_s * (year == 2016) * lean_c
gen triple_2022 = treated_s * (year == 2022) * lean_c
gen triple_2024 = treated_s * (year == 2024) * lean_c

* Main DDD regression
areg turnout did_2012 did_2016 did_2022 did_2024 ///
    triple_2012 triple_2016 triple_2022 triple_2024 ///
    lyr_2012 lyr_2016 lyr_2022 lyr_2024 covid_ctrl i.year, ///
    absorb(county_id) vce(cluster state)
```

### Wild Cluster Bootstrap (preferred inference)

```stata
* P-value only (fast)
boottest triple_2024, reps(999) seed(42) weight(webb) noci

* P-value + CI (requires re-running regression immediately before)
areg turnout ..., absorb(county_id) vce(cluster state)
boottest triple_2024, reps(999) seed(42) weight(webb)
```

### Sample Filter (preferred spec)

```stata
keep if trifecta_2020 == 1      // R-trifecta states only
drop if inlist(state, "OH", "MO") // Drop late-cohort states
keep if excl_A == 0              // Drop swing counties
```

---

## Important

- **Read the log every time.** Exit codes and error messages are only in the log.
- **Confirm variable names** from existing scripts before using them — do not assume.
- **Document every sample restriction** with an inline comment explaining why.
- **Never pool** heterogeneous year effects — always report year-by-year coefficients separately.
- **Mirror is not optional.** The data folder is the working copy; the repo is the authoritative copy.
