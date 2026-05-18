#---------------------------------
# Child function: Vector to Matrix
#---------------------------------
vtm<-function(vc, dm){matrix(vc, ncol=length(vc), nrow=dm, byrow=T)}
#---------------------------------

# ---- AIPTW for cumulative incidence ----
# Based on the AIPTW estimator for right-censored time-to-event outcomes
# described in Ozenne et al. (2020).
aiptw_cif <- function(
    data,
    covars_treat,
    covars_outcome,
    covars_cens=NULL,
    y_col = "Y",
    delta_col = "Delta",
    z_col = "Z",
    ps_clip = c(1e-6, 1 - 1e-6),
    g_clip  = 1e-6
) {
  # check columns
  needed <- unique(c(y_col, delta_col, z_col, covars_treat, covars_outcome,
                     if (!is.null(covars_cens)) covars_cens))
  stopifnot(all(needed %in% names(data)))

  df <- data[, needed]
  names(df)[names(df) == y_col] <- "Y"
  names(df)[names(df) == delta_col] <- "Delta"
  names(df)[names(df) == z_col] <- "Z"

  df <- df[complete.cases(df), ]
  n <- nrow(df); if (n == 0L) stop("No complete cases after filtering.")

  # ---------------------------
  # t_grid
  # ---------------------------
  t_grid <- sort(unique(df$Y))
  K <-length(t_grid)

  # ---------------------------
  # 1) Treatment model: logistic regression (covars_treat)
  # ---------------------------
  form_ps <- as.formula(paste("Z ~", paste(covars_treat, collapse = " + ")))
  ps_fit  <- glm(form_ps, data = df, family = binomial(link = "logit"))
  ps1     <- as.numeric(predict(ps_fit, type = "response"))
  ps1     <- pmin(pmax(ps1, ps_clip[1]), ps_clip[2])
  ps0     <- 1 - ps1

  # ---------------------------
  # 2) Outcome model: Cox regression (covars_outcome)
  # ---------------------------
  form_cox <- as.formula(paste("Surv(Y, Delta) ~ Z +", paste(covars_outcome, collapse = " + ")))
  cox_fit  <- coxph(form_cox, data = df, ties = "efron", x = TRUE)

  #-------------------------------------------
  #-- adjusted survival curves (G-computation)
  #-------------------------------------------
  # Baseline cumulative hazard for LP = 0
  bh <- basehaz(cox_fit, centered = TRUE)
  H0_step <- stats::stepfun(bh$time, c(0, bh$hazard))   # step function for H0(t)
  H0_at_grid <- H0_step(t_grid)                         # length K

  # Linear predictors under Z=1 and Z=0 for each subject
  lp1 <- as.numeric(predict(cox_fit,
                            newdata = transform(df, Z = 1),
                            type = "lp"))
  lp0 <- as.numeric(predict(cox_fit,
                            newdata = transform(df, Z = 0),
                            type = "lp"))

  # Predicted cumulative incidence matrices: n x K
  # (outer(exp(lp), H0(t)) gives the subject-specific cumulative hazard H_i(t))
  predicted_F1 <- 1 - exp(-(exp(lp1) %o% H0_at_grid))
  predicted_F0 <- 1 - exp(-(exp(lp0) %o% H0_at_grid))

  # Marginal (G-computation) curves by averaging across subjects
  adj_F1_cox <- colMeans(predicted_F1)   # length K
  adj_F0_cox <- colMeans(predicted_F0)   # length K

  # ---------------------------
  # 3) Censoring
  # ---------------------------
  # -- independent --> KM
  if (is.null(covars_cens)){
    km_cens <- survfit(Surv(Y, 1 - Delta) ~ 1, data = df)
    G_step <- stats::stepfun(km_cens$time, c(1, km_cens$surv))
    G_at_Y <- pmax(G_step(df$Y), g_clip)
  }else{
    # -- Covariate-dependent --> Cox
    form_cox_cens <- as.formula(paste("Surv(Y, 1-Delta) ~ ", paste(covars_cens, collapse = " + ")))
    cox_fit_cens  <- coxph(form_cox_cens, data = df, ties = "efron", x = TRUE)
    G_at_Y = pmax(exp(-predict(cox_fit_cens,type="expected")),g_clip)
  }

  # ----------------------------------
  # 4) Compute AIPTW estimates (curve)
  # ----------------------------------
  #-- Index (counting process)--
  Ni_mat <- outer(df$Y, t_grid, "<=") * df$Delta  # n x K

  #-- IPCW --
  ipcw_mat = t(vtm(1/G_at_Y,K))  # n x K

  #-- PS weight ---
  w1 <- (df$Z == 1) / ps1 ; pswt1_mat = t(vtm(w1,K))  # n x K
  w0 <- (df$Z == 0) / ps0 ; pswt0_mat = t(vtm(w0,K))  # n x K

  #-- IPTW  ---
  tmp1 = Ni_mat * ipcw_mat * pswt1_mat
  tmp0 = Ni_mat * ipcw_mat * pswt0_mat
  adj_F1_iptw = apply(tmp1, 2, mean)
  adj_F0_iptw = apply(tmp0, 2, mean)

  #-- AIPTW  ---
  tmp1 = Ni_mat * ipcw_mat * pswt1_mat + predicted_F1 * (1-pswt1_mat)
  tmp0 = Ni_mat * ipcw_mat * pswt0_mat + predicted_F0 * (1-pswt0_mat)
  adj_F1_aiptw = apply(tmp1, 2, mean)
  adj_F0_aiptw = apply(tmp0, 2, mean)

  #--------------------------------------
  # OUTPUT
  #--------------------------------------
  Z=data.frame(t = c(0,t_grid),
               S1_AIPTW = 1 - c(0,adj_F1_aiptw),
               S0_AIPTW = 1 - c(0,adj_F0_aiptw),
               S1_Gcomp = 1 - c(0,adj_F1_cox),
               S0_Gcomp = 1 - c(0,adj_F0_cox),
               S1_IPTW  = 1 - c(0,adj_F1_iptw),
               S0_IPTW  = 1 - c(0,adj_F0_iptw)
  )

  attr(Z, "ps_fit")  <- ps_fit
  attr(Z, "cox_fit") <- cox_fit
  attr(Z, "G_at_Y") <- G_at_Y

  if (is.null(covars_cens)){
    attr(Z, "G_step")  <- G_step
  }else{
    attr(Z, "cox_fit_cens")  <- cox_fit_cens
  }
  return(Z)
}

#-------------------------------------------
# Convert aiptw_cif output to adjusted survival curve format
#-------------------------------------------
aiptw_to_adjsurv <- function(res){

  res2 <- res[, c("t", "S1_AIPTW", "S0_AIPTW")]

  adjsurv <- rbind(
    data.frame(time = res2$t, surv = res2$S0_AIPTW, group = 0),
    data.frame(time = res2$t, surv = res2$S1_AIPTW, group = 1)
  )

  return(adjsurv)
}

#' Estimate adjusted survival curves using AIPTW
#'
#' @description
#' Estimates adjusted survival curves using augmented inverse probability of
#' treatment weighting (AIPTW). This implementation follows the AIPTW/IPCW
#' setup used in the simulation study and application.
#'
#' @param data A data frame.
#' @param covars_treat Character vector of covariates for the treatment model.
#' @param covars_outcome Character vector of covariates for the outcome model.
#' @param covars_cens Character vector of covariates for the censoring model.
#'   If `NULL`, pooled KM is used for censoring. If not `NULL`, a Cox model is
#'   used for censoring.
#' @param y_col Name of the observed time variable. Default is `"time"`.
#' @param delta_col Name of the event indicator variable. Default is `"event"`.
#' @param z_col Name of the treatment/group variable. This variable should be
#'   coded as 0/1. Default is `"group"`.
#' @param bootstrap Logical. If `TRUE`, bootstrap adjusted survival curves are
#'   generated and stored in `boot_data`.
#' @param n_boot Number of bootstrap samples.
#' @param ps_clip Truncation range for propensity scores.
#' @param g_clip Lower bound for censoring survival probabilities.
#'
#' @return An adjusted survival curve object. The main element is `adj`,
#'   a data frame with columns `time`, `surv`, and `group`. If
#'   `bootstrap = TRUE`, the object also contains `boot_data`.
#'
#' @references
#' Ozenne B, Scheike TH, Staerk L, and Gerds TA. On the estimation of average
#' treatment effects with right-censored time to event outcome and competing
#' risks. Biometrical Journal. 2020;62(3):751-763.
#'
#' @examples
#' D <- survival::pbc[!is.na(survival::pbc$trt), ]
#' D$Y <- D$time / 365.25
#' D$Delta <- as.numeric(D$status == 2)
#' D$Z <- as.numeric(D$trt == 2)
#'
#' D <- D[complete.cases(D[, c("Y", "Delta", "Z", "age", "sex", "bili", "albumin")]), ]
#'
#' adjsurv <- aiptw_adjustedsurv(
#'   data = D,
#'   covars_treat = c("age", "sex"),
#'   covars_outcome = c("bili", "age", "albumin"),
#'   y_col = "Y",
#'   delta_col = "Delta",
#'   z_col = "Z",
#'   bootstrap = FALSE
#' )
#'
#' adjusted_ahsw(adjsurv, to = 5, conf_int = FALSE)
#'
#' \dontrun{
#' adjsurv_boot <- aiptw_adjustedsurv(
#'   data = D,
#'   covars_treat = c("age", "sex"),
#'   covars_outcome = c("bili", "age", "albumin"),
#'   y_col = "Y",
#'   delta_col = "Delta",
#'   z_col = "Z",
#'   bootstrap = TRUE,
#'   n_boot = 300
#' )
#'
#' adjusted_ahsw(adjsurv_boot, to = 5, conf_int = TRUE)
#' }
#'
#' @importFrom survival Surv coxph survfit basehaz
#' @importFrom stats as.formula binomial complete.cases glm predict
#' @export
aiptw_adjustedsurv <- function(data,
                               covars_treat,
                               covars_outcome,
                               covars_cens = NULL,
                               y_col = "time",
                               delta_col = "event",
                               z_col = "group",
                               bootstrap = FALSE,
                               n_boot = 300,
                               ps_clip = c(1e-6, 1 - 1e-6),
                               g_clip = 1e-6){

  #---- point estimate ----
  res <- aiptw_cif(
    data = data,
    covars_treat = covars_treat,
    covars_outcome = covars_outcome,
    covars_cens = covars_cens,
    y_col = y_col,
    delta_col = delta_col,
    z_col = z_col,
    ps_clip = ps_clip,
    g_clip = g_clip
  )

  adjsurv <- aiptw_to_adjsurv(res)

  Z <- list()
  Z$adj <- adjsurv
  Z$data <- data
  Z$method <- "aiptw"
  Z$variable <- z_col
  Z$ev_time <- y_col
  Z$event <- delta_col
  Z$covars_treat <- covars_treat
  Z$covars_outcome <- covars_outcome
  Z$covars_cens <- covars_cens
  Z$call <- match.call()

  #---- bootstrap survival curves ----
  if (bootstrap){

    boot_data <- c()

    for (b in 1:n_boot){

      BD <- data[sample(1:nrow(data), replace = TRUE), ]

      res_b <- aiptw_cif(
        data = BD,
        covars_treat = covars_treat,
        covars_outcome = covars_outcome,
        covars_cens = covars_cens,
        y_col = y_col,
        delta_col = delta_col,
        z_col = z_col,
        ps_clip = ps_clip,
        g_clip = g_clip
      )

      tmp <- aiptw_to_adjsurv(res_b)
      tmp$boot <- b

      boot_data <- rbind(boot_data, tmp)
    }

    Z$boot_data <- boot_data
  }

  class(Z) <- "adjustedsurv"

  return(Z)
}

