---
name: event-study-expert
description: |
  Unified DiD and event study methodology advisor synthesizing five foundational papers.
  Covers TWFE failure modes, heterogeneity-robust estimators, specification choices,
  pre-trend testing pitfalls, inference with few clusters, and continuous-treatment extensions.
type: skill
tags: [methodology, causal-inference, event-study, DiD, DDD, TWFE, econometrics]
sources: |
  Miller, D.L. (2023). "An Introductory Guide to Event Study Models." JEP 37(2): 203–230.
  Callaway, B., Goodman-Bacon, A., & Sant'Anna, P.H.C. (2024). "Event Studies with a
    Continuous Treatment." AEA P&P 114: 601–605.
  Roth, J., Sant'Anna, P.H.C., Bilinski, A., & Poe, J. (2023). "What's Trending in
    Difference-in-Differences?" J. Econometrics 235: 2218–2244.
  Roth, J. (2022). "Pretest with Caution." AER: Insights 4(3): 305–322.
  de Chaisemartin, C. & D'Haultfœuille, X. (2023). "Two-Way Fixed Effects and
    Differences-in-Differences with Heterogeneous Treatment Effects: A Survey."
    Econometrics Journal 26: C1–C30.
---

# Event Study Expert

Use this skill to design, audit, or troubleshoot **DiD and event study specifications** — including simple 2×2 DiD, staggered adoption, triple-difference (DDD), and continuous-treatment designs.

DiD is the restricted special case of an event study (pre-period coefficients constrained to zero, post-period coefficients constrained to be equal). Both share the same identifying assumptions, FE structure, and inference challenges. This skill covers both as one unified framework.

---

## Part 1: Data Structures — Know Your Design

From Miller (2023), four data structures determine what methods are valid:

| Structure | Never-treated units? | Common event date? | Identifying variation |
|-----------|---------------------|--------------------|-----------------------|
| **DiD-type** | Yes | Yes (all treated at same time) | Treated vs. never-treated |
| **Timing-based** | No | No (staggered across units) | Earlier vs. later treated |
| **Hybrid** | Yes | No (staggered) | Both sources combined |
| **Continuous treatment** | Yes (D=0) or never-treated | Varies | Dose variation × timing |

**Key rule:** You need at least one of (a) never-treated units or (b) variation in event timing. Without either, treatment effects cannot be separated from calendar-time confounders.

**Vote suppression project:** Hybrid structure — 8 treated states, 15 never-treated R-trifecta states (after dropping OH/MO), staggered timing within treated cohort (2020→2022 index change).

---

## Part 2: TWFE — When It Works and When It Fails

### The Basic TWFE Specification

```stata
* Static TWFE
areg y treated_post i.year, absorb(unit_id) vce(cluster state)

* Dynamic TWFE (event study)
areg y ib(-1).rel_time i.year, absorb(unit_id) vce(cluster state)
```

### TWFE is valid IF AND ONLY IF:
1. **Treatment turns on once and stays on** (absorbing state, binary)
2. **All treated units share the same event date** (no staggered timing)
3. **Treatment effects are homogeneous** across units and time

If any of these fail, TWFE may estimate a **non-convex weighted average of treatment effects with some negative weights** — a finding that may be zero, wrong-signed, or uninterpretable even when all true effects are positive.

### The Negative-Weights Problem (de Chaisemartin & D'Haultfœuille 2020)

Under parallel trends, the static TWFE coefficient estimates:
$$\hat{\beta}^{fe} = \sum_{(g,t): D_{g,t}=1} W_{g,t} \cdot TE_{g,t}$$

where weights $W_{g,t}$ are proportional to:
$$D_{g,t} - D_{g,.} - D_{.,t} + D_{.,.}$$

**Negative weights arise when:**
- A group is treated for most of the sample period (high $D_{g,.}$)
- A time period has high average treatment (high $D_{.,t}$)
- In staggered designs: early-treated units appear as "controls" for late-treated units in later periods

**Consequence:** $\hat{\beta}^{fe}$ can be *positive* when every true effect is *negative*, or vice versa. This is the **no-sign-reversal failure**.

**Diagnostic:** Run `twowayfeweights` (Stata/R) to check fraction of negative weights and their sum. If negative weights are substantial, TWFE estimates are unreliable.

### The Forbidden Comparisons Problem (Goodman-Bacon 2021)

In staggered DiD, the static TWFE coefficient decomposes as:
$$\hat{\beta}^{fe} = \sum_{g \neq g', t < t'} v_{g,g',t,t'} \cdot DID_{g,g',t,t'}$$

This includes DiDs where an **already-treated unit** serves as the control group for a later-treated unit — the "forbidden comparison." Early-adopters who received large treatment effects get *negative weights* when used as controls in later periods.

**Simple example (Borusyak & Jaravel):** Early group $e$ treated at $t=2$; late group $\ell$ treated at $t=3$.
$$\hat{\beta}^{fe} = \frac{1}{2}\bigl[DID_{e,\ell,1,2} + DID_{\ell,e,2,3}\bigr]$$

$DID_{\ell,e,2,3}$ uses $e$ (already treated at period 2) as the control for $\ell$ (newly treated at period 3). This is a forbidden comparison: the "control" is itself treated.

**Diagnostic:** Run `bacondecomp` (Stata/R) to visualize how much weight falls on forbidden comparisons.

### Dynamic TWFE: Also Problematic under Cohort Heterogeneity

The dynamic specification:
$$Y_{it} = \alpha_i + \phi_t + \sum_{r \neq 0} \mathbf{1}[R_{it} = r]\beta_r + \epsilon_{it}$$

works when all cohorts have the same expected effect $\tau_s$ in period $s$ since treatment. When cohort effects are heterogeneous (Sun & Abraham 2021), $\beta_r$ gets contaminated by cross-lag "pollution" — $\beta_2$ may reflect treatment effects at lag 3 for some units. **Critically: pre-treatment leads are not guaranteed to be zero even when parallel trends holds**, making pre-trend tests based on dynamic TWFE leads unreliable.

---

## Part 3: Heterogeneity-Robust Estimators

When TWFE fails, use one of these. Choose based on your design:

| Situation | Recommended Estimator | Stata Package |
|-----------|----------------------|---------------|
| Staggered binary treatment, never-treated comparison | **Callaway & Sant'Anna (2021)** | `csdid` |
| Staggered binary, no never-treated, imputation approach | **Borusyak, Jaravel & Spiess (2021)** | `did_imputation` |
| Staggered binary, interaction-weighted | **Sun & Abraham (2021)** | `eventstudyinteract` |
| Treatment can turn on AND off | **de Chaisemartin & D'Haultfœuille (2020)** | `did_multiplegt` |
| Continuous treatment + staggered timing | **Callaway, Goodman-Bacon & Sant'Anna (2024)** | `csdid` (adapted) |
| Diagnostics for TWFE weighting issues | `twowayfeweights`, `bacondecomp` | Both in Stata/R |

### Callaway & Sant'Anna (2021) — The Building-Block Approach

**Building block:** ATT(g,t) = average treatment effect at time $t$ for the cohort first treated at time $g$:
$$ATT(g,t) = E[Y_t(g) - Y_t(\infty) | G = g]$$

**Identification:** Under parallel trends and no-anticipation, for any "clean" comparison group $G^{comp}$ with $g' > t$:
$$ATT(g,t) = E[Y_t - Y_{g-1} | G=g] - E[Y_t - Y_{g-1} | G \in G^{comp}]$$

**Aggregation options:**
- `simple`: weighted average across all $(g,t)$ pairs
- `dynamic`: weighted by event time (like an event study plot)
- `group`: weighted average within each cohort $g$
- `calendar`: weighted average within each calendar period $t$

```stata
* Callaway & Sant'Anna in Stata
csdid outcome covars, ivar(unit_id) time(year) gvar(first_treat_year) ///
    notyet  /* or: never */
csdid_plot  /* event study plot */
```

**Comparison group:** `notyet` uses not-yet-treated units (Assumption 4a — weaker); `never` uses only never-treated (Assumption 4 — stronger but may use never-treated as controls which could differ systematically).

---

## Part 4: Specification Choices (Miller 2023)

### 4.1 Reference Period

**Rule:** Normalize one pre-treatment period to zero. This defines the counterfactual baseline.

- **Default:** Period immediately before treatment ($t = -1$), implemented by excluding that dummy. Advantages: closest to treatment, minimal extrapolation.
- **Alternative:** Normalize over a window of pre-periods by constraining them to average zero. Effect: smaller SEs (less noise from a single period), but pre-trends look visually different (must assess trend, not level).
- **Avoid:** Averaging multiple pre-periods without good reason — adds collinearity, makes individual pre-period coefficients uninterpretable.
- **When to deviate:** If there is an "Ashenfelter's dip" (mechanical drop just before treatment), use a period prior to the dip as baseline (Jacobson et al. 1993 used "5+ years before" for this reason).

**Vote suppression:** Normalize to 2020 (one period before 2022 treatment). This gives the cleanest DiD baseline.

### 4.2 Event Window (How Far Before/After?)

**Competing considerations:**
- **Wide window:** More pre-period data → stronger parallel-trends test; long post-period → see dynamics
- **Narrow window:** Coefficients estimated off balanced samples; avoids power loss from sparse far-out periods

**Miller's recommendation:** Show the full available window; collapse or drop most-distant periods only if power is severely compromised. Always report how many units identify each event-time coefficient.

**Critical for balance:** Prefer event windows where all event-time coefficients are identified by roughly the same units. If the $e = +4$ coefficient is identified by only 2 of 8 treated states, note this explicitly.

### 4.3 Endpoint/End-Cap Treatment

When observations exist outside your main event window ($j \leq -m$ or $j \geq n$), you must decide:

1. **Separate dummy for each endpoint** — cleanest; shows the full picture including potentially noisy tails
2. **End-cap dummy** (binning): $D_{i,t \leq E_i - m}$ pools all pre-event observations beyond the window. Recommended by Schmidheiny & Siegloch (2023). **Risk:** Masks trends if treatment effects or counterfactual trends are themselves trending at the endpoints.
3. **Drop out-of-window observations** — simplest; creates imbalance in calendar time if event dates vary
4. **Include in reference group** — only acceptable for pre-event; never pool pre- AND post-event far periods into the same reference group

**Rule:** Be explicit about your choice and plot endpoint coefficients with a distinct symbol to alert readers they are differently computed.

### 4.4 Pooling Event Times for Statistical Power

With many event-time bins, SEs are large. Options to regain power:
- **Pool adjacent periods:** Constrain $\gamma_{j} = \gamma_{j+1}$ for selected pairs. Report unpooled as robustness.
- **Spline restriction:** Force coefficients to lie on a piecewise-linear function (Bailey et al. 2020; Lafortune et al. 2018). Allow a jump at $t=0$. Show unconstrained as robustness.

**Avoid:** Pooling pre- and post-event periods into a single coefficient (the classic DiD restriction). Report if you do this and test sensitivity.

### 4.5 Control Unit Selection and Re-weighting

**Threats to the control group:**
- Never-treated units may be systematically different (observables and unobservables)
- Future-treated units used as controls before their own treatment → contamination if treatment effects accumulate
- Size/composition imbalance between treated and control units

**Solutions:**
1. **Exclude problematic controls** (e.g., OH/MO in vote suppression — dropped entirely)
2. **Pre-treatment parallel-trends check** as a selection test
3. **Propensity-score re-weighting** on observables before estimation (Goodman-Bacon & Cunningham 2019)
4. **Matching** on pre-treatment outcomes and covariates
5. **Callaway-Sant'Anna "not-yet-treated"** as comparison — avoids never-treated contamination

**Vote suppression:** Dropped OH/MO because: (a) they are future-treated → cannot be controls; (b) Callaway-Sant'Anna pre-trend test fails (F=7.85, p=0.0009) → cannot be reclassified as treated in main cohort.

---

## Part 5: Pre-Trend Testing — Do It Right (Roth 2022)

**The standard practice:** Test pre-period coefficients for individual or joint significance. If none significant → parallel trends holds → proceed.

**This practice has two serious problems.**

### Problem 1: Low Power

Roth (2022) calibrates pre-trend tests to 12 published papers and finds:

- A linear violation of parallel trends that would be detected **only 50% of the time** can produce biases **comparable to or larger than the estimated treatment effect**
- CI coverage can fall from nominal 95% to as low as **24%** under such violations
- In the most extreme case: the bias from a trend detected half the time equals the treatment effect estimate; the CI barely covers the true parameter

**Why?** Pre-trend tests have limited degrees of freedom (few pre-periods), often small samples or few clusters, and test a joint hypothesis with low power against smooth violations.

### Problem 2: Pretest Bias (Conditioning on Passing)

When you condition your analysis on "the pretest passed," you draw from a **selected subsample of the data-generating process**. In this selected subsample:
- The bias from differential trends can be **larger than the unconditional bias**
- Under homoskedasticity and monotonically increasing violation: conditional bias is **always larger**
- Conditional coverage of 95% CIs can fall below unconditional coverage

**Intuition:** The draws of the data that happen to show flat pre-trends are not a random sample. Among DGPs where trends exist, the ones that "pass" the pretest are those where the trend happens to be masked by noise — and that same noise often inflates the post-treatment estimate.

### What to Do Instead

**Do NOT:**
- Treat a non-significant pre-trend as proof of parallel trends
- Use pre-test result as a binary screen (pass/fail)
- Report only individual t-tests on pre-period coefficients

**DO:**
1. **Report power of your pretest.** For your pre-period setup (K pre-periods, your SE structure), what slope of differential trend would be detected 50% / 80% of the time? Use `pretrends` (R package, Roth 2022) or compute analytically.
2. **Report joint significance test** of all pre-period coefficients (not just individual), plus a test of linear trend through pre-periods.
3. **Show the event-study plot with full pre-period window** — visual inspection adds context but is not sufficient alone.
4. **Conduct sensitivity analysis** (Rambachan & Roth 2022 via `honestDiD`) — bound treatment effects under violations of parallel trends no larger than the pre-trend you observe.
5. **Economic reasoning.** Argue why parallel trends should hold based on institutional knowledge, not just data.

### Practical Guidance for Pre-Period Coefficients

From Miller (2023):
- Pre-event coefficients should bounce around zero without a systematic trend
- A **systematic pattern** (monotone increase/decrease) across all pre-periods → suspect violation
- **Noisy bouncing** (±0.01–0.02, no trend) → consistent with parallel trends
- Do NOT mechanically round insignificant pre-trends to zero — report them

**Vote suppression DDD pre-trends:** 2012, 2016, 2020 triple interactions all near zero, no trend. Passes visual and statistical check. But with 8 treated states, power is limited — acknowledge this.

---

## Part 6: Inference with Few Clusters

**Critical when:** Treatment is assigned at a higher level than observation (state-level policy, county-level outcomes), AND you have fewer than 30–40 clusters, AND especially fewer than 10–15 *treated* clusters.

### The Problem

Standard cluster-robust SEs (Liang-Zeger) require many clusters in both treated AND control groups to be valid. With 8 treated states, t-statistics are inflated and nominal p-values are too small.

### Solutions (from Roth et al. 2023 and Miller 2023)

**1. Wild Cluster Bootstrap** (MacKinnon & Webb; Cameron, Gelbach & Miller)
- Resample at the cluster level (state), preserving within-cluster structure
- Compute bootstrap t-statistics; use empirical distribution for p-values
- More robust than analytical SE correction with few treated clusters
- Stata: `boottest` package (Roodman et al.)

**2. Imbens & Kolesar (2016) Small-Sample Correction**
- Adjusts degrees of freedom based on effective number of treated clusters
- Conservative but transparent
- For 8 treated, 15 control: correction factor ≈ 1.5–2.0×
- Stata: `ivreg2` with `small` option, or `reghdfe` with `dkraay` SE

**3. Randomization Inference (Fisher Exact)**
- Valid under the sharp null (treatment effect = 0 for all units)
- No distributional assumptions; exact in finite samples
- Permute treatment assignment across states; compute test statistic empirically
- Computationally feasible with 23 states (8 treated + 15 control)

**4. Design-Based Inference** (Athey & Imbens 2022; Roth et al. 2023)
- Treats randomness as coming from treatment assignment, not sampling
- Justifies clustering at level of independent treatment assignment (state, if policy is state-level)
- Often yields same recommendation as sampling-based approach

### Recommendation for Vote Suppression (8 treated, 15 control states)

```
Primary: cluster-robust SE at state level (as currently done)
Robustness: wild cluster bootstrap p-values (boottest)
Report: t-statistics with note on few-cluster risk; wild bootstrap 95% CI
```

**Example:**
```
Main result: β = −0.102, SE = 0.037, t = −2.76, p = 0.012 (clustered SE)
Wild bootstrap 95% CI: [−0.19, −0.01], p = 0.038
Interpretation: result is robust to small-cluster correction
```

---

## Part 7: Continuous Treatment (Callaway, Goodman-Bacon & Sant'Anna 2024)

When treatment is continuous — units receive different *doses* $D_i \in [0, d_H]$ in addition to varying treatment timing $G_i$ — the building blocks are:

**ATT(g,t,d):** Average treatment effect at time $t$ for the cohort first treated in period $g$ with dose $d$, vs. zero dose.

**ACR(g,t,d):** Average causal response — the marginal effect of a unit increase in dose at $d$, for cohort $g$ at time $t$.

Both are far too numerous to report. Researchers must **choose an aggregation strategy** based on the research question.

### Three Aggregation Strategies

**Strategy 1: Event-Study Parameters (ignore dose, aggregate across timing)**

$$ATT^{es}(e) = E[ATT^o(G, G+e) | G+e \in [2,T], D>0]$$

- Pools all dose levels; shows effect $e$ periods after treatment
- **Estimation:** Treat all $D>0$ as "ever-treated" (binary), $D=0$ as "never-treated." Apply standard Callaway-Sant'Anna (2021) binary event study estimators.
- **Use when:** You want the overall average effect, ignoring dose heterogeneity.

**Strategy 2: Dose-Aware Event-Study Parameters (separate by dose bins)**

$$ATT^{es}_{d_1,d_2}(e) = E[ATT^o_{d_1,d_2}(G, G+e) | d_1 \leq D \leq d_2, G+e \in [2,T]]$$

- Shows how treatment effect dynamics differ across dose levels
- **Estimation:** Subset to units with dose in $[d_1, d_2]$ OR $D=0$. Run binary event study on this subset. Repeat for each bin.
- **Use when:** You want to show high-dose vs. low-dose states have different timing/magnitude.

```stata
* Example: vote suppression — low vs. high restriction states
* Low-restriction bin
keep if (d_idx_2022 < 0.005 & treated_s==1) | treated_s==0
csdid turnout, ivar(county_id) time(year) gvar(first_treat_year)

* High-restriction bin  
keep if (d_idx_2022 >= 0.005 & treated_s==1) | treated_s==0
csdid turnout, ivar(county_id) time(year) gvar(first_treat_year)
```

**Strategy 3: Dose-Response Curves (aggregate over event time, vary dose)**

$$ATT^{es}_{e_1,e_2}(d) = \frac{\sum_{e=e_1}^{e_2} E[ATT(G, G+e, d) | G+e_2 \in [2,T], D=d]}{e_2 - e_1 + 1}$$

- Shows effect size as a function of dose, averaged over a time window
- **Estimation:** Use Callaway-Goodman-Bacon-Sant'Anna (2024) dose-response estimator; for limited N, use flexible parametric form (cubic splines with knots at 25th, 50th, 75th percentile of dose distribution).
- **Use when:** You want to show how much restriction magnitude matters; short-run vs. long-run dose-response.

```
Short-run dose-response (e1=0, e2=2 event times):
  x-axis: d_idx_2022 (restriction increase)
  y-axis: ATT at that dose level
  Show fitted cubic spline

Long-run dose-response (e1=3, e2=4 event times):
  Same x-axis; separate spline
```

### Identification (Theorem 1, Callaway et al. 2024)

Under parallel trends across timing-dose groups:
$$E[\Delta Y_t(0) | G=g, D=d] = E[\Delta Y_t(0) | G=g', D=d']$$

all three aggregation strategies are non-parametrically identified. Estimation follows standard binary DiD tools applied to appropriately subsetted data.

### Application to Vote Suppression

The project's finding (β(2022) ≈ −0.031, β(2024) ≈ −0.102) is the event-study parameter ATT^es(e) averaged over doses. The large difference between 2022 and 2024 effects suggests either:
- **Cumulative suppression:** Restrictions bite harder after a full electoral cycle of implementation
- **Dose heterogeneity:** High-restriction states (large d_idx_2022) drive the 2024 result; low-restriction states show earlier effects

**Strategy 2 (dose-aware)** would distinguish these. Compare above/below median $d_{idx,2022}$ event study plots.

---

## Part 8: Triple-Difference (DDD) Specifications

The DDD design adds a within-unit "nested" dimension (e.g., county partisan lean) to the standard DiD (treated state × year). This isolates the treatment effect specifically in the sub-group where it should operate — a third difference that controls for any time-invariant difference across the nested dimension.

### Estimating Equation

```stata
* DDD event study (preferred form)
gen triple_2022 = treated_s * lean_c * (year==2022)
gen triple_2024 = treated_s * lean_c * (year==2024)
gen lyr_2012 = lean_c * (year==2012)   /* lean × year FEs (all years) */
gen lyr_2016 = lean_c * (year==2016)
gen lyr_2022 = lean_c * (year==2022)
gen lyr_2024 = lean_c * (year==2024)
gen did_2022 = treated_s * (year==2022) /* main DiD effects by year */
gen did_2024 = treated_s * (year==2024)

areg turnout did_2022 did_2024 triple_2022 triple_2024 ///
    lyr_2012 lyr_2016 lyr_2022 lyr_2024 ///
    covid_ctrl i.year, absorb(county_id) vce(cluster state)
```

**Key collinearity rule:** Do NOT add state fixed effects when treatment is state-specific. `treated_s` is state-level; adding state FE would absorb it entirely.

**Why year-specific DiD terms (did_2022, did_2024) instead of pooled:**
A single `did = treated_s × post` creates partial collinearity with the year-specific triple interactions, because both `triple_2022` and `triple_2024` are nonzero in treated post-treatment years. Use separate `did_2022` and `did_2024` to eliminate this collinearity and allow pre-trend checking.

### Interpreting DDD Results

- **β₁(year):** Main DiD effect — average turnout change in treated vs. control states, averaged over lean (the "level" effect)
- **β₂(year) [triple interaction]:** Differential effect by lean — how much does the effect differ for D-leaning vs. R-leaning counties within treated states?
- **Identification:** β₂ is identified even if β₁ is not, because the lean interaction controls for within-state compositional differences

**Vote suppression interpretation:** β₂(2024) = −0.102 means: in treated states, a county at 70% Dem lean (vs. 30% Dem lean) saw ~4pp lower turnout in 2024 relative to 2020, over and above the same comparison in control states.

**Why DiD shows 2022 but DDD shows 2024:** The DiD averages over lean — R-leaning counties (where restrictions don't affect D-turnout) dilute the 2024 signal. The triple interaction isolates exactly the counties where restrictions bite.

---

## Part 9: Stata Packages Reference

| Package | Method | Install |
|---------|--------|---------|
| `csdid` | Callaway & Sant'Anna (2021) | `ssc install csdid` |
| `did_imputation` | Borusyak, Jaravel & Spiess (2021) | `ssc install did_imputation` |
| `eventstudyinteract` | Sun & Abraham (2021) | `net install eventstudyinteract` |
| `did_multiplegt` | de Chaisemartin & D'Haultfœuille (2020) | `ssc install did_multiplegt` |
| `bacondecomp` | Goodman-Bacon (2021) decomposition | `ssc install bacondecomp` |
| `twowayfeweights` | de Chaisemartin negative-weights diagnostic | `ssc install twowayfeweights` |
| `boottest` | Wild cluster bootstrap inference | `ssc install boottest` |
| `honestDiD` | Rambachan & Roth sensitivity analysis | R only (`remotes::install_github`) |
| `coefplot` | Event study coefficient plots | `ssc install coefplot` |
| `reghdfe` | High-dimensional FE OLS with clustering | `ssc install reghdfe` |

---

## Part 10: Diagnostic Checklists

### Before Running Your Regression

- [ ] **Data structure identified:** DiD-type / timing-based / hybrid / continuous? Documented?
- [ ] **TWFE appropriate?** If staggered timing + heterogeneous effects likely → use robust estimator (Part 3)
- [ ] **Reference period chosen:** Explicitly stated (immediate pre-period, or averaged?). Rationale given?
- [ ] **Event window chosen:** Covers all available pre- and post-periods, or justified truncation?
- [ ] **Endpoint treatment:** End-cap or separate dummy? Choice stated?
- [ ] **Control group defined:** Contaminated future-treated units dropped or handled?
- [ ] **Fixed effects:** Treatment term not subsumed by FE; no surprise dropped variables
- [ ] **Collinearity checked:** No pooled post term when using year-specific triples (DDD)

### Pre-Trend Testing Protocol

1. Estimate all pre-period event-time coefficients (don't pool them)
2. Report individual coefficients + SEs
3. Report joint significance test (chi-squared, all pre-periods)
4. Report t-statistic for linear trend through pre-periods
5. **Assess power:** What slope of differential trend would your pretest detect with 50% / 80% probability?
6. If power is low (as it often is with few clusters), do NOT claim the test "confirms" parallel trends — say it "is consistent with" parallel trends
7. Add economic reasoning: why should treated and control units have evolved in parallel absent treatment?

### After Running

- [ ] **Check for dropped variables:** Did Stata drop any collinear terms? Were they expected?
- [ ] **Heterogeneous effects:** If year-by-year effects differ substantially, report them separately — do NOT pool
- [ ] **Cluster-robust inference:** SEs clustered at treatment-assignment level (state). Few-cluster adjustment if < 30 treated clusters
- [ ] **TWFE diagnostic (if staggered):** Run `bacondecomp` or `twowayfeweights` to check negative weight exposure
- [ ] **Robustness:** Vary FE structure, reference period, event window, control group definition

### Presenting Results

1. **Event-study plot:** All pre- and post-treatment coefficients with 95% CI. Reference period clearly marked ($t=0$ or $t=-1$). Endpoint coefficients plotted with distinct symbol.
2. **Full regression table:** LHS, RHS, FE structure, clustering, N, SE type all stated
3. **Pre-trends assessment:** Results of joint test and power discussion in text or appendix
4. **Heterogeneous effects:** If β(2022) ≠ β(2024) substantially, show year-by-year table — do NOT report only pooled
5. **Robustness table:** Alternate control groups, FE structures, reference periods, continuous treatment version

---

## Part 11: Common Pitfalls Quick Reference

| Pitfall | Symptom | Fix |
|---------|---------|-----|
| Static TWFE with staggered adoption | Coefficient near zero or wrong sign despite positive effects | Use Callaway-Sant'Anna or other robust estimator |
| Forbidden comparisons | Goodman-Bacon decomposition shows large weight on "already-treated" controls | Use not-yet-treated or never-treated comparison only |
| Pooling heterogeneous effects | Effect disappears when years pooled, appears when separated | Report year-by-year; do NOT pool; explain dynamics |
| Collinear pooled DiD + year-specific triples | Stata drops variables; coefficients unidentified | Replace pooled `did` with separate `did_2022`, `did_2024` |
| Non-significant pretest ≠ parallel trends | Low power means bias of meaningful size may be undetected | Report power; use sensitivity analysis; rely on economic reasoning |
| Pretest bias | Published estimates higher after passing pretest, inflated t-stats | Report unconditional inference; consider sensitivity analysis |
| Few clusters, standard SEs | p < 0.05 with 8 treated states using naive clustered SE | Apply wild bootstrap (`boottest`); report both |
| State FE with state-level treatment | Treatment term absorbed; coefficient = 0 or dropped | Remove state FE; treatment is already state-specific |
| Missing end-cap explanation | Readers can't assess whether tails are reliable | State endpoint handling explicitly; use distinct plot symbols |
| Averaging reference period without reason | SEs smaller but pre-trend pattern uninterpretable | Use immediate pre-period as default; document any deviation |

---

## When to Consult This Skill

- **Design phase:** Choosing treatment definition, control group, event window, FE structure, estimator
- **TWFE check:** Does staggered timing + likely heterogeneity → should I use robust estimator?
- **Pre-trend diagnostics:** How to interpret pre-period coefficients; power assessment
- **Inference:** Few treated clusters; which SE correction to use
- **Continuous treatment:** How to aggregate ATT(g,t,d) building blocks
- **Write-up:** What to report, how to explain choices to referees, what robustness checks to run

---

## Source Papers (on file in `supporting_papers/`)

| Paper | Key contribution |
|-------|----------------|
| Miller (2023) JEP | Data structures, specification choices, reference period, event window, endpoints |
| Callaway, Goodman-Bacon & Sant'Anna (2024) AEA P&P | Continuous treatment, three aggregation strategies, Theorem 1 |
| Roth, Sant'Anna, Bilinski & Poe (2023) J.Econometrics | TWFE failure modes, robust estimators, sensitivity analysis, checklist |
| Roth (2022) AER: Insights | Pre-trend testing: low power + pretest bias; practical recommendations |
| de Chaisemartin & D'Haultfœuille (2023) Econometrics J. | Negative weights formula, forbidden comparisons, did_multiplegt, survey of estimators |
