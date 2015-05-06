#!/usr/bin/env Rscript

# This will split the voxelwise time-series into bio and phys
# It will make use of the residual time-series from the task-based analysis

suppressMessages(library(niftir))


#--- FUNCTIONS ---#

read_data <- function(subject, runtype) {
  # Get the timing file
  timing_fname  <- sprintf("%s/r_faceMemory01_%s_%s.csv", timingdir, subject, runtype)
  timing        <- read.csv(timing_fname)

  # Read in the data
  ## paths
  ddir          <- file.path(datadir, subject, runtype)
  tdir          <- file.path(ddir, "connectivity/task_residuals.reml")
  func_file     <- file.path(tdir, "residuals.nii.gz")
  #func_file     <- file.path(ddir, "filtered_func_0mm_data.nii.gz")
  mask_file     <- file.path(ddir, "mask.nii.gz")
  ## read
  hdr           <- read.nifti.header(func_file)
  mask          <- read.mask(mask_file)
  func          <- read.big.nifti(func_file)
  func          <- deepcopy(func, cols=mask)
  
  list(timing=timing, hdr=hdr, mask=mask, func=func)
}

# Splits data into bio/phys
split_data_into_conditions <- function(dat, timing, relative.onset=0, tr=1, shift=2) {
  # Divide this based on each condition
  conditions      <- levels(timing$condition)
  nconditions     <- length(conditions)
  nregions        <- ncol(dat)
  tot.tpts        <- nrow(dat)
  ntrials         <- nrow(timing)
  
  # Get the timepoints for each individual trial
  onsets       <- round(timing$onset/tr) + relative.onset + 1 + shift # all in time-points
  offsets      <- round(timing$onset/tr) + floor(timing$duration/tr) + 1 + shift
  
  # For trials at the end of runs, make sure offset isn't greater than duration
  orig.offsets    <- offsets
  last.trial.inds <- c(diff(timing$run)==1,TRUE)
  last.trial.offsets <- round(timing$onset[last.trial.inds]/tr) + 
    round(timing$duration[last.trial.inds]/tr) + 1 - 1
  offsets[last.trial.inds] <- last.trial.offsets
  
  # Compile trial time-points
  lst_trial_tpts <- llply(1:ntrials, function(i) {
    onsets[i]:offsets[i]
  })
  
  # Now combine the data based on each of the conditions
  lst_cond_dat <- llply(conditions, function(cond) {
    trial_inds <- which(as.character(timing$condition) == cond)
    tpts <- unlist(lst_trial_tpts[trial_inds])
    deepcopy(dat, rows=tpts)
  })
  names(lst_cond_dat) <- conditions
  
  ## Finally create a dataframe with information concerning each time-point
  #lst_cond_info <- llply(conditions, function(cond) {
  #  trial_inds <- which(as.character(timing$condition) == cond)
  #  ldply(trial_inds, function(tind) {
  #    trial.info <- timing[tind,]
  #    tpts <- lst_trial_tpts[[tind]]
  #    ntpts <- length(tpts)
  #    data.frame(
  #      tpt = as.integer(tpts), 
  #      run = as.integer(trial.info$run), 
  #      trial = as.integer(trial.info$trial), 
  #      condition = as.character(trial.info$condition), 
  #      onset = as.numeric(trial.info$onset), 
  #      duration = as.numeric(trial.info$duration), 
  #      per.run.onset = as.numeric(trial.info$per.run.onset)
  #    )
  #  })
  #})
  #names(lst_cond_info) <- conditions
  #
  #list(info=lst_cond_info, dat=lst_cond_dat)
  
  list(info=NULL, dat=lst_cond_dat)
}


#--- SETUP ---#

library(plyr)

# Paths and Settings
datadir   <- "/mnt/nfs/psych/faceMemoryMRI/analysis/subjects"
timingdir <- "/mnt/nfs/psych/faceMemoryMRI/scripts/timing"

subjects  <- as.character(as.matrix(read.table("../sublist_all.txt")))
runtypes  <- c("Questions", "NoQuestions") # for now
opts      <- expand.grid(list(subject=subjects, runtype=runtypes))

conditions<- c("bio", "phys")

nforks    <- 4 # for doMC

library(doMC)
registerDoMC(nforks)
cat(sprintf("using %i forks\n", nforks))


#--- run ---#

foreach(i=1:nrow(opts)) %dopar% {
  row <- opts[i,]
  ac <- as.character
  an <- as.numeric
  cat(ac(row$subject), "-", ac(row$runtype), "\n")
  
  cat("Read\n")
  res         <- read_data(ac(row$subject), ac(row$runtype))
  
  cat("Split\n")
  split_conds <- split_data_into_conditions(res$func, res$timing)
    
  # split up stuff for ease
  split.info  <- split_conds$info
  split.dat   <- split_conds$dat
  
  cat("Save\n")
  outdir      <- file.path(datadir, ac(row$subject), ac(row$runtype), "connectivity/task_residuals.reml")
  if (!file.exists(outdir)) dir.create(outdir)
  for (cond in conditions) {
    #outfile1  <- file.path(outdir, sprintf("split_fwhm5_concat_info_%s.csv", cond))
    #cat("...saving", outfile1, "\n")
    #write.csv(split.info[[cond]], file=outfile1, row.names=F)
  
    outfile2  <- file.path(outdir, sprintf("residuals_%s.nii.gz", cond))
    #outfile2  <- file.path(outdir, sprintf("filtered_func_0mm_%s.nii.gz", cond))
    cat("...saving", outfile2, "\n")
    res$hdr$dim[4] <- nrow(split.dat[[cond]])
    bm4d <- as.big.nifti4d(split.dat[[cond]], res$hdr, res$mask)
    write.nifti(bm4d, outfile=outfile2, overwrite=T)
    system(sprintf("3dcalc -overwrite -a %s -expr a -prefix %s", outfile2, outfile2))
  }
}
