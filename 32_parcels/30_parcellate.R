#!/usr/bin/env Rscript

# This script will use the temporally concatenated and data reduced
# localizer data and run the parcellation scheme on that data

#--- SETUP ---#

cat("Setup\n")

# Load all the region growing shiz
source("/mnt/nfs/psych/rparcellate/command/lib/region_growing.R")
#source("functions/region_growing.R")

# Masks for each hemisphere
prior_file  <- "/mnt/nfs/psych/rparcellate/rois/ho_maxprob25.nii.gz"

# Basics
basedir     <- "/mnt/nfs/psych/faceMemoryMRI/analysis/groups/Localizer/parcels_migp"

# Paths to the data
func_file   <- file.path(basedir, "group_migp_localizer.nii.gz")
mask_file   <- file.path(basedir, "group_mask.nii.gz")


#--- PARCELLATE ---#

cat("Parcellate\n")
outdir      <- file.path(basedir, "group_region_growing")
if (file.exists(outdir)) system(sprintf("rm -r %s", outdir))
if (!file.exists(outdir)) dir.create(outdir)
parcels     <- region_growing_wrapper(func_file, mask_file, prior_file, outdir=outdir, roi.scale=10000)
