#===============================================================================
## function to calculate the average hazard with survival weight
## based on the adjusted survival curves derived from adjustedCurves::adjustedsurv()
## Difference will be group1 (large) - group0 (small)
## Reference: adjustedCurves::adjusted_rmst()
#===============================================================================

#--------------------------------------------------------------
# Calculate RMST, t-year, and AHSW from a given survival curve
#--------------------------------------------------------------


ahsw.calc=function(time, surv, tau=NA){

  #-- remove records with surv = NA
  idx = !is.na(surv)
  time=time[idx]
  surv=surv[idx]

  #-- default tau
  if (is.na(tau)) tau = max(x)
  idx=time<=tau

  #-- assume x has 0 and y has 1 in the first row --
  x = unique(c(time[idx],tau))
  y = surv[idx] ;
  if (length(x)>length(y)){
    y=c(y, y[length(y)])
  }
  cbind(x,y)
  x.diff = diff(x)

  #--- step function --
  rmst=x.diff%*%y[-length(y)]
  #--- linear interpolation ---
  #    y.sum = y[-length(y)] + y[-1]
  #    cbind(x.diff, y.sum)
  #    rmst=x.diff%*%y.sum/2

  #---- output ---
  Z=list()
  Z$rmst = rmst
  Z$tau = tau
  Z$event_rate = 1 - y[length(y)]
  Z$ahsw = Z$event_rate/Z$rmst
  return(Z)
}
#---------------------

#' @name adjusted_ahsw
#' @aliases adjusted_ahsw
#' @title Adjusted Average Hazard with Survival Weight (AHSW)
#' @description Calculate Adjusted Average Hazard with Survival Weight (AHSW), RMST, and Event Rate.
#' @details It also calculates confidence intervals and p-values using bootstrapped standard errors.
#' @author Hong Xiong, Hajime Uno
#' @references
#' Xiong H, Connors J, Schrag D, Uno H. Comparative Effectiveness Research with Average Hazard for Censored Time-to-Event Outcomes: A Numerical Study <arXiv:2407.00709>
#'
#' Uno H and Horiguchi M. Ratio and difference of average hazard with survival weight: new measures to quantify survival benefit of new therapy. Statistics in Medicine. 2023;1-17. \doi{10.1002/sim.9651}
#' @usage adjusted_ahsw(adjsurv, to, from=0, conf_int=FALSE, conf_level=0.95)
#' @param adjsurv A list object resulting from an adjusted survival analysis
#'   containing survival probabilities (`adjsurv$adj`) and optionally bootstrap
#'   data (`adjsurv$boot_adj`).
#' @param to Numeric. The upper time limit (tau) for calculating RMST and AHSW.
#' @param from Numeric. Lower time limit for integration (default 0).
#' @param conf_int Logical. If TRUE, calculates bootstrap-based confidence intervals.
#' @param conf_level Numeric. Confidence level for intervals (default 0.95).
#' @return A list containing:
#' \item{est}{A data frame with point estimates of RMST, event rate, and AHSW for two groups, their difference, and log difference.}
#' \item{rmst}{A data frame with bootstrap-based estimates, standard errors, confidence intervals, and p-values for RMST.}
#' \item{evrt}{Similar results as `rmst` but for event rate.}
#' \item{ahsw}{Similar results as `rmst` but for AHSW.}
#' @examples
#' library(survival)
#' library(ggplot2)
#' library(riskRegression)
#' library(pammtools)
#' library(adjustedCurves)
#'
#' # simulate standard survival data with 300 rows
#' data_1 <- sim_confounded_surv(n=300, max_t=1.1, group_beta=-0.6)
#' # code the grouping variable as a factor
#' data_1$group <- as.factor(data_1$group)
#'
#' # take a look at the first few rows
#' head(data_1)
#'
#' #--- Direct standardization via Cox regression model ----
#' outcome_model <- survival::coxph(Surv(time, event) ~ x1 + x2 + x3 + x4 + x5 + x6 + group,
#'                                  data=data_1, x=TRUE)
#' treatment_model <- glm(group ~ x1 + x2 + x3 + x4 + x5 + x6,
#'                        data=data_1, family=binomial(link="logit"))
#'
#' adjsurv <- adjustedsurv(data=data_1,
#'                         variable="group",
#'                         ev_time="time",
#'                         event="event",
#'                         method="direct",
#'                         outcome_model=outcome_model,
#'                         conf_int=TRUE,
#'                         bootstrap=TRUE,
#'                         n_boot=100)
#'
#' #--- AHSW ----
#' adjusted_ahsw(adjsurv, to=0.4, conf_int=TRUE)
#'
#' @export

#-------------------------------------------
# Wrapper (similar to adjustedCurves::adjusted_rmst())
#-------------------------------------------
adjusted_ahsw <- function(adjsurv, to, from=0, conf_int=FALSE, conf_level=0.95){

  #--- set to FALSE if it can't be done
  if (conf_int & is.null(adjsurv$boot_adj)){conf_int <- FALSE}

  #--- get the number of groups ---
  ugroup = sort(unique(adjsurv$adj$group)); ku = length(ugroup)

  #--- get the points estimates for each group --
  rmst = evrt = ahsw = rep(NA, 4)
  if(ku !=2 ) {print("Error: the number of groups is not 2") ; stop}
  for (i in 1:ku){
    idx = adjsurv$adj$group==ugroup[i]
    tmp = ahsw.calc(adjsurv$adj$time[idx], adjsurv$adj$surv[idx], tau=to)
    rmst[i] = tmp$rmst
    evrt[i] = tmp$event_rate
    ahsw[i] = tmp$ahsw
  }
  rmst[3] = rmst[2]-rmst[1]
  evrt[3] = evrt[2]-evrt[1]
  ahsw[3] = ahsw[2]-ahsw[1]

  rmst[4] = log(rmst[2])-log(rmst[1])
  evrt[4] = log(evrt[2])-log(evrt[1])
  ahsw[4] = log(ahsw[2])-log(ahsw[1])

  out = data.frame(rbind(rmst, evrt, ahsw)) #-- 3x4--
  rownames(out)=c("rmst","event_rate","ahsw")
  colnames(out)=c("group0","group1","difference","log_dif")

  #- output -
  Z=list()
  Z$est = out

  #=========================================
  # confidence interval based on bootstrap
  #=========================================
  if (conf_int & !is.null(adjsurv$boot_adj)){
    n_boot = max(adjsurv$boot_data$boot)

    #---- boot ---
    boot_rmst = boot_evrt = boot_ahsw = c()
    for (k in 1:n_boot){
      btime  = adjsurv$boot_data$time[adjsurv$boot_data$boot==k]
      bsurv  = adjsurv$boot_data$surv[adjsurv$boot_data$boot==k]
      bgroup = adjsurv$boot_data$group[adjsurv$boot_data$boot==k]

      for (i in 1:ku){
        idx = bgroup==ugroup[i]
        tmp2 = ahsw.calc(btime[idx], bsurv[idx], tau=to)
        rmst[i] = tmp2$rmst
        evrt[i] = tmp2$event_rate
        ahsw[i] = tmp2$ahsw
      }
      rmst[3] = rmst[2]-rmst[1]
      evrt[3] = evrt[2]-evrt[1]
      ahsw[3] = ahsw[2]-ahsw[1]

      rmst[4] = log(rmst[2])-log(rmst[1])
      evrt[4] = log(evrt[2])-log(evrt[1])
      ahsw[4] = log(ahsw[2])-log(ahsw[1])

      boot_rmst = rbind(boot_rmst, rmst)
      boot_evrt = rbind(boot_evrt, evrt)
      boot_ahsw = rbind(boot_ahsw, ahsw)
    }
    #-----------
    rownames(boot_rmst)=1:n_boot
    rownames(boot_evrt)=1:n_boot
    rownames(boot_ahsw)=1:n_boot
    colnames(boot_rmst)=c("group0","group1","difference","log_dif")
    colnames(boot_evrt)=c("group0","group1","difference","log_dif")
    colnames(boot_ahsw)=c("group0","group1","difference","log_dif")

    #---- SE ---
    se_rmst = apply(boot_rmst,2,sd)
    se_evrt = apply(boot_evrt,2,sd)
    se_ahsw = apply(boot_ahsw,2,sd)

    #---- add SE to the output ---
    out_rmst = data.frame(est=t(out[1,]), se=se_rmst)
    out_evrt = data.frame(est=t(out[2,]), se=se_evrt)
    out_ahsw = data.frame(est=t(out[3,]), se=se_ahsw)


    #--- add CI to the output -------
    tt = out_rmst;
    colnames(tt)=c("est","se")
    tt$low = tt$est - qnorm(1-(1-conf_level)/2)*tt$se
    tt$upp = tt$est + qnorm(1-(1-conf_level)/2)*tt$se
    tt$p_value = (1-pnorm(abs(tt$est/tt$se)))*2
    tt$p_value[1:2]=NA
    out_rmst = tt;

    tt = out_evrt;
    colnames(tt)=c("est","se")
    tt$low = tt$est - qnorm(1-(1-conf_level)/2)*tt$se
    tt$upp = tt$est + qnorm(1-(1-conf_level)/2)*tt$se
    tt$p_value = (1-pnorm(abs(tt$est/tt$se)))*2
    tt$p_value[1:2]=NA
    out_evrt = tt;

    tt = out_ahsw;
    colnames(tt)=c("est","se")
    tt$low = tt$est - qnorm(1-(1-conf_level)/2)*tt$se
    tt$upp = tt$est + qnorm(1-(1-conf_level)/2)*tt$se
    tt$p_value = (1-pnorm(abs(tt$est/tt$se)))*2
    tt$p_value[1:2]=NA
    out_ahsw = tt;

    #--- output ---
    Z$rmst = out_rmst
    Z$evrt = out_evrt
    Z$ahsw = out_ahsw
  }

  return(Z)
}
