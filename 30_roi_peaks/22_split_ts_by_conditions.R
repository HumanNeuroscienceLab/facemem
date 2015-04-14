#!/usr/bin/env Rscript

# This script will split the averaged parcel time-series by condition (bio / phys)


#--- FUNCTIONS ---#

read_data <- function(subject, runtype, roiname) {
  # Get the timing file
  timing_fname  <- sprintf("%s/r_faceMemory01_%s_%s.csv", timingdir, subject, runtype)
  timing        <- read.csv(timing_fname)

  # Read in the data
  ts_dir        <- file.path(datadir, subject, runtype, "ts")
  ts_file       <- file.path(ts_dir, sprintf("%s_n%02i.1D", roiname, nrois))
  dat           <- as.matrix(read.table(ts_file))
    
  list(timing=timing, dat=dat)
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
    dat[tpts,]
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

nrois     <- 59

# Paths and Settings
datadir   <- "/mnt/nfs/psych/faceMemoryMRI/analysis/subjects"
timingdir <- "/mnt/nfs/psych/faceMemoryMRI/scripts/timing"

subjects <- as.character(as.matrix(read.table("../sublist_all.txt")))
runtypes <- c("Questions", "NoQuestions") # for now
opts     <- expand.grid(list(subject=subjects, runtype=runtypes))

conditions<- c("bio", "phys")

roiname   <- "task_pos_peaks"

nforks   <- 8 # for doMC

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
  res         <- read_data(ac(row$subject), ac(row$runtype), roiname)
  
  cat("Split\n")
  split_conds <- split_data_into_conditions(res$dat, res$timing)
    
  # split up stuff for ease
  split.info  <- split_conds$info
  split.dat   <- split_conds$dat
  
  cat("Save\n")
  outdir      <- file.path(datadir, ac(row$subject), ac(row$runtype), "ts")
  for (cond in conditions) {
    outfile1  <- file.path(outdir, sprintf("%s_n%02i_%s_info.csv", roiname, nrois, cond))
    cat("...saving", outfile1, "\n")
    write.csv(split.info[[cond]], file=outfile1, row.names=F)
  
    outfile2  <- file.path(outdir, sprintf("%s_n%02i_%s.1D", roiname, nrois, cond))
    cat("...saving", outfile2, "\n")
    write.table(split.dat[[cond]], file=outfile2, row.names=F, col.names=F, quote=F)
  }
}
