#!/usr/bin/env Rscript

# Transforms the concatenated functional data into standard space
# Also does the same to the brain mask
# Creates a new brain mask?


#--- SETUP ---#

cat("Setup\n")

suppressMessages(library(niftir))
library(biganalytics)

library(doMC)
registerDoMC(8)

# Get the paths
base_dir    <- "/mnt/nfs/psych/faceMemoryMRI/analysis/subjects"
subjects    <- list.files(base_dir)
runtypes    <- c("Localizer")


#--- REGISTER ---#

cat("\n")

l_ply(runtypes, function(runtype) {
  cat(runtype, "\n")

  select_subs <- file.exists(file.path(base_dir, subjects, runtype, "filtered_func_data.nii.gz"))
  data_dirs   <- file.path(base_dir, subjects, runtype)[select_subs]

  n           <- length(data_dirs)
  func_files  <- file.path(data_dirs, "filtered_func_data.nii.gz")
  mask_files  <- file.path(data_dirs, "mask.nii.gz")
  reg_dirs    <- file.path(data_dirs, "reg")
  
  out_dirs    <- file.path(data_dirs, "reg_standard")
  ofunc_files <- file.path(out_dirs, "filtered_func_data.nii.gz")
  omask_files <- file.path(out_dirs, "mask.nii.gz")
  
  l_ply(1:n, function(i) {
    cat("subject:", subjects[i], "\n")
    
    if(!file.exists(out_dirs[i])) dir.create(out_dirs[i])
    
    # Transform functional data
    cmd <- "gen_applywarp.rb -i %s --reg %s -w 'exfunc-to-standard' -o %s --interp spline --float"
    cmd <- sprintf(cmd, func_files[i], reg_dirs[i], ofunc_files[i])
    cat(cmd, "\n")
    system(cmd)
    
    # Transform the brain mask
    cmd <- "gen_applywarp.rb -i %s --reg %s -w 'exfunc-to-standard' -o %s --interp nn --short"
    cmd <- sprintf(cmd, mask_files[i], reg_dirs[i], omask_files[i])
    cat(cmd, "\n")
    system(cmd)
    
    # Resave the brain mask
    cmd <- "fslmaths %s -mas %s -Tmin -bin %s"
    cmd <- sprintf(cmd, ofunc_files[i], omask_files[i], omask_files[i])
    cat(cmd, "\n")
    system(cmd)    
  }, .parallel=TRUE)
}, .parallel=FALSE)


#--- REGISTER ONLY MASKS ---#

cat("\n")
# For all other runtypes, just register the mask here

runtypes <- c("Questions", "NoQuestions")

l_ply(runtypes, function(runtype) {
  cat(runtype, "\n")

  select_subs <- file.exists(file.path(base_dir, subjects, runtype, "filtered_func_data.nii.gz"))
  data_dirs   <- file.path(base_dir, subjects, runtype)[select_subs]

  n           <- length(data_dirs)
  func_files  <- file.path(data_dirs, "filtered_func_data.nii.gz")
  mask_files  <- file.path(data_dirs, "mask.nii.gz")
  reg_dirs    <- file.path(data_dirs, "reg")
  
  out_dirs    <- file.path(data_dirs, "reg_standard")
  ofunc_files <- file.path(out_dirs, "filtered_func_data.nii.gz")
  omask_files <- file.path(out_dirs, "mask.nii.gz")
  
  l_ply(1:n, function(i) {
    cat("subject:", subjects[i], "\n")
    
    if(!file.exists(out_dirs[i])) dir.create(out_dirs[i])
    
    # Create the min mask
    min_mask <- file.path(data_dirs[i], "mask_min.nii.gz")
    cmd <- "fslmaths %s -mas %s -Tmin -bin %s"
    cmd <- sprintf(cmd, func_files[i], mask_files[i], min_mask)
    cat(cmd, "\n")
    system(cmd)
    
    # Transform the min brain mask
    omin_mask <- file.path(out_dirs[i], "mask_min.nii.gz")
    cmd <- "gen_applywarp.rb -i %s --reg %s -w 'exfunc-to-standard' -o %s --interp nn --short"
    cmd <- sprintf(cmd, min_mask, reg_dirs[i], omin_mask)
    cat(cmd, "\n")
    system(cmd)
    
    # Transform the regular brain mask
    cmd <- "gen_applywarp.rb -i %s --reg %s -w 'exfunc-to-standard' -o %s --interp nn --short"
    cmd <- sprintf(cmd, mask_files[i], reg_dirs[i], omask_files[i])
    cat(cmd, "\n")
    system(cmd)
    
    # Resave the brain mask
    cmd <- "fslmaths %s -mas %s %s"
    cmd <- sprintf(cmd, omask_files[i], omin_mask, omask_files[i])
    cat(cmd, "\n")
    system(cmd)
  }, .parallel=TRUE)
}, .parallel=FALSE)

