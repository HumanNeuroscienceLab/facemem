# Load functions to get parameters in eventstats
source("param_funcs.R")

# Other Functions
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
    offsets = offsets, 
    duration = round(timing$duration), 
    orig.offsets = orig.offsets
  )
}

load.data <- function(subject, runtype, roi, 
                      basedir="~/Dropbox/Research/facemem/data/ts", 
                      prestim=5, poststim=19, 
                      select.nodes=NULL, node.names=NULL) 
{
  # Input file paths
  timing_file <- sprintf("%s/%s_%s_timing.txt", basedir, subject, runtype)
  dat_file    <- sprintf("%s/%s_%s_%s_peaks_ts.txt", basedir, subject, runtype, roi)
  
  # Read in data
  timing <- read.csv(timing_file)
  dat    <- read.table(dat_file)
  
  # Select any nodes of interest
  if (!is.null(select.nodes)) dat <- dat[,select.nodes]
  if (!is.null(node.names)) colnames(dat) <- node.names
  
  # Clean up trial indices
  timing <- get_trial_inds(timing, rel.onset=-prestim, rel.offset=poststim, tr=1) 
  
  # Split into trials
  library(plyr)
  ntrials         <- nrow(timing)
  ntpts           <- poststim + prestim + 1
  nregions        <- ncol(dat)
  # Take prestim seconds before the onset and poststim seconds after the onset
  trial_dat <- laply(1:ntrials, function(i) {
    trial.info  <- timing[i,]
    trialts     <- matrix(NA, ntpts, nregions)
    inds        <- trial.info$onset:trial.info$offset
    trialts[1:length(inds),] <- as.matrix(dat[inds,])
    trialts
  })
  tpts <- 1:dim(trial_dat)[2] - prestim - 1
  dimnames(trial_dat) <- list(trial=1:ntrials, time=tpts, region=node.names)
  #trial_dat <- aperm(trial_dat, c(3,1,2))
  
  list(trial=trial_dat, timing=timing, tpts=tpts)
}

# Removes the baseline signal and save output as percent signal change
remove.baseline <- function(lst.dat, baseline.tpts) {
  baseline.inds <- which(lst.dat$tpts %in% baseline.tpts)
  
  # Remove baseline for each trial
  # save as percent signal change
  dat <- lst.dat$trial
  dat <- aaply(dat, c(1,3), function(x) {
    m <- mean(x[baseline.inds], na.rm=T)
    (x-m)/m * 100
  })
  dat <- aperm(dat, c(1,3,2))
  lst.dat$trial <- dat
  
  lst.dat
}

# Generate smoothed average time-series across trials
smoothed.average <- function(dat, tpts, new.tpts) {
  library(mgcv)
  
  # Fit a smoothed spline to the data
  # spline will represent the average response across trials
  df.dat <- data.frame(
    y = as.vector(t(dat)), 
    x = rep(tpts, nrow(dat))
  )
  
  fit <- gam(y~s(x), data=df.dat) # TODO: can I add covariates?
  pred<- predict(fit, newdata=list(x=new.tpts), se=T)
  
  list(tpts=new.tpts, dat=pred)
}

## TESTING: MIXED EFFECTS
#sdf <- subset(all.df, roi.set=="postask" & runtype=="Questions" & region=="OFA" & condition=="bio")
#fit <- gamm( mean ~ s(tpts), random = list(subject=~1), data=sdf )
#new.tpts <- seq(-5, 19, by=1)
#res <- predict(fit$gam, newdata=list(tpts=new.tpts), se=T)
#plot(new.tpts, res$fit, type='l')

# Same as above except this will loop through each condition
smoothed.average.by.condition <- function(lst.dat, new.tr=0.2) {
  timing   <- lst.dat$timing
  uconds   <- levels(timing$condition)
  tpts     <- lst.dat$tpts
  new.tpts <- seq(tpts[1], tpts[length(tpts)], by=new.tr)
  regions  <- dimnames(lst.dat$trial)[[3]]
  nregions <- length(regions)
  
  avets.df <- ldply(uconds, function(cond) {
    trial.inds <- timing$condition == cond
    ldply(1:nregions, function(ri) {
      dat  <- lst.dat$trial[trial.inds,,ri]
      ret  <- smoothed.average(dat, tpts, new.tpts)
      data.frame(
        region = regions[ri], 
        condition = cond, 
        tpts = ret$tpts, 
        mean = ret$dat$fit, 
        se   = ret$dat$se.fit
      )
    })
  })
  
  avets.df
}

average.by.condition <- function(lst.dat) {
  timing   <- lst.dat$timing
  uconds   <- levels(timing$condition)
  tpts     <- lst.dat$tpts
  regions  <- dimnames(lst.dat$trial)[[3]]
  nregions <- length(regions)
  
  avets.df <- ldply(uconds, function(cond) {
    trial.inds <- timing$condition == cond
    ldply(1:nregions, function(ri) {
      dat  <- lst.dat$trial[trial.inds,,ri] # trials x tpts
      rmean<- colMeans(dat, na.rm=T)
      rsd  <- apply(dat, 2, sd, na.rm=T)/sqrt(nrow(dat))
      data.frame(
        region = regions[ri], 
        condition = cond, 
        tpts = tpts, 
        mean = rmean, 
        se   = rsd
      )
    })
  })
  
  avets.df
}

# Area Under the Curve of the HemoDynamic Response
auc.hdr <- function(vdat, tpts, to.plot=F) {
  # Restrict range of indices for peak detection
  inds      <- tpts>=0 & tpts<=16
  ptpts     <- tpts[inds]
  pts       <- vdat[inds]
  
  # Find the peak
  apts      <- abs(pts)
  peak.ind  <- which.max(apts)
  peak.tpts <- ptpts[peak.ind]
  peak.val  <- pts[peak.ind]
  
  # Since the baseline should be 0
  # see if the onset is within that range
  onset.search  <- pts>0 & apts<peak.val & ptpts<peak.tpts
  onset.ind     <- ifelse(sum(onset.search) > 0, which(onset.search)[1], 1)
  offset.search <- pts>0 & apts<peak.val & ptpts>peak.tpts
  offset.ind    <- ifelse(sum(offset.search) > 0, rev(which(offset.search))[1], length(pts))
  
  if (to.plot == TRUE) {
    plot(ptpts, as.numeric(pts), type='n', xlab="Time", ylab="% Signal Change")
    abline(h=0, col="grey")
    abline(v=ptpts[onset.ind], lty=2)
    abline(v=ptpts[offset.ind], lty=2)
    lines(ptpts, as.numeric(pts))
  }
  
  # Try different area under the curves
  # http://stackoverflow.com/questions/4954507/calculate-the-area-under-a-curve-in-r
  x <- ptpts[onset.ind:offset.ind]
  y <- pts[onset.ind:offset.ind]
  auc <- as.numeric(trapz(x,y))
  
  auc
}

# If you want to do a gamm model (mixed effects)
# for future reference
tmptmp <- function() {
  tmp <- ldply(subjects, function(subject) {
    # Load the data
    # ret <- list(trial=matrix(trial x time x region), timing, ntpts)
    lst.dat <- load.data(subject, runtype, roi, 
                         basedir="~/Dropbox/Research/facemem/data/ts", 
                         prestim=5, poststim=19, 
                         select.nodes=srois[[roi]], node.names=snames[[roi]])   
    
    # Remove the baseline
    lst.dat <- remove.baseline(lst.dat, baseline.tpts=-3:-1)
    
    ntrials <- dim(lst.dat$trial)[1]
    tpts    <- lst.dat$tpts
    regions <- dimnames(lst.dat$trial)$region
    timing  <- lst.dat$timing
    tdf     <- ldply(1:ntrials, function(ii) {
      ldply(tpts, function(tpt) {
        ldply(regions, function(region) {
          data.frame(
            trial = ii, 
            condition = as.character(timing$condition[ii]), 
            region = region, 
            time = tpt, 
            value = lst.dat$trial[ii,tpts==tpt,regions==region]
          )
        })
      })
    })
    
    ## Get the mean time-series per condition via a smoothed fit
    #ave.df  <- smoothed.average.by.condition(lst.dat, new.tr=0.2)
    
    # Return dataframe with additional information
    cbind(data.frame(
      roi.set = roi, 
      runtype = runtype, 
      subject = subject
    ), tdf)
  }, .progress="text")
  
  fit <- gamm( value ~ s(time), random = list(subject=~1), data= subset(tmp, region=="OFA" & condition=="bio") )
  new.tpts <- seq(-5, 19, by=1)
  res <- predict(fit$gam, newdata=list(time=new.tpts), se=T)
  plot(new.tpts, res$fit, type='l')
}

## Add an alpha value to a colour
# require(RCurl)
# source(textConnection(getURL("https://gist.github.com/mages/5339689/raw/576263b8f0550125b61f4ddba127f5aa00fa2014/add.alpha.R")))
add.alpha <- function(col=NULL, alpha=1){
  if(missing(col))
    stop("Please provide a vector of colours.")
  apply(sapply(col, col2rgb)/255, 2, 
        function(x) 
          rgb(x[1], x[2], x[3], alpha=alpha))  
}

# Plot
#cat("=== region:", snames[k], "=== \n")
#layout(1:2)
#ylim <- range(trial_dat[,,k], na.rm=T)

# dat is a ntrials x ntpts
plot.trial.ts <- function(dat, sname, cond, 
                          baseline.tpts=-3:-1, remove.baseline=TRUE, 
                          tpts=as.numeric(dimnames(dat)[[2]]), 
                          ylim=NULL, trial.col=add.alpha("red", 0.4)) {
  # k <- 1
  # sname <- snames[k]
  # cond=levels(timing$condition)[1]
  # trial_inds <- timing$condition == cond
  # dat <- trial_dat[trial_inds,,k]
  # ylim=range(dat, na.rm=T)
  # baseline.inds=1:3
  # remove.baseline=T
  # tpts=s.numeric(dimnames(dat)[[2]])
  # trial.col=add.alpha("red", 0.4)
  # layout(1)
  
  baseline.inds <- which(tpts %in% baseline.tpts)
  
  # Remove baseline for each trial
  # save as percent signal change
  if (remove.baseline) {
    dat <- aaply(dat, 1, function(x) {
      m <- mean(x[baseline.inds], na.rm=T)
      (x-m)/m * 100
    })
  }
  
  # Set the ylim
  if (is.null(ylim)) ylim <- range(dat, na.rm=T)
  
  # Plot initial box
  plot(tpts, dat[1,], type='n', ylim=ylim, 
       xlab="Time (sec)", ylab="BOLD Signal", main=sprintf("%s\n%s", sname, cond))
  
  # Add the vertical line for trial onset
  abline(v=0, lty=2, col="grey50")
  
  # Get the mean baseline and add this as a horizontal line
  baseline <- mean(dat[,baseline.inds])
  abline(h=baseline, lty=1, col="grey50")
  
  # Plot each of the trial responses
  for (i in 1:nrow(dat)) {
    lines(tpts, dat[i,], col=trial.col, lwd=2)
  }
  
  # Fit a smoothed spline to the data
  # spline will represent the average response across trials
  new.tr   <- 0.2
  new.tpts <- seq(tpts[1], tpts[length(tpts)], by=new.tr)
  df.dat <- data.frame(
    y = as.vector(t(dat)), 
    x = rep(tpts, nrow(dat))
  )
  fit <- gam(y~s(x), data=df.dat) # TODO: can I add covariates?
  pred<- predict(fit, newdata=list(x=new.tpts), se=T)
  lines(new.tpts, pred$fit, col=add.alpha("grey", 0.7), lwd=10)
  
  # Now get the parameters
  params <- get_parameters(pred$fit, new.tpts, baseline.time=tpts[baseline.inds])
  abline(v=params$peak, col="grey50", lty=3)
  if (length(params$width) > 0) {
    lines(params$peak+c(-1,1)*params$width/2, rep(ylim[1], 2), 
          lwd=4, col=add.alpha("grey50", 0.25))
  }
  abline(v=params$onset, col="grey50", lty=3)
  
  params
}
