#!/usr/bin/env Rscript

# This script will concatenate the localizer data for each subject
# and take the top spatial eigenvectors as a dimensionality reduction
# step. It uses the MIGP approach of Smith et al., 2014

# Here we include the task effects in our parcellation.


#--- SETUP ---#

cat("Setup\n")

suppressMessages(library(niftir))
library(biganalytics)

# Get the paths in standard space
base_dir    <- "/mnt/nfs/psych/faceMemoryMRI/analysis/subjects"
subjects    <- list.files(base_dir)
select_subs <- file.exists(file.path(base_dir, subjects, "Localizer/reg_standard/filtered_func_data.nii.gz"))
data_dirs   <- file.path(base_dir, subjects, "Localizer", "reg_standard")[select_subs]
func_files  <- file.path(data_dirs, "filtered_func_data.nii.gz")

outdir      <- "/mnt/nfs/psych/faceMemoryMRI/analysis/groups/Localizer/parcels_migp"
if (!file.exists(outdir)) dir.create(outdir)

mask_file   <- file.path(outdir, "group_mask.nii.gz")
grp_mask    <- read.mask(mask_file)


#--- MIGP ---#

cat("MIGP\n")

setwd("/data/psych/faceMemoryMRI/scripts/connpaper/30_parcel")
source("functions/temporal_concatenation.R")

# Concatenate files and apply data reduction using the MIGP
func_migp <- migp_files(func_files, grp_mask, scale=TRUE)

# Save the file
hdr       <- read.nifti.header(func_files[1])
write.nifti(t(func_migp), hdr, grp_mask, outfile=file.path(outdir, "group_migp_localizer.nii.gz"), overwrite=T)
