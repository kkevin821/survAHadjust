# Using survAHadjust

## Overview

The `survAHadjust` package calculates average hazard-based summaries
from adjusted survival curves.

The main workflow is:

``` text
adjusted survival curves
  -> adjusted_ahsw()
  -> ahsw_table()
```

For most adjusted survival curve methods, users can use
[`adjustedCurves::adjustedsurv()`](https://robindenz1.github.io/adjustedCurves/reference/adjustedsurv.html).

For AIPTW, this package provides
[`aiptw_adjustedsurv()`](https://kkevin821.github.io/survAHadjust/reference/aiptw_adjustedsurv.md).

## Load packages

``` r

library(survAHadjust)
library(survival)
```

## Example data

We use the `pbc` data from the `survival` package only as a small
example dataset.

``` r

D <- survival::pbc[!is.na(survival::pbc$trt), ]

D$Y <- D$time / 365.25
D$Delta <- as.numeric(D$status == 2)
D$Z <- as.numeric(D$trt == 2)

D <- D[complete.cases(D[, c("Y", "Delta", "Z", "age", "sex", "bili", "albumin")]), ]

head(D[, c("Y", "Delta", "Z", "age", "sex", "bili", "albumin")])
#>           Y Delta Z      age sex bili albumin
#> 1  1.095140     1 0 58.76523   f 14.5    2.60
#> 2 12.320329     0 0 56.44627   f  1.1    4.14
#> 3  2.770705     1 0 70.07255   m  1.4    3.48
#> 4  5.270363     1 0 54.74059   f  1.8    2.54
#> 5  4.117728     0 1 38.10541   f  3.4    3.53
#> 6  6.852841     1 1 66.25873   f  0.8    3.98
```

## Workflow 1: Analyze an existing adjusted survival curve object

The function
[`adjusted_ahsw()`](https://kkevin821.github.io/survAHadjust/reference/adjusted_ahsw.md)
accepts an object that contains adjusted survival curves in
`adjsurv$adj`.

The required columns are:

``` text
time
surv
group
```

``` r

adjsurv_example <- list(
  adj = data.frame(
    time = c(0, 0.5, 1.0, 0, 0.5, 1.0),
    group = factor(c(0, 0, 0, 1, 1, 1)),
    surv = c(1.0, 0.80, 0.70, 1.0, 0.90, 0.85)
  )
)

res_example <- adjusted_ahsw(adjsurv_example, to = 1, conf_int = FALSE)

res_example$est
#>               group0    group1 difference     log_dif
#> rmst       0.9000000 0.9500000  0.0500000  0.05406722
#> event_rate 0.3000000 0.1500000 -0.1500000 -0.69314718
#> ahsw       0.3333333 0.1578947 -0.1754386 -0.74721440
```

The result can be formatted using
[`ahsw_table()`](https://kkevin821.github.io/survAHadjust/reference/ahsw_table.md).

``` r

tab_example <- ahsw_table(res_example, method = "Example")

knitr::kable(
  tab_example,
  align = c("l", rep("c", ncol(tab_example) - 1))
)
```

| Method  | Group 0 AH | Group 1 AH |  DAH   |  RAH  |
|:--------|:----------:|:----------:|:------:|:-----:|
| Example |   0.333    |   0.158    | -0.175 | 0.474 |

## Workflow 2: Standard methods from adjustedCurves

For standard adjusted survival curve methods, users can first call
[`adjustedCurves::adjustedsurv()`](https://robindenz1.github.io/adjustedCurves/reference/adjustedsurv.html)
and then pass the result to
[`adjusted_ahsw()`](https://kkevin821.github.io/survAHadjust/reference/adjusted_ahsw.md).

The following code shows the workflow. It is not evaluated in this
vignette because it depends on `adjustedCurves` and its additional
dependencies.

``` r

D_ac <- D
D_ac$Z <- factor(D_ac$Z)

outcome_model <- survival::coxph(
  survival::Surv(Y, Delta) ~ Z + age + sex + bili + albumin,
  data = D_ac,
  x = TRUE
)

adjsurv_direct <- adjustedCurves::adjustedsurv(
  data = D_ac,
  variable = "Z",
  ev_time = "Y",
  event = "Delta",
  method = "direct",
  outcome_model = outcome_model,
  conf_int = FALSE,
  bootstrap = FALSE
)

res_direct <- adjusted_ahsw(
  adjsurv = adjsurv_direct,
  to = 5,
  conf_int = FALSE
)

tab_direct <- ahsw_table(res_direct, method = "Direct standardization")

knitr::kable(
  tab_direct,
  align = c("l", rep("c", ncol(tab_direct) - 1))
)
```

Other methods from
[`adjustedCurves::adjustedsurv()`](https://robindenz1.github.io/adjustedCurves/reference/adjustedsurv.html)
can be used in the same way, such as IPTW, matching, empirical
likelihood, and Kaplan-Meier methods.

## Workflow 3: AIPTW

AIPTW is a standard doubly robust approach for estimating adjusted
survival curves. In `survAHadjust`, the function
[`aiptw_adjustedsurv()`](https://kkevin821.github.io/survAHadjust/reference/aiptw_adjustedsurv.md)
implements the AIPTW estimator used in our simulation study and
application. The implementation follows the AIPTW/IPCW setup described
by Ozenne et al. (2020). Under independent censoring, the censoring
distribution is estimated using a pooled Kaplan-Meier estimator; when
`covars_cens` is supplied, a Cox model is used for the censoring
distribution.

For non-AIPTW adjusted survival curve methods, users can use
[`adjustedCurves::adjustedsurv()`](https://robindenz1.github.io/adjustedCurves/reference/adjustedsurv.html)
and then pass the resulting object to
[`adjusted_ahsw()`](https://kkevin821.github.io/survAHadjust/reference/adjusted_ahsw.md).

If users prefer another implementation of AIPTW, they can also use that
output with
[`adjusted_ahsw()`](https://kkevin821.github.io/survAHadjust/reference/adjusted_ahsw.md)
as long as it is formatted as an adjusted survival curve object with an
`adj` element containing columns `time`, `surv`, and `group`.

For bootstrap-based confidence intervals, the object should also contain
`boot_data` with columns `time`, `surv`, `group`, and `boot`.

``` r

adjsurv_aiptw <- aiptw_adjustedsurv(
  data = D,
  covars_treat = c("age", "sex"),
  covars_outcome = c("bili", "age", "albumin"),
  y_col = "Y",
  delta_col = "Delta",
  z_col = "Z",
  bootstrap = FALSE
)

head(adjsurv_aiptw$adj)
#>        time      surv group
#> 1 0.0000000 1.0000000     0
#> 2 0.1122519 0.9944196     0
#> 3 0.1396304 0.9941534     0
#> 4 0.1943874 0.9876205     0
#> 5 0.2108145 0.9873209     0
#> 6 0.3011636 0.9870068     0
```

Then pass the result to
[`adjusted_ahsw()`](https://kkevin821.github.io/survAHadjust/reference/adjusted_ahsw.md).

``` r

res_aiptw <- adjusted_ahsw(
  adjsurv = adjsurv_aiptw,
  to = 5,
  conf_int = FALSE
)

res_aiptw$est
#>                group0     group1   difference     log_dif
#> rmst       4.31113377 4.17248530 -0.138648464 -0.03268907
#> event_rate 0.28738998 0.29232353  0.004933552  0.01702106
#> ahsw       0.06666227 0.07005981  0.003397537  0.04971014
```

Format the result:

``` r

tab_aiptw <- ahsw_table(res_aiptw, method = "AIPTW")

knitr::kable(
  tab_aiptw,
  align = c("l", rep("c", ncol(tab_aiptw) - 1))
)
```

| Method | Group 0 AH | Group 1 AH |  DAH  |  RAH  |
|:-------|:----------:|:----------:|:-----:|:-----:|
| AIPTW  |   0.067    |   0.070    | 0.003 | 1.051 |

## Bootstrap inference

Bootstrap inference can be requested by setting `bootstrap = TRUE`.

For real analyses, use a larger number of bootstrap samples, such as
`n_boot = 300`. The following code is not evaluated in this vignette
because it can take longer to run.

``` r

adjsurv_aiptw_boot <- aiptw_adjustedsurv(
  data = D,
  covars_treat = c("age", "sex"),
  covars_outcome = c("bili", "age", "albumin"),
  y_col = "Y",
  delta_col = "Delta",
  z_col = "Z",
  bootstrap = TRUE,
  n_boot = 300
)

res_aiptw_boot <- adjusted_ahsw(
  adjsurv = adjsurv_aiptw_boot,
  to = 5,
  conf_int = TRUE
)

tab_aiptw_boot <- ahsw_table(res_aiptw_boot, method = "AIPTW")

knitr::kable(
  tab_aiptw_boot,
  align = c("l", rep("c", ncol(tab_aiptw_boot) - 1))
)
```

The code above shows the workflow for real analyses. The small example
below is evaluated to show the structure of the bootstrap-based output
and how the confidence interval level appears in the output column
names.

``` r

adjsurv_boot_example <- list(
  adj = data.frame(
    time = c(0, 0.5, 1.0, 0, 0.5, 1.0),
    group = factor(c(0, 0, 0, 1, 1, 1)),
    surv = c(1.0, 0.80, 0.70, 1.0, 0.90, 0.85)
  ),
  boot_data = rbind(
    data.frame(
      time = c(0, 0.5, 1.0, 0, 0.5, 1.0),
      group = factor(c(0, 0, 0, 1, 1, 1)),
      surv = c(1.0, 0.82, 0.72, 1.0, 0.91, 0.86),
      boot = 1
    ),
    data.frame(
      time = c(0, 0.5, 1.0, 0, 0.5, 1.0),
      group = factor(c(0, 0, 0, 1, 1, 1)),
      surv = c(1.0, 0.78, 0.68, 1.0, 0.89, 0.84),
      boot = 2
    )
  )
)

res_boot_90 <- adjusted_ahsw(
  adjsurv = adjsurv_boot_example,
  to = 1,
  conf_int = TRUE,
  conf_level = 0.90
)

res_boot_90$ahsw
#>                   est          se     low_90    high_90 p_value
#> group0      0.3333333 0.036669323  0.2730177  0.3936490      NA
#> group1      0.1578947 0.016062150  0.1314749  0.1843146      NA
#> difference -0.1754386 0.020607173 -0.2093344 -0.1415428       0
#> log_dif    -0.7472144 0.008270833 -0.7608187 -0.7336101       0
```

When `conf_level = 0.90`, the confidence interval columns are named
`low_90` and `high_90`. Similarly, when `conf_level = 0.95`, the columns
are named `low_95` and `high_95`.

The helper function
[`ahsw_table()`](https://kkevin821.github.io/survAHadjust/reference/ahsw_table.md)
uses these confidence interval column names to label the summary table.
For example, because the object above was created with
`conf_level = 0.90`, the table columns include `Group 0 AH (90% CI)`,
`Group 1 AH (90% CI)`, `DAH (90% CI)`, and `RAH (90% CI)`.

The helper function
[`ahsw_table()`](https://kkevin821.github.io/survAHadjust/reference/ahsw_table.md)
returns a regular data frame. In rendered documents,
[`knitr::kable()`](https://rdrr.io/pkg/knitr/man/kable.html) can be used
to display it as a cleaner table. In the example below, line breaks are
added only for display so that the point estimate and confidence
interval appear on separate lines.

``` r

tab_boot_90 <- ahsw_table(res_boot_90, method = "Example")

tab_boot_90_display <- tab_boot_90

names(tab_boot_90_display) <- sub(
  " \\(",
  "<br>(",
  names(tab_boot_90_display)
)

tab_boot_90_display[-1] <- lapply(
  tab_boot_90_display[-1],
  function(x) sub(" \\(", "<br>(", x)
)

knitr::kable(
  tab_boot_90_display,
  align = c("l", rep("c", ncol(tab_boot_90_display) - 1)),
  escape = FALSE
)
```

[TABLE]

## Combining multiple methods

Results from multiple methods can be combined with
[`rbind()`](https://rdrr.io/r/base/cbind.html).

The following code shows how to combine results from standard methods
and AIPTW. It is not evaluated in this vignette because `res_direct` is
created in a non-evaluated example above.

``` r

tab_all <- rbind(
  ahsw_table(res_direct, method = "Direct standardization"),
  ahsw_table(res_aiptw, method = "AIPTW")
)

knitr::kable(
  tab_all,
  align = c("l", rep("c", ncol(tab_all) - 1))
)
```

For the evaluated example in this vignette, we only show the AIPTW row.

``` r

tab_aiptw_only <- rbind(
  ahsw_table(res_aiptw, method = "AIPTW")
)

knitr::kable(
  tab_aiptw_only,
  align = c("l", rep("c", ncol(tab_aiptw_only) - 1))
)
```

| Method | Group 0 AH | Group 1 AH |  DAH  |  RAH  |
|:-------|:----------:|:----------:|:-----:|:-----:|
| AIPTW  |   0.067    |   0.070    | 0.003 | 1.051 |
