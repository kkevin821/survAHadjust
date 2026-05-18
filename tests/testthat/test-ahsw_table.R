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
  expect_true("Group 0" %in% names(tab))
  expect_true("Group 1" %in% names(tab))
  expect_true("Difference" %in% names(tab))
  expect_true("Ratio" %in% names(tab))
})
