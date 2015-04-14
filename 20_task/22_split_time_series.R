#!/usr/bin/env Rscript

# This script will split the averaged parcel time-series by condition (bio vs phys)

suppressMessages(library(niftir))


#--- FUNCTIONS ---#

read_data <- function(subject, runtype, fname) {
  # Get the timing file
  timing_fname  <- sprintf("%s/r_faceMemory01_%s_%s.csv", timingdir, subject, runtype)
  timing        <- read.csv(timing_fname)

  # Read in the data
  ## paths
  ts_dir        <- file.path(datadir, subject, runtype, "preproc")
  ts_file       <- file.path(ts_dir, paste(fname, ".nii.gz", sep=""))
  mask_file     <- file.path(ts_dir, "mask.nii.gz")
  ## read
  hdr           <- read.nifti.header(ts_file)
  mask          <- read.mask(mask_file)
  dat           <- read.big.nifti(ts_file, shared=FALSE)
  mdat          <- deepcopy(dat, cols=mask, shared=FALSE)
  rm(dat); gc(F,T)
  
  list(timing=timing, dat=mdat, hdr=hdr, mask=mask)
}

# Splits data into bio/phys
split_data_into_conditions <- function(dat, timing, relative.onset=0, tr=1) {
  # Divide this based on each condition
  conditions      <- levels(timing$condition)
  nconditions     <- length(conditions)
  nregions        <- ncol(dat)
  tot.tpts        <- nrow(dat)
  ntrials         <- nrow(timing)
  
  # Get the timepoints for each individual trial
  lst_trial_tpts <- llply(1:ntrials, function(i) {
    trial.info  <- timing[i,]
    onset       <- round(trial.info$onset) + relative.onset
    offset      <- round(trial.info$onset) + floor(trial.info$duration)
    onset:offset
  })
  
  # Now combine the data based on each of the conditions
  lst_cond_dat <- llply(conditions, function(cond) {
    trial_inds <- which(as.character(timing$condition) == cond)
    tpts <- unlist(lst_trial_tpts[trial_inds])
    deepcopy(dat, rows=tpts, shared=FALSE)
  })
  names(lst_cond_dat) <- conditions
  
  # Finally create a dataframe with information concerning each time-point
  lst_cond_info <- llply(conditions, function(cond) {
    trial_inds <- which(as.character(timing$condition) == cond)
    ldply(trial_inds, function(tind) {
      trial.info <- timing[tind,]
      tpts <- lst_trial_tpts[[tind]]
      ntpts <- length(tpts)
      data.frame(
        tpt = as.integer(tpts), 
        run = as.integer(trial.info$run), 
        trial = as.integer(trial.info$trial), 
        condition = as.character(trial.info$condition), 
        onset = as.numeric(trial.info$onset), 
        duration = as.numeric(trial.info$duration), 
        per.run.onset = as.numeric(trial.info$per.run.onset)
      )
    })
  })
  names(lst_cond_info) <- conditions
  
  list(info=lst_cond_info, dat=lst_cond_dat)
}


#--- SETUP ---#

library(plyr)

# Paths and Settings
datadir   <- "/mnt/nfs/psych/faceMemoryMRI/analysis/subjects"
timingdir <- "/mnt/nfs/psych/faceMemoryMRI/scripts/timing"

subjects <- as.character(as.matrix(read.table("../sublist_all.txt")))
runtypes <- c("Questions") # for now
#fnames   <- c("func_concat")
#fnames   <- c("func_concat_mc")
#fnames   <- c("func_concat_mc_compcor_top5", "func_concat_mc_compcor_sim")
fnames   <- c("func_concat", "func_concat_mc", "func_concat_mc_compcor_top5", "func_concat_mc_compcor_sim")
opts     <- expand.grid(list(subject=subjects, runtype=runtypes, fname=fnames))
print(opts)

conditions<- c("bio", "phys")

nforks   <- 8 # for doMC

library(doMC)
registerDoMC(nforks)
cat(sprintf("using %i forks\n", nforks))


#--- run ---#

#nrow(opts)
foreach(i=1:nrow(opts)) %dopar% {
  row <- opts[i,]
  ac <- as.character
  an <- as.numeric
  cat(ac(row$subject), "-", ac(row$runtype), ac(row$fname), "\n")
  
  cat("Read\n")
  res         <- read_data(ac(row$subject), ac(row$runtype), ac(row$fname))
  # header and mask
  hdr         <- res$hdr
  mask        <- res$mask
  
  cat("Split\n")
  split_conds <- split_data_into_conditions(res$dat, res$timing)
  # clean up
  rm(res); gc(F,T)
  # split up stuff for ease
  split.info  <- split_conds$info
  split.dat   <- split_conds$dat
  
  cat("Save\n")
  outdir      <- file.path(datadir, ac(row$subject), ac(row$runtype), "preproc", "split_ts")
  if (!file.exists(outdir)) dir.create(outdir)
  for (cond in conditions) {
    #outfile1  <- file.path(outdir, sprintf("%s_%s_info.csv", fname, cond))
    #cat("...saving", outfile1, "\n")
    #write.csv(split.info[[cond]], file=outfile1, row.names=F)
    
    outfile2  <- file.path(outdir, sprintf("%s_%s.nii.gz", ac(row$fname), cond))
    cat("...saving", outfile2, "\n")
    hdr$dim[4] <- nrow(split.dat[[cond]])
    nii4d <- as.big.nifti4d(split.dat[[cond]], hdr, mask)
    write.nifti(nii4d, outfile=outfile2, overwrite=T)
    rm(nii4d); gc(F,T)
  }
  
  rm(split.dat, split.info); gc(F,T)
}

