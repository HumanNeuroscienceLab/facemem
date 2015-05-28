#' Here we vary the connectivity parameters to see what might work.
#' 
#' First we have some helper functions to create.
#' 
#+ functions

# Settings
timingdir <- "/mnt/nfs/psych/faceMemoryMRI/scripts/timing"
srois <- c(
  3,  # R OFA
  1,  # R FFA
  69, # R vATL (post)
  32, # R vATL (ant)
  8,  # L OFA
  2,  # L FFA
  62, # L vATL (post)
  26  # L vATL (ant)
)
snames <- c("R IOG", "R mFus", "R aFus", "R vATL", 
            "L IOG", "L mFus", "L aFus", "L vATL")
runtypes<- c("Questions", "NoQuestions")
conds   <- c("bio", "phys")
region  <- "prob_atlas_peaks_n146"
subjects <- as.character(read.table("sublist_all.txt")[,1])


#' Right now my aim is to load the data.
#' Note that it might be nice to redo the old approach with the variable lengths

base      <- "/mnt/nfs/psych/faceMemoryMRI"
scriptdir <- file.path(base, "scripts/connpaper")
setwd(file.path(scriptdir, "22_eventstats")); source("eventstats_funcs.R")
setwd(scriptdir)

runtype <- runtypes[1]
subject <- subjects[1]

cat("Runtype:", runtype, "\n")

load.concat.ts <- function(subject, runtype, 
                           to.scale=F, to.baseline=F, to.smooth=F, 
                           final.times=2:12, 
                           region="prob_atlas_peaks_n146") 
{
  # Paths
  subdir   <- file.path(base, "analysis/subjects", subject, runtype)
  resdir   <- file.path(subdir, "connectivity/task_residuals.reml")
  tsfile   <- file.path(resdir, sprintf("ts_%s.1D", region))
  timefile <- file.path(timingdir, sprintf("r_faceMemory01_%s_%s.csv", subject, runtype))
  
  # Read in the data
  lst.dat  <- load.data2(timefile, tsfile, 
                         prestim=5, poststim=19,  
                         select.nodes=srois, node.names=snames, 
                         to.smooth=to.smooth)
  
  # If you wanted to remove the baseline, this also would be where to do it
  if (to.baseline) {
    lst.dat <- remove.baseline(lst.dat, -2:0)
  }
  
  # Select the final times
  ## dat: ntrials x ntpts x nrois
  final.inds <- which(lst.dat$tpts %in% final.times)
  dat        <- lst.dat$trial[,final.inds,]
  
  # If you wanted to center and scale the data by each trial
  if (to.scale) {
    for (i in 1:dim(dat)[1]) {
      dat[i,,] <- scale(dat[i,,])
    }
  }
  
  # Split the data by condition and concatenate across trials
  cdat <- llply(conds, function(cond) {
    cdat <- dat[lst.dat$timing$condition == cond,,]
    dim(cdat) <- c(prod(dim(cdat)[1:2]), dim(cdat)[3])
    colnames(cdat) <- snames
    cdat
  })
  names(cdat) <- conds
  
  cdat
}

# Load the data with defaults
list.dat <- llply(runtypes, function(runtype) {
  cat("Runtype:", runtype, "\n")
  ret <- llply(subjects, function(subject) {
    load.concat.ts(subject, runtype)
  }, .progress="text")
  names(ret) <- subjects
  ret
})
names(list.dat) <- runtypes

# Compute the connectivity (FZ transformed r vals)
# zmats is 
# 2 x 2 x 16 x 6 x 6
# runtypes x conditions x subjects x rois x rois
zmats <- laply(runtypes, function(runtype) {
  cat("Runtype:", runtype, "\n")
  laply(conds, function(cond) {
    cat("- Condition:", cond, "\n")
    laply(subjects, function(subject) {
      # Compute correlation between ROI time-series
      ts.mat    <- list.dat[[runtype]][[subject]][[cond]]
      r.mat     <- cor(ts.mat)
      z.mat     <- atanh(r.mat)
      diag(z.mat) <- 0
      return(z.mat)
    }, .progress=prog)
  })
})
dimnames(zmats) <- list(runtype=runtypes, condition=conds, subject=subjects, 
                        roi=snames, roi=snames)

# Now let's try the significant test thing
pMats <- aaply(zmats, c(1,4,5), function(x) {
  if (all(x==1) || all(x==0)) {
    return(0)
  } else {
    return(t.test(x[1,], x[2,], paired=T)$p.value)
  }
})
round(pMats[1,,], 2)


#' ## Scale the Data
# Ok let's instead try to scale the data
list.dat <- llply(runtypes, function(runtype) {
  cat("Runtype:", runtype, "\n")
  ret <- llply(subjects, function(subject) {
    load.concat.ts(subject, runtype, to.scale=T)
  }, .progress="text")
  names(ret) <- subjects
  ret
})
names(list.dat) <- runtypes

zmats <- laply(runtypes, function(runtype) {
  cat("Runtype:", runtype, "\n")
  laply(conds, function(cond) {
    cat("- Condition:", cond, "\n")
    laply(subjects, function(subject) {
      # Compute correlation between ROI time-series
      ts.mat    <- list.dat[[runtype]][[subject]][[cond]]
      r.mat     <- cor(ts.mat)
      z.mat     <- atanh(r.mat)
      diag(z.mat) <- 0
      return(z.mat)
    }, .progress=prog)
  })
})
dimnames(zmats) <- list(runtype=runtypes, condition=conds, subject=subjects, 
                        roi=snames, roi=snames)

pMats <- aaply(zmats, c(1,4,5), function(x) {
  if (all(x==1) || all(x==0)) {
    return(0)
  } else {
    return(t.test(x[1,], x[2,], paired=T)$p.value)
  }
})
round(pMats[1,,], 2)
(pMats[1,,]<0.05 & pMats[1,,]>0)*1

#' ## Remove the baseline
#' 
list.dat <- llply(runtypes, function(runtype) {
  cat("Runtype:", runtype, "\n")
  ret <- llply(subjects, function(subject) {
    load.concat.ts(subject, runtype, to.scale=F, to.baseline=T)
  }, .progress="text")
  names(ret) <- subjects
  ret
})
names(list.dat) <- runtypes

zmats <- laply(runtypes, function(runtype) {
  cat("Runtype:", runtype, "\n")
  laply(conds, function(cond) {
    cat("- Condition:", cond, "\n")
    laply(subjects, function(subject) {
      # Compute correlation between ROI time-series
      ts.mat    <- list.dat[[runtype]][[subject]][[cond]]
      r.mat     <- cor(ts.mat)
      z.mat     <- atanh(r.mat)
      diag(z.mat) <- 0
      return(z.mat)
    }, .progress=prog)
  })
})
dimnames(zmats) <- list(runtype=runtypes, condition=conds, subject=subjects, 
                        roi=snames, roi=snames)

pMats <- aaply(zmats, c(1,4,5), function(x) {
  if (all(x==1) || all(x==0)) {
    return(0)
  } else {
    return(t.test(x[1,], x[2,], paired=T)$p.value)
  }
})
round(pMats[1,,], 2)
(pMats[1,,]<0.05 & pMats[1,,]>0)*1


#' ## Remove Baseline + Scale the Data
#+ base-scale
list.dat <- llply(runtypes, function(runtype) {
  cat("Runtype:", runtype, "\n")
  ret <- llply(subjects, function(subject) {
    load.concat.ts(subject, runtype, to.scale=T, to.baseline=T)
  }, .progress="text")
  names(ret) <- subjects
  ret
})
names(list.dat) <- runtypes

zmats <- laply(runtypes, function(runtype) {
  cat("Runtype:", runtype, "\n")
  laply(conds, function(cond) {
    cat("- Condition:", cond, "\n")
    laply(subjects, function(subject) {
      # Compute correlation between ROI time-series
      ts.mat    <- list.dat[[runtype]][[subject]][[cond]]
      r.mat     <- cor(ts.mat)
      z.mat     <- atanh(r.mat)
      diag(z.mat) <- 0
      return(z.mat)
    }, .progress=prog)
  })
})
dimnames(zmats) <- list(runtype=runtypes, condition=conds, subject=subjects, 
                        roi=snames, roi=snames)

pMats <- aaply(zmats, c(1,4,5), function(x) {
  if (all(x==1) || all(x==0)) {
    return(0)
  } else {
    return(t.test(x[1,], x[2,], paired=T)$p.value)
  }
})
round(pMats[1,,], 2)
(pMats[1,,]<0.05 & pMats[1,,]>0)*1



#' ## Graphical Lasso
#+ glasso
#library(glasso)
#library(cvTools)
#?rmspe

nrois <- 8
lh.inds <- 1:(nrois/2)
rh.inds <- (nrois/2+1):nrois
# 0 = no connection; 1 = yes connection
fixed.conn.mat <- matrix(0, nrois, nrois, dimnames=list(roi=snames, roi=snames))
# these are the right-hemisphere only connections
fixed.conn.mat[lh.inds,lh.inds] <- 1
# now the left-hemisphere connections
fixed.conn.mat[rh.inds,rh.inds] <- 1
# keep the diagonals out of this
diag(fixed.conn.mat) <- 0
# homotopic
diag(fixed.conn.mat[lh.inds,rh.inds]) <- 1
diag(fixed.conn.mat[rh.inds,lh.inds]) <- 1

# load the data
list.dat <- llply(runtypes, function(runtype) {
  cat("Runtype:", runtype, "\n")
  ret <- llply(subjects, function(subject) {
    load.concat.ts(subject, runtype)
  }, .progress="text")
  names(ret) <- subjects
  ret
})
names(list.dat) <- runtypes

library(netgsa)
tsmat <- list.dat$Questions$tb9226$bio
cv.fit <- cv.covsel(tsmat, zero=1-fixed.conn.mat, nfolds=10, 
                    lambda=seq(0,0.4,0.02))
min.lambda <- cv.fit$lambda[which.min(cv.fit$cve)]
fit <- covsel(tsmat, zero=1-fixed.conn.mat, 
              lambda=min.lambda)
#fit2 <- glasso(var(tsmat), rho=0.001, zero=1-fixed.conn.mat)

oc <- var(tsmat)
fit2 <- glasso(oc/mean(diag(oc)), rho=5/1000, 
               zero=cbind(row(fixed.conn.mat)[(1-fixed.conn.mat)==1], col(fixed.conn.mat)[(1-fixed.conn.mat)==1]))
fit$wi <- 

lambda=5; % arbitrary choice of regularisation!
  oc=cov(ts1); % raw covariance
ic=-L1precisionBCD(oc/mean(diag(oc)),lambda/1000); % get regularised negative inverse covariance
#r=(ic ./ repmat(sqrt(abs(diag(ic))),1,Nnodes)) ./ repmat(sqrt(abs(diag(ic)))',Nnodes,1); % use diagonal to get normalised coefficients
#r=r+eye(Nnodes); % remove diagonal 


-fit$wAdj
library(doMC)
registerDoMC(12)
zmats <- laply(runtypes, function(runtype) {
  cat("Runtype:", runtype, "\n")
  laply(conds, function(cond) {
    cat("- Condition:", cond, "\n")
    laply(subjects, function(subject) {
      # Compute correlation between ROI time-series
      ts.mat    <- list.dat[[runtype]][[subject]][[cond]]
      cv.fit <- cv.covsel(tsmat, zero=1-fixed.conn.mat, nfolds=10, 
                          lambda=seq(0,0.4,0.02))
      min.lambda <- cv.fit$lambda[which.min(cv.fit$cve)]
      fit <- covsel(ts.mat, zero=1-fixed.conn.mat, 
                    lambda=min.lambda)
      return(-fit$wAdj)
    }, .parallel=T)
  })
})
dimnames(zmats) <- list(runtype=runtypes, condition=conds, subject=subjects, 
                        roi=snames, roi=snames)

pMats <- aaply(zmats, c(1,4,5), function(x) {
  if (all(x==1) || all(x==0)) {
    return(0)
  } else {
    return(t.test(x[1,], x[2,], paired=T)$p.value)
  }
})
round(pMats[1,,], 2)
(pMats[1,,]<0.05 & pMats[1,,]>0)*1




#' ## Correlate the Smoothed Average Time-Series
#' 
#+ smooth-ave
all.df <- ldply(rois, function(roi) {
  ldply(runtypes, function(runtype) {
    ldply(subjects, function(subject) {
      # Load the data
      # ret <- list(trial=matrix(trial x time x region), timing, ntpts)
      lst.dat <- load.data(subject, runtype, roi, 
                           basedir=file.path(base, "data/ts"), 
                           prestim=5, poststim=19, 
                           select.nodes=srois[[roi]], node.names=snames[[roi]])   
      
      # Remove the baseline
      lst.dat <- remove.baseline(lst.dat, baseline.tpts=-2:0)
      ## to check
      ## round(as.numeric(apply(lst.dat$trial[,3:5,4], 1, mean), 2))
      
      # Get the mean time-series per condition via a smoothed fit
      ave.df  <- smoothed.average.by.condition(lst.dat, new.tr=0.2)
      
      # Return dataframe with additional information
      cbind(data.frame(
        roi.set = roi, 
        runtype = runtype, 
        subject = subject
      ), ave.df)
    }, .progress="text")
  })
})


#' ## Smoothing
#' 
#' I shall smooth the time-series with splines. The idea here is that my data is fairly noisy 
#' and using some amount of smoothing may help recover our signal. The noise issue is esp
#' true in the vATL and aFus regions.
#' 
#' This doesn't work either. Ok now I really need to stop!
#' 
#+ smooth
# Load the data with defaults
list.dat <- llply(runtypes, function(runtype) {
  cat("Runtype:", runtype, "\n")
  ret <- llply(subjects, function(subject) {
    load.concat.ts(subject, runtype, to.smooth=T, final.times=0:12)
  }, .progress="text")
  names(ret) <- subjects
  ret
})
names(list.dat) <- runtypes

# Compute the connectivity (FZ transformed r vals)
# zmats is 
# 2 x 2 x 16 x 6 x 6
# runtypes x conditions x subjects x rois x rois
zmats <- laply(runtypes, function(runtype) {
  cat("Runtype:", runtype, "\n")
  laply(conds, function(cond) {
    cat("- Condition:", cond, "\n")
    laply(subjects, function(subject) {
      # Compute correlation between ROI time-series
      ts.mat    <- list.dat[[runtype]][[subject]][[cond]]
      r.mat     <- cor(ts.mat)
      z.mat     <- atanh(r.mat)
      diag(z.mat) <- 0
      return(z.mat)
    }, .progress="none")
  })
})
dimnames(zmats) <- list(runtype=runtypes, condition=conds, subject=subjects, 
                        roi=snames, roi=snames)

# Now let's try the significant test thing
pMats <- aaply(zmats, c(1,4,5), function(x) {
  if (all(x==1) || all(x==0)) {
    return(0)
  } else {
    return(t.test(x[1,], x[2,], paired=T)$p.value)
  }
})
round(pMats[1,,], 2)
(pMats[1,,]<0.05 & pMats[1,,]>0)*1
