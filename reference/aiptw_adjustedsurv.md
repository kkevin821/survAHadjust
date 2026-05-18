# Estimate adjusted survival curves using AIPTW

Estimates adjusted survival curves using augmented inverse probability
of treatment weighting (AIPTW). This implementation follows the
AIPTW/IPCW setup used in the simulation study and application.

## Usage

``` r
aiptw_adjustedsurv(
  data,
  covars_treat,
  covars_outcome,
  covars_cens = NULL,
  y_col = "time",
  delta_col = "event",
  z_col = "group",
  bootstrap = FALSE,
  n_boot = 300,
  ps_clip = c(1e-06, 1 - 1e-06),
  g_clip = 1e-06
)
```

## Arguments

- data:

  A data frame.

- covars_treat:

  Character vector of covariates for the treatment model.

- covars_outcome:

  Character vector of covariates for the outcome model.

- covars_cens:

  Character vector of covariates for the censoring model. If `NULL`,
  pooled KM is used for censoring. If not `NULL`, a Cox model is used
  for censoring.

- y_col:

  Name of the observed time variable. Default is `"time"`.

- delta_col:

  Name of the event indicator variable. Default is `"event"`.

- z_col:

  Name of the treatment/group variable. This variable should be coded as
  0/1. Default is `"group"`.

- bootstrap:

  Logical. If `TRUE`, bootstrap adjusted survival curves are generated
  and stored in `boot_data`.

- n_boot:

  Number of bootstrap samples.

- ps_clip:

  Truncation range for propensity scores.

- g_clip:

  Lower bound for censoring survival probabilities.

## Value

An adjusted survival curve object. The main element is `adj`, a data
frame with columns `time`, `surv`, and `group`. If `bootstrap = TRUE`,
the object also contains `boot_data`.

## References

Ozenne B, Scheike TH, Staerk L, and Gerds TA. On the estimation of
average treatment effects with right-censored time to event outcome and
competing risks. Biometrical Journal. 2020;62(3):751-763.

## Examples

``` r
D <- survival::pbc[!is.na(survival::pbc$trt), ]
D$Y <- D$time / 365.25
D$Delta <- as.numeric(D$status == 2)
D$Z <- as.numeric(D$trt == 2)

D <- D[complete.cases(D[, c("Y", "Delta", "Z", "age", "sex", "bili", "albumin")]), ]

adjsurv <- aiptw_adjustedsurv(
  data = D,
  covars_treat = c("age", "sex"),
  covars_outcome = c("bili", "age", "albumin"),
  y_col = "Y",
  delta_col = "Delta",
  z_col = "Z",
  bootstrap = FALSE
)

adjusted_ahsw(adjsurv, to = 5, conf_int = FALSE)
#> $est
#>                group0     group1   difference     log_dif
#> rmst       4.31113377 4.17248530 -0.138648464 -0.03268907
#> event_rate 0.28738998 0.29232353  0.004933552  0.01702106
#> ahsw       0.06666227 0.07005981  0.003397537  0.04971014
#> 

if (FALSE) { # \dontrun{
adjsurv_boot <- aiptw_adjustedsurv(
  data = D,
  covars_treat = c("age", "sex"),
  covars_outcome = c("bili", "age", "albumin"),
  y_col = "Y",
  delta_col = "Delta",
  z_col = "Z",
  bootstrap = TRUE,
  n_boot = 300
)

adjusted_ahsw(adjsurv_boot, to = 5, conf_int = TRUE)
} # }
```
