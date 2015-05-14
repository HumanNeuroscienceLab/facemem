#' Extract model parameters
#' 
#' Returns the height, time to peak, and width of given HRF
#' If TR is given then returns time to peak and width in seconds
#' --- TODO: give details
#' --- TODO: also mention that borrow some code from link + give paper citation
#' --- TODO: also mention the onset latency paper
#' --- TODO: and scott's paper and lol anything else
#' 
#' @param hdrf hemodynamic response
#' @param TR time between each data-point in HDRF
#' 
#' @return list
#'
#' @examples
#' # TODO: add creation of some HRF and then analyze with this
get_parameters <- function(hdrf, tpts=0:(length(hdrf)-1), baseline.time=c(0,0), 
                           to.plot=FALSE) {
  # see: http://stackoverflow.com/questions/6836409/finding-local-maxima-and-minima
  local.maxima<- function(x) which(diff(sign(diff(x)))==-2)+1
  
  # Find the maximum of the response
  peak.ind    <- which.max(abs(hdrf))
  peak.height <- as.numeric(hdrf[peak.ind])
  peak.time   <- tpts[peak.ind]
  #if (peak.ind > 0.6*length(hdrf)) warning("Late time to peak")
  
  # Flip the HDR if negative (makes calculating onset and width easier)
  if (sign(peak.height) == -1) hdrf <- hdrf * -1
  
  # Calculate width as the difference in time between time-points at half
  # the height (relative to the baseline)
  baseline.inds   <- tpts >= baseline.time[1] & tpts <= baseline.time[2]
  baseline        <- mean(hdrf[baseline.inds])
  halfpeak.height <- as.numeric(hdrf[peak.ind] - (hdrf[peak.ind] - baseline)/2)
  half.inds       <- which(hdrf<halfpeak.height)
  ascend.ind      <- as.numeric(tail(half.inds[half.inds < peak.ind], 1) + 1)
  descend.ind     <- as.numeric(head(half.inds[half.inds > peak.ind], 1) + 0) # a bit of interpolation here
  width.time      <- tpts[descend.ind] - tpts[ascend.ind]
  
  # Calculate the onset latency when slope is 10% of max slope of ascending part
  # pick that 10% point that is closest to max slope...
  slopes      <- diff(hdrf)
  ascend.ind2 <- local.maxima(slopes)
  ascend.ind2 <- tail(ascend.ind2[ascend.ind2<peak.ind], 1)
  onset.ind   <- which(slopes <= 0.25*slopes[ascend.ind2])
  onset.ind   <- tail(onset.ind[onset.ind<ascend.ind2], 1)
  ## more accurate would be midway between this and next time-point
  onset.time  <- (tpts[onset.ind] + tpts[onset.ind+1])/2
  if (length(onset.time) == 0) onset.time <- NA
  
  if (to.plot) {
    # get main plot with baseline and onset
    plot(x=tpts, y=hdrf, type='n', xlab="Time", ylab="Signal")
    abline(h=baseline, col="grey75")
    abline(v=0, col="grey75")
    # show the peak
    abline(v=peak.time, lty=2)
    #abline(h=peak.height, col="grey", lty=2)
    # show the width
    abline(v=tpts[ascend.ind], lty=4)
    abline(v=tpts[descend.ind], lty=4)
    lines(tpts[c(ascend.ind,descend.ind)], hdrf[c(ascend.ind,descend.ind)], type='l')
    # show the onset
    abline(v=onset.time, lty=5)
    # finally get the main HRF
    lines(x=tpts, y=hdrf, lwd=2)
  }
  
  return(list(baseline=baseline, height=peak.height, peak=peak.time, width=width.time, onset=onset.time))
}

## Calculate the width of the response as the maximum of the slopes
## relative to the maximal response (or when slope doesn't change?)
#slopes      <- diff(hdrf)
### ascending part of function
### if many max slopes, choose max slope right before peak
#ascend.ind  <- local.maxima(slopes)
#ascend.ind  <- tail(ascend.ind[ascend.ind<peak.ind], 1)
### descending part of function
### if many min slopes, choose min slope right after peak
#descend.ind <- local.maxima(slopes*-1)
#descend.ind <- head(descend.ind[descend.ind>peak.ind], 1)
### width is difference in time between ascending and descending part of fct
#width.time  <- (descend.ind - ascend.ind)*TR
