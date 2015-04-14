#!/usr/bin/env Rscript

###
# Setup / Functions
###

library(stringr)
library(plyr)

read_stim_info <- function(fname) {
  # Get lines to actually read
  lines <- readLines(fname)
  ## get counterbalancing
  li    <- grep("Counterbalance", lines)
  len   <- str_length(lines[[li]])
  counterbalance <- substr(lines[[li]], len, len)
  counterbalance <- as.integer(counterbalance)
  ## get the start and # of lines to read
  start_li  <- grep("^Subject", lines) 
  nlines    <- which(lines[11:length(lines)]=="") - 1

  # Read in the lines from table
  orig_dat  <- read.table(fname, header=T, skip=start_li-1, nrows=nlines-1)
  ## get relevant columns
  stim_dat  <- subset(orig_dat, select=c("Subject", "RunNum", "RunType", "Trial", "StimID", "Type", "Quest.", "StimOnset", "Resp", "RT"))
  ## rename columns
  stim_dat  <- rename(stim_dat, c("RunNum"="Run", "Quest."="Question", "StimOnset"="Onset"))
  ## flip run and runtype
  stim_dat[,c(2,3)] <- stim_dat[,c(3,2)]
  names(stim_dat)[c(2,3)] <- c("RunType", "Run")
  
  stim_dat
}


###
# Paths
###

indir   <- '/mnt/nfs/share/Dropbox/ExpControl_Current/fMRI/FaceMemory_MRI'
outdir  <- '/mnt/nfs/psych/faceMemoryMRI/scripts/timing'

infiles <- list.files(indir, pattern="^facememory01_MRI_tb.*[0-9][.]log$")
## remove extra empty files
rmfiles <- c("facememory01_MRI_tb9360_01_NoQuestions_07Aug2014_14_21_10.log", "facememory01_MRI_tb9276_04_NoQuestions_21Jul2014_16_6_17.log", "facememory01_MRI_tb9276_04_NoQuestions_21Jul2014_16_7_29.log", "facememory01_MRI_tb9585_02_Questions_25Sep2014_14_43_34.log")
bad_inds<- infiles %in% rmfiles
infiles <- infiles[!bad_inds]
if (length(infiles) != (16*2*4-1)) stop("must have 127 files")

infpaths <- file.path(indir, infiles)


###
# Read
###

# For everything
stim_df <- ldply(infpaths, read_stim_info, .progress="text")
stim_df <- with(stim_df, stim_df[order(Subject, RunType, Run, Trial),])
write.csv(stim_df, row.names=F, file=file.path(outdir, "all_subjs_info_and_timing.csv"))

# Separate each subject
d_ply(stim_df, .(Subject, RunType), function(x) {
  subj  <- as.character(x$Subject[1])
  rtype <- as.character(x$RunType[1])
  write.csv(x, row.names=F, file=file.path(outdir, sprintf("all_%s_%s_info_and_timing.csv", subj, rtype)))
}, .progress="text")

