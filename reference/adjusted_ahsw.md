# Adjusted Average Hazard with Survival Weight (AHSW)

Calculate Adjusted Average Hazard with Survival Weight (AHSW), RMST, and
Event Rate.

## Usage

``` r
adjusted_ahsw(adjsurv, to, from=0, conf_int=FALSE, conf_level=0.95)
```

## Arguments

- adjsurv:

  A list object resulting from an adjusted survival analysis containing
  survival probabilities (`adjsurv$adj`) and optionally bootstrap data
  (`adjsurv$boot_data`).

- to:

  Numeric. The upper time limit (tau) for calculating RMST and AHSW.

- from:

  Numeric. Lower time limit for integration (default 0).

- conf_int:

  Logical. If TRUE, calculates bootstrap-based confidence intervals.

- conf_level:

  Numeric. Confidence level for intervals (default 0.95).

## Value

A list containing:

- est:

  A data frame with point estimates of RMST, event rate, and AHSW for
  two groups, their difference, and log difference.

- rmst:

  A data frame with bootstrap-based estimates, standard errors,
  confidence intervals, and p-values for RMST.

- evrt:

  Similar results as `rmst` but for event rate.

- ahsw:

  Similar results as `rmst` but for AHSW.

## Details

It also calculates confidence intervals and p-values using bootstrapped
standard errors.

## References

Uno H and Horiguchi M. Ratio and difference of average hazard with
survival weight: new measures to quantify survival benefit of new
therapy. Statistics in Medicine. 2023;1-17.
[doi:10.1002/sim.9651](https://doi.org/10.1002/sim.9651)

## Author

Hajime Uno, Miki Horiguchi, Hong Xiong

## Examples

``` r
adjsurv <- list(
  adj = data.frame(
    time = c(0, 0.5, 1.0, 0, 0.5, 1.0),
    group = factor(c(0, 0, 0, 1, 1, 1)),
    surv = c(1.0, 0.80, 0.70, 1.0, 0.90, 0.85)
  )
)

adjusted_ahsw(adjsurv, to = 1, conf_int = FALSE)
#> $est
#>               group0    group1 difference     log_dif
#> rmst       0.9000000 0.9500000  0.0500000  0.05406722
#> event_rate 0.3000000 0.1500000 -0.1500000 -0.69314718
#> ahsw       0.3333333 0.1578947 -0.1754386 -0.74721440
#> 
```
