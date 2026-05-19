
<!-- README.md is generated from README.Rmd. Please edit README.Rmd instead. -->

# survAHadjust

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.20277581.svg)](https://doi.org/10.5281/zenodo.20277581)

`survAHadjust` calculates average hazard-based summaries from adjusted
survival curves.

The main workflow is:

``` text
adjusted survival curves
  -> adjusted_ahsw()
  -> ahsw_table()
```

For most adjusted survival curve methods, users can first use
`adjustedCurves::adjustedsurv()`.

For AIPTW, `survAHadjust` provides `aiptw_adjustedsurv()`.

Both workflows produce an adjusted survival curve object that can be
passed to `adjusted_ahsw()`.

## Installation

Install the GitHub version with:

``` r
install.packages("pak")
pak::pak("kkevin821/survAHadjust")
```

For local development, after cloning the repository and opening the
package folder in RStudio, install the package locally with:

``` r
devtools::install()
```

## Basic example

`adjusted_ahsw()` requires an adjusted survival curve object with:

``` text
adjsurv$adj$time
adjsurv$adj$surv
adjsurv$adj$group
```

``` r
library(survAHadjust)

adjsurv <- list(
  adj = data.frame(
    time = c(0, 0.5, 1.0, 0, 0.5, 1.0),
    group = factor(c(0, 0, 0, 1, 1, 1)),
    surv = c(1.0, 0.80, 0.70, 1.0, 0.90, 0.85)
  )
)

res <- adjusted_ahsw(adjsurv, to = 1, conf_int = FALSE)

res$est
#>               group0    group1 difference     log_dif
#> rmst       0.9000000 0.9500000  0.0500000  0.05406722
#> event_rate 0.3000000 0.1500000 -0.1500000 -0.69314718
#> ahsw       0.3333333 0.1578947 -0.1754386 -0.74721440
```

The result can be formatted as a one-row table:

``` r
ahsw_table(res, method = "Example")
#>    Method Group 0 Group 1 Difference Ratio
#> 1 Example   0.333   0.158     -0.175 0.474
```

## Standard adjusted survival curve methods

For standard adjusted survival curve methods, use
`adjustedCurves::adjustedsurv()` first.

For example:

``` r
outcome_model <- survival::coxph(
  survival::Surv(time, event) ~ group + x1 + x2 + x3,
  data = dat,
  x = TRUE
)

adjsurv <- adjustedCurves::adjustedsurv(
  data = dat,
  variable = "group",
  ev_time = "time",
  event = "event",
  method = "direct",
  outcome_model = outcome_model,
  bootstrap = TRUE,
  n_boot = 300
)

res <- adjusted_ahsw(
  adjsurv = adjsurv,
  to = 0.7,
  conf_int = TRUE
)

ahsw_table(res, method = "Direct standardization")
```

Other methods from `adjustedCurves::adjustedsurv()` can be used in the
same way.

## AIPTW

AIPTW is a standard doubly robust approach for estimating adjusted
survival curves. In `survAHadjust`, the function `aiptw_adjustedsurv()`
implements the AIPTW estimator used in our simulation study and
application. The implementation follows the AIPTW/IPCW setup described
by Ozenne et al. (2020). Under independent censoring, the censoring
distribution is estimated using a pooled Kaplan-Meier estimator; when
`covars_cens` is supplied, a Cox model is used for the censoring
distribution.

For non-AIPTW adjusted survival curve methods, users can use
`adjustedCurves::adjustedsurv()` and then pass the resulting object to
`adjusted_ahsw()`.

If users prefer another implementation of AIPTW that returns an adjusted
survival curve object with `adj`, `time`, `surv`, and `group`, that
object can also be passed to `adjusted_ahsw()`.

``` r
adjsurv_aiptw <- aiptw_adjustedsurv(
  data = dat,
  covars_treat = c("x2", "x3", "x5", "x6"),
  covars_outcome = c("x1", "x2", "x4", "x5_squared"),
  covars_cens = NULL,
  y_col = "time",
  delta_col = "event",
  z_col = "group",
  bootstrap = TRUE,
  n_boot = 300
)

res_aiptw <- adjusted_ahsw(
  adjsurv = adjsurv_aiptw,
  to = 0.7,
  conf_int = TRUE
)

ahsw_table(res_aiptw, method = "AIPTW")
```

If censoring depends on covariates, specify `covars_cens`:

``` r
adjsurv_aiptw <- aiptw_adjustedsurv(
  data = dat,
  covars_treat = c("x2", "x3", "x5", "x6"),
  covars_outcome = c("x1", "x2", "x4", "x5_squared"),
  covars_cens = c("x2"),
  y_col = "time",
  delta_col = "event",
  z_col = "group",
  bootstrap = TRUE,
  n_boot = 300
)
```

## Output

`adjusted_ahsw()` always returns point estimates in:

``` r
res$est
```

The object `res$est` contains RMST, event rate, and AHSW:

``` text
              group0  group1  difference  log_dif
rmst
event_rate
ahsw
```

Here, `difference` is:

``` text
group1 - group0
```

and `log_dif` is:

``` text
log(group1) - log(group0)
```

For the AHSW row, `exp(log_dif)` gives the ratio of average hazards.

If `conf_int = TRUE` and bootstrap data are available, `adjusted_ahsw()`
also returns bootstrap-based inference tables:

``` r
res$rmst
res$evrt
res$ahsw
```

These tables give inference results for RMST, event rate, and AHSW,
respectively. Each table has rows:

``` text
group0
group1
difference
log_dif
```

and columns:

``` text
est      point estimate
se       bootstrap standard error
low      lower confidence limit
upp      upper confidence limit
p_value  two-sided p-value
```

The `p_value` is reported for `difference` and `log_dif`. The p-values
for `group0` and `group1` are set to `NA`, because the main comparisons
are the difference and ratio between groups.

For example, `res$ahsw` gives bootstrap-based inference for AHSW. The
`log_dif` row is the log ratio of average hazards. The ratio and its
confidence interval can be obtained by exponentiating the log-scale
values:

``` r
exp(res$ahsw["log_dif", c("est", "low", "upp")])
```

## Documentation

Package documentation, function references, and the vignette are
available at:

<https://kkevin821.github.io/survAHadjust/>

The vignette can also be opened directly at:

<https://kkevin821.github.io/survAHadjust/articles/survAHadjust.html>

The vignette source file is available in:

``` text
vignettes/survAHadjust.Rmd
```

## Citation

If you use `survAHadjust`, please cite the software DOI from Zenodo:

``` text
Uno H, Horiguchi M, Xiong H. survAHadjust: Adjusted Average Hazard with Survival Weight. Version 1.0.1. Zenodo. https://doi.org/10.5281/zenodo.20277581
```
