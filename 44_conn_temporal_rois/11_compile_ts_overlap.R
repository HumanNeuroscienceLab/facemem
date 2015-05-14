#!/usr/bin/env Rscript

# This script will read in all the ROI time-series and compile them into one rda file

library(plyr)
library(doMC)
registerDoMC(16)

###
# SETUP

cat("setup\n")

subjects <- as.character(as.matrix(read.table("../sublist_all.txt")))
# We want to select a subset of the extract ROIs for our analyses
srois <- c(
  2,   # L vATL
  5,   # L PHC
  4,   # L RSC
  40,   # R PCC
  14,  # L tpole
  28   # R tpole
)
snames <- c("R vATL", "L PHC", "L RSC", "R RSC", 
             "L tpole", "R tpole")
runtypes<- c("Questions", "NoQuestions")
conds   <- c("bio", "phys")
region  <- "overlap_peaks_n41"


###
# Run

cat("run\n")

base    <- "/mnt/nfs/psych/faceMemoryMRI"
dat <- llply(runtypes, function(runtype) {
  cat("Runtype:", runtype, "\n")
  # Paths
  sdirs   <- file.path(base, "analysis/subjects", subjects, runtype)
  tdirs   <- file.path(sdirs, "connectivity/task_residuals.reml")
  
  # Get the time-series
  lst.tsmats <- llply(conds, function(cond) {
    cat("- Condition:", cond, "\n")
    
    # Get the names of all the time-series files for this condition
    tsfiles   <- file.path(tdirs, sprintf("ts_%s_%s.1D", region, cond))
  
    lst.ts <- llply(tsfiles, function(tsfile) {
      # Read in the time-series file
      # but only keep the ROIs of especial interest
      ts.mat    <- as.matrix(read.table(tsfile))
      ts.mat    <- ts.mat[,srois]
      colnames(ts.mat) <- snames
      ts.mat
    }, .parallel=T)
    names(lst.ts) <- subjects
    
    lst.ts
  })
  names(lst.tsmats) <- conds
  
  lst.tsmats
})
names(dat) <- runtypes
# dat$Questions$bio$tb9226


###
# Save

cat("saving\n")
save(dat, file="../data/ts_rois_selectoverlap.rda")
