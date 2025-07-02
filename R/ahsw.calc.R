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
