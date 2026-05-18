
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

For AIPTW, `survAHadjust` provides `aiptw_adjustedsurv()`.

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

Each of these tables contains:

``` text
est
se
low
upp
p_value
```

For example, `res$ahsw` contains bootstrap-based inference for
group-specific AHSW, the AHSW difference, and the log ratio. The rows of
`res$ahsw` are:

``` text
group0
group1
difference
log_dif
```

The ratio of average hazards can be obtained from the log ratio:

``` r
exp(res$ahsw["log_dif", "est"])
```

## Vignette

The vignette source file is available in:

``` text
vignettes/survAHadjust.Rmd
```

To preview the vignette without installing the package, open the file in
RStudio and click **Knit**.

To install the package with the vignette built locally, use:

``` r
install.packages("remotes")

remotes::install_github(
  "kkevin821/survAHadjust",
  build_vignettes = TRUE,
  dependencies = TRUE
)

vignette("survAHadjust", package = "survAHadjust")
```
