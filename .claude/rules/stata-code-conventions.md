---
paths:
  - "scripts/stata/**/*.do"
---

# Stata Code Standards

**Standard:** Senior econometrician + PhD researcher quality. Every `.do` file must be reproducible from a clean Stata session.

---

## 1. Script Header (Required)

Every `.do` file must begin with:

```stata
* ============================================================
* [Descriptive Title]
* Project: Vote Suppression and Voter Turnout
* Author: [from project context]
* Purpose: [What this script does in 1-2 sentences]
* Inputs: [Data files / prior scripts]
* Outputs: [Log file, saved datasets, tables]
* Created: YYYY-MM-DD
* Last modified: YYYY-MM-DD
* ============================================================

clear all
set more off
```

`clear all` and `set more off` are **mandatory** at the top. Omitting them is a Major issue.

---

## 2. Log Files

Open a log at the start; close it at the end:

```stata
* Open log
log using "scriptname.log", replace text

* ... script body ...

log close
```

Always use `replace` so re-runs overwrite the previous log cleanly.

---

## 3. Missing Value Guards

Stata's `.` (and `.a`–`.z`) sort to +∞ — **always guard comparisons**:

```stata
* WRONG — includes missing values in "treated" group
gen treated = (d_idx_2022 > 0.001)

* RIGHT
gen treated = (d_idx_2022 > 0.001) if !missing(d_idx_2022)

* WRONG — missing lean_c observations appear in keep
keep if lean_c > 0

* RIGHT
keep if lean_c > 0 & !missing(lean_c)
```

---

## 4. Variable Generation and Labels

- Use `gen` to create a new variable; use `replace` to modify an existing one.
- Label every new variable immediately after creation:

```stata
gen triple_2024 = treated_s * (year == 2024) * lean_c
label var triple_2024 "treated_s × I(year=2024) × lean_c"
```

- Use `=` for assignment and `==` for comparison — mixing them is a syntax error.

---

## 5. Factor Variables and Regression Syntax

- Use `i.` for categorical variables in regression (never treat year as continuous):

```stata
* WRONG
areg turnout ... year, absorb(county_id)

* RIGHT
areg turnout ... i.year, absorb(county_id)
```

- Use `///` for line continuation in long regression specifications:

```stata
areg turnout did_2012 did_2016 did_2022 did_2024 ///
    triple_2012 triple_2016 triple_2022 triple_2024 ///
    lyr_2012 lyr_2016 lyr_2022 lyr_2024 covid_ctrl i.year, ///
    absorb(county_id) vce(cluster state)
```

---

## 6. Clustering and Inference

- **Cluster SE at the state level** for all DDD/DiD regressions — treatment is state-level.
- Use `vce(cluster state)` with `areg` or `reghdfe`.
- With ≤ 30 treated clusters, also run wild cluster bootstrap (Webb weights, ≥999 reps):

```stata
* Standard SE regression
areg turnout ..., absorb(county_id) vce(cluster state)
estimates store main_spec

* Wild cluster bootstrap (p-value only)
boottest triple_2024, reps(999) seed(42) weight(webb) noci

* Bootstrap CI (requires re-running regression first)
areg turnout ..., absorb(county_id) vce(cluster state)
boottest triple_2024, reps(999) seed(42) weight(webb)
```

Always specify `seed(42)` for reproducibility.

---

## 7. Merge Discipline

Always tabulate `_merge` before asserting or dropping:

```stata
merge 1:1 county_id year using "other_data.dta"
tab _merge          * ALWAYS tab before assert
assert _merge == 3
drop _merge
```

An unexamined merge is a Major issue.

---

## 8. Sample Documentation

Document sample restrictions with inline comments:

```stata
* --- Sample restriction: preferred spec ---
* Keep only R-trifecta states
keep if trifecta_2020 == 1

* Drop OH and MO (late-cohort contamination: restrictions added 2022→2024 only)
drop if inlist(state, "OH", "MO")

* Drop swing counties (excl_A removes counties with <10pp partisan margin)
keep if excl_A == 0
```

---

## 9. Stored Results and Output

- Store estimates with `estimates store name` before running the next regression.
- Display results clearly with `di` or display blocks.
- For bootstrap output, explicitly echo the key statistics to the log:

```stata
di "--- Main DDD results ---"
di "beta_2(2024) = " _b[triple_2024] "  SE = " _se[triple_2024]
di "t = " _b[triple_2024]/_se[triple_2024]
```

---

## 10. Mirror Rule (Project-Specific)

After writing or modifying any `.do` file, mirror it immediately:

```bash
cp "scripts/stata/FILENAME.do" "/Users/anke/pCloud Drive/papers/vote suppression new/do files/FILENAME.do"
```

An un-mirrored script is a Critical issue at commit time.

---

## 11. Section Structure

Divide scripts into numbered sections using comment headers:

```stata
* ---- Step 1: Load data ----------------------------------------
* ---- Step 2: Generate variables --------------------------------
* ---- Step 3: Main regression -----------------------------------
* ---- Step 4: Robustness checks ---------------------------------
* ---- Step 5: Output and display --------------------------------
```

---

## 12. Local Macro Syntax

Locals use `` `name' `` (backtick open, single-quote close). Forgetting the close is the #1 macro bug:

```stata
local controls "covid_ctrl lyr_2012 lyr_2016 lyr_2022 lyr_2024"
areg turnout triple_2024 `controls' i.year, absorb(county_id) vce(cluster state)
* NOT: `controls  (missing close quote)
* NOT: 'controls' (wrong quote characters)
```

---

## 13. Code Quality Checklist

```
[ ] Header block with purpose, inputs, outputs, date
[ ] clear all + set more off at top
[ ] Log opened with replace, closed at end
[ ] Missing value guards on all comparisons
[ ] Variable labels on all new variables
[ ] i.year (not plain year) in regressions
[ ] vce(cluster state) on all DDD/DiD regressions
[ ] _merge tabulated before assert/drop
[ ] Sample restrictions documented with comments
[ ] Mirror copy updated
[ ] No hardcoded absolute paths (use project data folder convention)
[ ] Bootstrap: weight(webb), reps(999), seed(42) specified
```
