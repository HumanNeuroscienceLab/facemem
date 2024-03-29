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
# srois <- c(
#   3,  # R OFA
#   1,  # R FFA
#   69, # R vATL
#   8,  # L OFA
#   2,  # L FFA
#   62  # L vATL
# )
# snames  <- c("R OFA", "R FFA", "R vATL", 
#              "L OFA", "L FFA", "L vATL")
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
save(dat, file="../data/ts_rois_ofa+ffa+vatl.rda")
