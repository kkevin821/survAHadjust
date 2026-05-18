test_that("adjusted_ahsw returns correct point estimates", {
  adjsurv <- list(
    adj = data.frame(
      time = c(0, 0.5, 1.0, 0, 0.5, 1.0),
      group = factor(c(0, 0, 0, 1, 1, 1)),
      surv = c(1.0, 0.80, 0.70, 1.0, 0.90, 0.85)
    )
  )

  res <- adjusted_ahsw(adjsurv, to = 1, conf_int = FALSE)

  expect_equal(as.numeric(res$est["rmst", "group0"]), 0.9)
  expect_equal(as.numeric(res$est["rmst", "group1"]), 0.95)

  expect_equal(as.numeric(res$est["event_rate", "group0"]), 0.3)
  expect_equal(as.numeric(res$est["event_rate", "group1"]), 0.15)

  expect_equal(as.numeric(res$est["ahsw", "group0"]), 0.3 / 0.9)
  expect_equal(as.numeric(res$est["ahsw", "group1"]), 0.15 / 0.95)
})
