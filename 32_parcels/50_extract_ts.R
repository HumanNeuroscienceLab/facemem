#!/usr/bin/env Rscript

# This script will extract the time-series from each participant and average it.

#--- SETUP ---#

cat("Setup\n")

#suppressMessages(library(niftir))

suppressMessages(library(niftir))
library(plyr)

# Use old ANFI
afni_dir <- "/mnt/nfs/share/afni/current"
Sys.setenv(PATH=paste(afni_dir, Sys.getenv("PATH"), sep=":"))
if (system("which afni", intern=T) != file.path(afni_dir, "afni")) {
  stop("couldn't find afni path")
}

# Set threads/forks
library(doMC)
registerDoMC(8)
Sys.setenv(OMP_NUM_THREADS=4)

# Get the paths
base_dir    <- "/mnt/nfs/psych/faceMemoryMRI/analysis/subjects"
subjects    <- list.files(base_dir)
runtypes    <- c("Questions", "NoQuestions")
#subjects    <- as.character(as.matrix(read.table("../sublist_localizer.txt")))
#runtypes    <- c("Localizer")

roi_dir     <- "/mnt/nfs/psych/faceMemoryMRI/analysis/groups/Localizer/parcels_migp"
mask_file   <- file.path(roi_dir, "group_mask.nii.gz")
roi_file    <- file.path(roi_dir, "group_region_growing/parcels_relabel.nii.gz")

# Load the mask/rois to get a count of the # of ROIs
mask        <- read.mask(mask_file)
rois        <- read.mask(roi_file, NULL)[mask]
nrois       <- length(unique(rois))


#--- TRANSFORM PARCELS ---#

cat("Transform Parcels to Functional Space\n")

# I want to have a list of the reg folders
sub_reg_dirs  <- file.path(base_dir, subjects, "anat", "reg")
if (any(!file.exists(sub_reg_dirs))) stop("some reg inputs don't exist")

# I want to take as input the ROI and the transforms for the subject
l_ply(1:length(subjects), function(si) {
  cat("subject:", subjects[si], "\n")
  subject <- subjects[si]
  
  l_ply(runtypes, function(runtype) {
    cat("...", runtype, "\n", sep="")
    
    # inputs
    sub_roi_dir   <- file.path(base_dir, subject, runtype, "rois")
    sub_reg_dir   <- file.path(base_dir, subject, runtype, "reg")
    sub_mask_file <- file.path(base_dir, subject, runtype, "mask.nii.gz")
    
    # output
    sub_roi_file  <- file.path(sub_roi_dir, sprintf("parcels_group_localizer_n%04i.nii.gz", nrois))
    if (file.exists(sub_roi_file)) {
      cat("...output", sub_roi_file, "already exists, skipping\n")
    } else {
      if (!file.exists(sub_roi_dir)) dir.create(sub_roi_dir)
      
      # run
      cmd <- "gen_applywarp.rb -i %s -r %s -w 'standard-to-exfunc' -o %s --interp nn --short"
      cmd <- sprintf(cmd, roi_file, sub_reg_dir, sub_roi_file)
      cat(cmd, "\n")
      system(cmd)
      
      # mask
      cmd <- "fslmaths %s -mas %s %s"
      cmd <- sprintf(cmd, sub_roi_file, sub_mask_file, sub_roi_file)
      cat(cmd, "\n")
      system(cmd)
    }
  })
}, .parallel=TRUE)


#--- EXTRACT ---#

cat("Extract TS\n")

l_ply(runtypes, function(runtype) {
  cat("RUNTYPE:", runtype, "\n")
  
  # I want the functional files
  data_dirs     <- file.path(base_dir, subjects, runtype)
  func_files    <- file.path(data_dirs, "filtered_func_0mm_data.nii.gz")
  if (any(!file.exists(func_files))) stop("some func inputs don't exist")
  
  # I want the ROI files
  sub_roi_dirs  <- file.path(base_dir, subjects, runtype, "rois")
  sub_roi_files <- file.path(sub_roi_dirs, sprintf("parcels_group_localizer_n%04i.nii.gz", nrois))
  
  # I want the output ts files
  ts_dirs       <- file.path(base_dir, subjects, runtype, "ts")
  out_files     <- file.path(ts_dirs, sprintf("parcels_group_localizer_n%04i.1D", nrois))
  
  l_ply(1:length(subjects), function(si) {
    cat("...", subjects[si], "\n")
    
    if (!file.exists(ts_dirs[si])) dir.create(ts_dirs[si])
    
    cmd <- "3dROIstats -mask %s -quiet %s > %s"
    cmd <- sprintf(cmd, sub_roi_files[si], func_files[si], out_files[si])
    cat(cmd, "\n")
    system(cmd)
  }, .parallel=TRUE)
  
  cat("\n")
})



# check
ret <- llply(runtypes, function(runtype) {
  
  laply(subjects, function(subject) {
    ts_dir <- file.path(base_dir, subject, runtype, "ts")
    ts_file <- file.path(ts_dir, sprintf("parcels_group_localizer_n%04i.1D", nrois))
    
    cmd <- sprintf("head -n 1 %s | wc -w", ts_file)
    cat(cmd, "\n")
    system(cmd, intern=T)
  }, .parallel=T)
  
})
cat("check - should be all", nrois, "\n")
print(ret)
all(as.integer(unlist(ret)) == nrois)
