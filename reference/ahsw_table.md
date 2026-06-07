# Create a summary table for adjusted average hazard results

Format the output from
[`adjusted_ahsw()`](https://kkevin821.github.io/survAHadjust/reference/adjusted_ahsw.md)
into a one-row summary table. This is useful for making paper-style
tables with group-specific AH, AH difference, and AH ratio.

## Usage

``` r
ahsw_table(
  x,
  method = NULL,
  group0_name = "Group 0",
  group1_name = "Group 1",
  digits = 3
)
```

## Arguments

- x:

  Output from
  [`adjusted_ahsw()`](https://kkevin821.github.io/survAHadjust/reference/adjusted_ahsw.md).

- method:

  Character string for the method name.

- group0_name:

  Column name for group 0.

- group1_name:

  Column name for group 1.

- digits:

  Number of digits to display.

## Value

A one-row data frame. If bootstrap-based inference is available,
confidence interval levels are shown in the column names, for example
`Group 0 AH (95% CI)` and `RAH (95% CI)`.

## Examples

``` r
adjsurv <- list(
  adj = data.frame(
    time = c(0, 0.5, 1.0, 0, 0.5, 1.0),
    group = factor(c(0, 0, 0, 1, 1, 1)),
    surv = c(1.0, 0.80, 0.70, 1.0, 0.90, 0.85)
  )
)

res <- adjusted_ahsw(adjsurv, to = 1, conf_int = FALSE)
ahsw_table(res, method = "Example")
#>    Method Group 0 AH Group 1 AH    DAH   RAH
#> 1 Example      0.333      0.158 -0.175 0.474
```
