test_that("aiptw_adjustedsurv returns adjusted survival curves", {
  D <- survival::pbc[!is.na(survival::pbc$trt), ]
  D$Y <- D$time / 365.25
  D$Delta <- as.numeric(D$status == 2)
  D$Z <- as.numeric(D$trt == 2)

  adjsurv <- aiptw_adjustedsurv(
    data = D,
    covars_treat = c("age", "sex"),
    covars_outcome = c("bili", "age", "albumin"),
    y_col = "Y",
    delta_col = "Delta",
    z_col = "Z",
    bootstrap = FALSE
  )

  expect_s3_class(adjsurv, "adjustedsurv")
  expect_true("adj" %in% names(adjsurv))
  expect_true(all(c("time", "surv", "group") %in% names(adjsurv$adj)))
  expect_equal(sort(unique(adjsurv$adj$group)), c(0, 1))

  res <- adjusted_ahsw(adjsurv, to = 5, conf_int = FALSE)

  expect_true("est" %in% names(res))
  expect_true(all(c("rmst", "event_rate", "ahsw") %in% rownames(res$est)))
  expect_true(all(c("group0", "group1", "difference", "log_dif") %in% colnames(res$est)))
})


test_that("aiptw_adjustedsurv bootstrap works with adjusted_ahsw", {
  D <- survival::pbc[!is.na(survival::pbc$trt), ]
  D$Y <- D$time / 365.25
  D$Delta <- as.numeric(D$status == 2)
  D$Z <- as.numeric(D$trt == 2)

  set.seed(1)

  adjsurv <- aiptw_adjustedsurv(
    data = D,
    covars_treat = c("age", "sex"),
    covars_outcome = c("bili", "age", "albumin"),
    y_col = "Y",
    delta_col = "Delta",
    z_col = "Z",
    bootstrap = TRUE,
    n_boot = 2
  )

  expect_true("boot_data" %in% names(adjsurv))
  expect_true(all(c("time", "surv", "group", "boot") %in% names(adjsurv$boot_data)))
  expect_equal(sort(unique(adjsurv$boot_data$boot)), c(1, 2))

  res <- adjusted_ahsw(adjsurv, to = 5, conf_int = TRUE)

  expect_true(all(c("est", "rmst", "evrt", "ahsw") %in% names(res)))
  expect_true(all(c("est", "se", "low", "upp", "p_value") %in% names(res$ahsw)))
})
