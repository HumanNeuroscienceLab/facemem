#!/usr/bin/env Rscript


suppressMessages(library(niftir))

require(Rcpp)
require(RcppArmadillo)
require(inline)
require(bigmemory)
library(mgcv)

datadir   <- "/mnt/nfs/psych/faceMemoryMRI/analysis/subjects"
timingdir <- "/mnt/nfs/psych/faceMemoryMRI/scripts/timing"


#--- FUNCTIONS ---#

read_data <- function(subject, runtype, fname="filtered_func_data") {
  # Get the timing file
  timing_fname  <- sprintf("%s/r_faceMemory01_%s_%s.csv", timingdir, subject, runtype)
  timing        <- read.csv(timing_fname)
  
  # Read in the data
  ## paths
  scan_dir      <- file.path(datadir, subject, runtype)
  ts_file       <- file.path(scan_dir, paste(fname, ".nii.gz", sep=""))
  mask_file     <- file.path(scan_dir, "mask.nii.gz")
  ## read
  hdr           <- read.nifti.header(ts_file)
  mask          <- read.mask(mask_file)
  dat           <- read.big.nifti(ts_file, shared=F)
  mdat          <- deepcopy(dat, cols=mask, shared=T)
  rm(dat); gc(F,T)
  
  list(timing=timing, dat=mdat, hdr=hdr, mask=mask)
}

read_data <- function(subject, runtype, fname="filtered_func_data") {
  # Get the timing file
  timing_fname  <- sprintf("%s/r_faceMemory01_%s_%s.csv", timingdir, subject, runtype)
  timing        <- read.csv(timing_fname)
  
  # Read in the data
  ## paths
  scan_dir      <- file.path(datadir, subject, runtype)
  ts_file       <- file.path(scan_dir, paste(fname, ".nii.gz", sep=""))
  mask_file     <- file.path(scan_dir, "mask.nii.gz")
  ## read
  hdr           <- read.nifti.header(ts_file)
  mask          <- read.mask(mask_file)
  dat           <- read.big.nifti(ts_file, shared=F)
  mdat          <- deepcopy(dat, cols=mask, shared=T)
  rm(dat); gc(F,T)
  
  list(timing=timing, dat=mdat, hdr=hdr, mask=mask)
}
# dat <- read_data("tb9226", "Questions")

# Splits data into bio/phys
get_trial_inds <- function(timing, rel.onset=-5, rel.offset=19, tr=1) {
  ntrials         <- nrow(timing)
  
  # Get the timepoints for each individual trial
  onsets          <- round(timing$onset/tr) + rel.onset + 1
  offsets         <- round(timing$onset/tr) + rel.offset + 1 
  
  # For trials at the end of runs, make sure offset isn't greater than duration
  orig.offsets    <- offsets
  last.trial.inds <- c(diff(timing$run)==1,TRUE)
  last.trial.offsets <- round(timing$onset[last.trial.inds]/tr) + 
    round(timing$duration[last.trial.inds]/tr) + 1 - 1
  offsets[last.trial.inds] <- last.trial.offsets
  
  # Return new onsets and offsets with everything else
  data.frame(
    run = timing$run, 
    trial = timing$trial, 
    condition = timing$condition, 
    onset = onsets, 
    offset = offsets, 
    duration = round(timing$duration), 
    orig.offset = orig.offsets
  )
}
# tpts <- -5:19
# trialtiming <- get_trial_inds(dat$timing, -5, 19)

# For the compile trial data function below
# and later the mean function
l <- getPlugin("RcppArmadillo")
plugin_bigmemory <- Rcpp::Rcpp.plugin.maker(
  include.before = "#include <RcppArmadillo.h>",  
  include.after = '
  #include "bigmemory/BigMatrix.h"     
  #include "bigmemory/MatrixAccessor.hpp"     
  #include "bigmemory/bigmemoryDefines.h"     
  #include "bigmemory/isna.hpp"     
  ', 
  libs    = "$(LAPACK_LIBS) $(BLAS_LIBS) $(FLIBS)", 
  LinkingTo = c("BH", "bigmemory", "RcppArmadillo", "Rcpp"), 
  Depends = c("bigmemory", "RcppArmadillo", "Rcpp"), 
  package = "bigmemory"
)
inline::registerPlugin("plug_bigmemory", plugin_bigmemory)
getPlugin("plug_bigmemory")

cpp_remove_baseline <- cxxfunction(signature(px = "externalptr", rstart = "numeric", rend = "numeric"), '
                                   /* R -> C++ (using Rcpp smart pointer) */
                                   Rcpp::XPtr<BigMatrix> pBigMat(px);
                                   
                                   /*  Start and end indices for mean baseline removal */
                                   arma::uword start = Rcpp::as<arma::uword>(rstart) - 1;
                                   arma::uword end = Rcpp::as<arma::uword>(rend) - 1;
                                   
                                   /* BigMat -> Arma */
                                   index_type offset = pBigMat->nrow() * pBigMat->col_offset();
                                   double *ptr_double = reinterpret_cast<double*>(pBigMat->matrix()) + offset;
                                   arma::mat X(ptr_double, pBigMat->nrow(), pBigMat->ncol(), false);
                                   
                                   /* Remove the baseline */
                                   arma::vec Xc;
                                   double baseline;
                                   for (arma::uword i = 0; i < X.n_cols; i++) {
                                     Xc = X.col(i);
                                     baseline = arma::mean(Xc.subvec(start,end));
                                     Xc = (Xc - baseline)/baseline * 100;
                                     X.col(i) = Xc;
                                   }
                                   
                                   return( px );
                                   ', plugin = "plug_bigmemory")

cpp_rowmean <- cxxfunction(signature(px = "externalptr"), '
                           /* R -> C++ (using Rcpp smart pointer) */
                           Rcpp::XPtr<BigMatrix> pBigMat(px);
                           
                           /* BigMat -> Arma */
                           index_type offset = pBigMat->nrow() * pBigMat->col_offset();
                           double *ptr_double = reinterpret_cast<double*>(pBigMat->matrix()) + offset;
                           arma::mat X(ptr_double, pBigMat->nrow(), pBigMat->ncol(), false);
                           
                           /* Get row means */
                           arma::vec rX = arma::mean(X,1);
                           
                           return Rcpp::wrap(rX);
                           ', plugin = "plug_bigmemory")
# mat <- matrix(rnorm(10*100), 10, 100)
# bmat <- as.big.matrix(mat)
# res1 <- cpp_rowmean(bmat@address)
# res2 <- rowMeans(mat)
# all.equal(as.numeric(res1),as.numeric(res2))

cpp_rowsd <- cxxfunction(signature(px = "externalptr"), '
                         /* R -> C++ (using Rcpp smart pointer) */
                         Rcpp::XPtr<BigMatrix> pBigMat(px);
                         
                         /* BigMat -> Arma */
                         index_type offset = pBigMat->nrow() * pBigMat->col_offset();
                         double *ptr_double = reinterpret_cast<double*>(pBigMat->matrix()) + offset;
                         arma::mat X(ptr_double, pBigMat->nrow(), pBigMat->ncol(), false);
                         
                         /* Get row sds */
                         arma::vec rX = arma::stddev(X,0,1);
                         
                         return Rcpp::wrap(rX);
                         ', plugin = "plug_bigmemory")
# mat <- matrix(rnorm(10*100), 10, 100)
# bmat <- as.big.matrix(mat)
# res1 <- cpp_rowsd(bmat@address)
# res2 <- apply(mat, 1, sd)
# all.equal(as.numeric(res1),as.numeric(res2))

# Compile data for a given trial
## vi = voxel index
get_trial_data <- function(vdat, trialtiming, vi, parallel=F, 
                           trials=1:nrow(trialtiming), 
                           remove.baseline=F, baseline.inds=c(1,1)) 
{
  ntpts     <- max(trialtiming$offset-trialtiming$onset+1)
  ntrials   <- length(trials)
  trial_dat <- big.matrix(ntpts,ntrials,init=NA,shared=T)
  
  l_ply(1:length(trials), function(i) {
    ti <- trials[i]
    inds  <- trialtiming$onset[ti]:trialtiming$offset[ti]
    n     <- length(inds)
    bedeepcopy(x=vdat, x.cols=vi, x.rows=inds, 
               y=trial_dat, y.cols=i, y.rows=1:n)
  }, .parallel=parallel)
  
  if (remove.baseline) {
    cpp_remove_baseline(trial_dat@address, baseline.inds[1], baseline.inds[2])
  }
  
  trial_dat
}
#baseline.inds <- c(3,5)
#trialdat <- get_trial_data(dat$dat, trialtiming, vi=1, 
#                           trials=which(trialtiming$condition=='bio'), 
#                           remove.baseline=T, baseline.inds=baseline.inds)

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
  if (length(width.time) == 0) width.time <- NA
  
  # Calculate the onset latency when slope is 10% of max slope of ascending part
  # pick that 10% point that is closest to max slope...
  slopes      <- diff(hdrf)
  ascend.ind2 <- local.maxima(slopes)
  ascend.ind2 <- tail(ascend.ind2[ascend.ind2<peak.ind], 1)
  onset.ind   <- which(slopes <= 0.1*slopes[ascend.ind2])
  onset.ind   <- tail(onset.ind[onset.ind<ascend.ind2], 1)
  ## more accurate would be midway between this and next time-point
  onset.time  <- (tpts[onset.ind] + tpts[onset.ind+1])/2
  if (length(onset.time) == 0) onset.time <- NA
  
  # For kicks, let's also calculate the offset latency
  descend.ind2 <- local.maxima(slopes*-1)
  descend.ind2 <- head(descend.ind2[descend.ind2>peak.ind], 1)
  offset.ind   <- which(slopes >= 0.1*slopes[descend.ind2])
  offset.ind   <- tail(offset.ind[offset.ind>descend.ind2], 1)
  ## more accurate would be midway between this and next time-point
  offset.time  <- (tpts[offset.ind] + tpts[offset.ind+1])/2
  if (length(offset.time) == 0) offset.time <- NA
  
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
  
  return(c(baseline=baseline, height=peak.height, peak=peak.time, 
              width=width.time, onset=onset.time, offset=offset.time))
}

# Get the plain average acrss trials
get_average <- function(trialdat, tpts) {
  # Get the average at each time-point
  #trialave  <- as.numeric(cpp_rowmean(trialdat@address))
  #trialsd   <- as.numeric(cpp_rowsd(trialdat@address))
  trialdat  <- as.matrix(trialdat)
  trialave  <- rowMeans(trialdat, na.rm=T)
  trialsd   <- apply(trialdat, 1, sd, na.rm=T)
  
  list(tpts=tpts, ave=trialave, sd=trialsd)
}
# avedat <- get_average(trialdat, tpts)

# Get the smoothed average across trials for each condition
get_smoothed_average <- function(trialdat, tpts, new.tr=0.2, retfit=F)
{
  # Fit a smoothed spline to the data
  # spline will represent the average response across trials
  new.tpts  <- seq(tpts[1], tpts[length(tpts)], by=new.tr)
  df.dat    <- data.frame(
    y = as.vector(as.matrix(trialdat)), 
    x = rep(tpts, ncol(trialdat))
  )
  fit       <- gam(y~s(x), data=df.dat) # TODO: can I add covariates?
  pred      <- predict(fit, newdata=list(x=new.tpts), se=T)
  
  ret <- list(tpts=tpts, new.tpts=new.tpts, ave=as.numeric(pred$fit), se=as.numeric(pred$se))
  
  if (retfit) ret$fit <- fit
    
  return(ret)
}
# smoothavedat <- get_smoothed_average(trialdat, tpts)

# Get the parameters (for the smoothed spline fit)
get_smoothed_params <- function(smoothedave, baseline.inds) {
  params    <- get_parameters(smoothedave$ave, tpts=smoothedave$new.tpts, 
                              baseline.time=smoothedave$tpts[baseline.inds])
  params
}
# params <- get_smoothed_params(smoothavedat, baseline.inds)


# find the code to load the voxelwise data as trial data
## make sure that the trials are set to -5 to 19 (and that a +1 is added!)
# then port my get_parameters code
# and loop through each voxel saving each parameter into two large big matrices for bio/phys
# save the big matrices?
# do above across for all subjects
# calculate the mean and paired difference (t-test)
# save the outputs