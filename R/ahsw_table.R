#' Create a summary table for adjusted average hazard results
#'
#' @description
#' Format the output from `adjusted_ahsw()` into a one-row summary table.
#' This is useful for making paper-style tables with group-specific AH,
#' AH difference, and AH ratio.
#'
#' @param x Output from `adjusted_ahsw()`.
#' @param method Character string for the method name.
#' @param group0_name Column name for group 0.
#' @param group1_name Column name for group 1.
#' @param digits Number of digits to display.
#'
#' @return A one-row data frame.
#'
#' @examples
#' adjsurv <- list(
#'   adj = data.frame(
#'     time = c(0, 0.5, 1.0, 0, 0.5, 1.0),
#'     group = factor(c(0, 0, 0, 1, 1, 1)),
#'     surv = c(1.0, 0.80, 0.70, 1.0, 0.90, 0.85)
#'   )
#' )
#'
#' res <- adjusted_ahsw(adjsurv, to = 1, conf_int = FALSE)
#' ahsw_table(res, method = "Example")
#'
#' @export
ahsw_table <- function(x,
                       method = NULL,
                       group0_name = "Group 0",
                       group1_name = "Group 1",
                       digits = 3){

  if (is.null(method)) {
    method <- NA_character_
  }

  fmt_num <- function(z){
    format(round(z, digits), nsmall = digits)
  }

  fmt_est <- function(est, low = NULL, upp = NULL){
    if (is.null(low) || is.null(upp)) {
      return(fmt_num(est))
    }

    paste0(
      fmt_num(est),
      " (",
      fmt_num(low),
      " to ",
      fmt_num(upp),
      ")"
    )
  }

  #-----------------------------------------
  # With bootstrap CI
  #-----------------------------------------
  if (!is.null(x$ahsw)) {

    ah <- x$ahsw

    group0 <- fmt_est(
      est = as.numeric(ah["group0", "est"]),
      low = as.numeric(ah["group0", "low"]),
      upp = as.numeric(ah["group0", "upp"])
    )

    group1 <- fmt_est(
      est = as.numeric(ah["group1", "est"]),
      low = as.numeric(ah["group1", "low"]),
      upp = as.numeric(ah["group1", "upp"])
    )

    difference <- fmt_est(
      est = as.numeric(ah["difference", "est"]),
      low = as.numeric(ah["difference", "low"]),
      upp = as.numeric(ah["difference", "upp"])
    )

    ratio <- fmt_est(
      est = exp(as.numeric(ah["log_dif", "est"])),
      low = exp(as.numeric(ah["log_dif", "low"])),
      upp = exp(as.numeric(ah["log_dif", "upp"]))
    )

  } else {

    #-----------------------------------------
    # Point estimate only
    #-----------------------------------------
    ah <- x$est

    group0 <- fmt_est(
      est = as.numeric(ah["ahsw", "group0"])
    )

    group1 <- fmt_est(
      est = as.numeric(ah["ahsw", "group1"])
    )

    difference <- fmt_est(
      est = as.numeric(ah["ahsw", "difference"])
    )

    ratio <- fmt_est(
      est = exp(as.numeric(ah["ahsw", "log_dif"]))
    )
  }

  out <- data.frame(
    Method = method,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  out[[group0_name]] <- group0
  out[[group1_name]] <- group1
  out[["Difference"]] <- difference
  out[["Ratio"]] <- ratio

  return(out)
}
