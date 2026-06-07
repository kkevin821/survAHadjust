test_that("ahsw_table formats point estimates", {
  adjsurv <- list(
    adj = data.frame(
      time = c(0, 0.5, 1.0, 0, 0.5, 1.0),
      group = factor(c(0, 0, 0, 1, 1, 1)),
      surv = c(1.0, 0.80, 0.70, 1.0, 0.90, 0.85)
    )
  )

  res <- adjusted_ahsw(adjsurv, to = 1, conf_int = FALSE)

  tab <- ahsw_table(res, method = "Example", digits = 3)

  expect_equal(nrow(tab), 1)
  expect_equal(tab$Method, "Example")
  expect_true("Group 0 AH" %in% names(tab))
  expect_true("Group 1 AH" %in% names(tab))
  expect_true("DAH" %in% names(tab))
  expect_true("RAH" %in% names(tab))

  expect_true(grepl("0.333", tab[["Group 0 AH"]]))
  expect_true(grepl("0.158", tab[["Group 1 AH"]]))
  expect_true(grepl("-0.175", tab[["DAH"]]))
  expect_true(grepl("0.474", tab[["RAH"]]))
})


test_that("ahsw_table works with confidence-level-specific CI columns", {

  x <- list(
    ahsw = data.frame(
      est = c(0.10, 0.20, 0.10, log(2)),
      se = c(0.01, 0.02, 0.02, 0.20),
      low_90 = c(0.08, 0.16, 0.06, 0.30),
      high_90 = c(0.12, 0.24, 0.14, 1.10),
      p_value = c(NA, NA, 0.04, 0.03),
      row.names = c("group0", "group1", "difference", "log_dif")
    )
  )

  tab <- ahsw_table(
    x = x,
    method = "Example",
    digits = 3
  )

  expect_equal(nrow(tab), 1)
  expect_equal(tab$Method, "Example")
  expect_true("Group 0 AH (90% CI)" %in% names(tab))
  expect_true("Group 1 AH (90% CI)" %in% names(tab))
  expect_true("DAH (90% CI)" %in% names(tab))
  expect_true("RAH (90% CI)" %in% names(tab))

  expect_true(grepl("0.100", tab[["Group 0 AH (90% CI)"]]))
  expect_true(grepl("0.080", tab[["Group 0 AH (90% CI)"]]))
  expect_true(grepl("0.120", tab[["Group 0 AH (90% CI)"]]))

  expect_true(grepl("0.200", tab[["Group 1 AH (90% CI)"]]))
  expect_true(grepl("0.160", tab[["Group 1 AH (90% CI)"]]))
  expect_true(grepl("0.240", tab[["Group 1 AH (90% CI)"]]))

  expect_true(grepl("0.100", tab[["DAH (90% CI)"]]))
  expect_true(grepl("0.060", tab[["DAH (90% CI)"]]))
  expect_true(grepl("0.140", tab[["DAH (90% CI)"]]))

  expect_true(grepl("2.000", tab[["RAH (90% CI)"]]))
})
