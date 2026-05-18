
<!-- README.md is generated from README.Rmd. Please edit README.Rmd instead. -->

# survAHadjust

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

For AIPTW, this package provides a custom function:

``` text
aiptw_adjustedsurv()
```

Both workflows produce an adjusted survival curve object that can be
passed to `adjusted_ahsw()`.

## Installation

After the package is available on GitHub, it can be installed with:

``` r
install.packages("pak")
pak::pak("kkevin821/survAHadjust")
```

For local development, install from the package folder with:

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

## Custom AIPTW

For AIPTW, use `aiptw_adjustedsurv()`.

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

With `conf_int = FALSE`, `adjusted_ahsw()` returns point estimates:

``` text
res$est
```

With `conf_int = TRUE`, it also returns bootstrap-based inference:

``` text
res$rmst
res$evrt
res$ahsw
```

The `ahsw` output contains:

``` text
group0
group1
difference
log_dif
```

where `log_dif` is the log ratio:

``` text
log(group1) - log(group0)
```

The ratio can be obtained by:

``` r
exp(res$ahsw["log_dif", "est"])
```

## Vignette

See the package vignette for a more complete workflow:

``` r
vignette("survAHadjust")
```
