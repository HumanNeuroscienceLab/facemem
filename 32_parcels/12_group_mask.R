#!/usr/bin/env Rscript

# This script will concatenate the localizer data for each subject
# and take the top spatial eigenvectors as a dimensionality reduction
# step. It uses the MIGP approach of Smith et al., 2014

# Here we include the task effects in our parcellation.


#--- SETUP ---#

cat("Setup\n")

suppressMessages(library(niftir))
library(biganalytics)

library(doMC)
registerDoMC(6)

# Get the paths
base_dir    <- "/mnt/nfs/psych/faceMemoryMRI/analysis/subjects"
subjects    <- list.files(base_dir)
runtypes    <- c("Localizer", "Questions", "NoQuestions")

outdir      <- "/mnt/nfs/psych/faceMemoryMRI/analysis/groups/Localizer/parcels_migp"
if (!file.exists(outdir)) dir.create(outdir)


#--- GROUP MASK ---#

cat("Group Mask\n")

# Get all the mask files
templ_path  <- file.path(base_dir, subjects, "*", "reg_standard", "mask.nii.gz")
mask_files  <- Sys.glob(templ_path)

# We want to constrain the group mask by our prior
prior_file  <- "/mnt/nfs/psych/rparcellate/rois/ho_maxprob25.nii.gz"
grp_mask    <- read.mask(prior_file)

# Read in all the subject masks
sub_masks   <- laply(mask_files, read.mask, .parallel=FALSE, .progress="text")

# Get the percent overlap
perc_overlap<- colMeans(sub_masks)

# Get the 100% overlap
overlap     <- perc_overlap == 1

# Combine with group mask
grp_mask    <- grp_mask & overlap

# Save the mask and percent overlap
hdr         <- read.nifti.header(mask_files[1])
write.nifti(grp_mask, hdr, outfile=file.path(outdir, "group_mask.nii.gz"), overwrite=T)
write.nifti(perc_overlap, hdr, outfile=file.path(outdir, "percent_overlap.nii.gz"), overwrite=T)
