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
#' @return A one-row data frame. If bootstrap-based inference is available,
#'   confidence interval levels are shown in the column names, for example
#'   `Group 0 AH (95% CI)` and `RAH (95% CI)`.
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

    # Find CI columns such as low_95 / high_95 or low_90 / high_90.
    low_col <- grep("^low_", names(ah), value = TRUE)[1]
    high_col <- grep("^high_", names(ah), value = TRUE)[1]

    # Fallback for old outputs, if needed.
    if (is.na(low_col) && "low" %in% names(ah)) {
      low_col <- "low"
    }

    if (is.na(high_col) && "upp" %in% names(ah)) {
      high_col <- "upp"
    }

    if (is.na(low_col) || is.na(high_col)) {
      stop("Cannot find confidence interval columns in `x$ahsw`.")
    }

    # Create a CI label from the column name.
    # For example, low_95 -> 95% CI, low_90 -> 90% CI.
    if (grepl("^low_", low_col)) {
      ci_level <- sub("^low_", "", low_col)
      ci_level <- gsub("_", ".", ci_level)
      ci_label <- paste0(ci_level, "% CI")
    } else {
      ci_label <- "CI"
    }

    group0 <- fmt_est(
      est = as.numeric(ah["group0", "est"]),
      low = as.numeric(ah["group0", low_col]),
      upp = as.numeric(ah["group0", high_col])
    )

    group1 <- fmt_est(
      est = as.numeric(ah["group1", "est"]),
      low = as.numeric(ah["group1", low_col]),
      upp = as.numeric(ah["group1", high_col])
    )

    difference <- fmt_est(
      est = as.numeric(ah["difference", "est"]),
      low = as.numeric(ah["difference", low_col]),
      upp = as.numeric(ah["difference", high_col])
    )

    ratio <- fmt_est(
      est = exp(as.numeric(ah["log_dif", "est"])),
      low = exp(as.numeric(ah["log_dif", low_col])),
      upp = exp(as.numeric(ah["log_dif", high_col]))
    )

    group0_col <- paste0(group0_name, " AH (", ci_label, ")")
    group1_col <- paste0(group1_name, " AH (", ci_label, ")")
    difference_col <- paste0("DAH (", ci_label, ")")
    ratio_col <- paste0("RAH (", ci_label, ")")

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

    group0_col <- paste0(group0_name, " AH")
    group1_col <- paste0(group1_name, " AH")
    difference_col <- "DAH"
    ratio_col <- "RAH"
  }

  out <- data.frame(
    Method = method,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  out[[group0_col]] <- group0
  out[[group1_col]] <- group1
  out[[difference_col]] <- difference
  out[[ratio_col]] <- ratio

  return(out)
}
