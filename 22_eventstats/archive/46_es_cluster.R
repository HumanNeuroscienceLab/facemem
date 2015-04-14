#!/usr/bin/env Rscript

#--- SETUP ---#

cat("Setup\n")

suppressMessages(library(niftir))
library(biganalytics)

library(doMC)
registerDoMC(12)

# Get the paths
base_dir    <- "/mnt/nfs/psych/faceMemoryMRI/analysis/subjects"
subjects    <- list.files(base_dir)
#runtypes    <- c("Questions", "NoQuestions")
runtype     <- "Questions"

grp_dir     <- "/mnt/nfs/psych/faceMemoryMRI/analysis/groups"
outdir      <- file.path(grp_dir, runtype, "task", "eventstats_cluster_01")
if (!file.exists(outdir)) dir.create(outdir)


#--- FUNCTIONS ---#

tconcat <- function(Y, parallel=T) {
  require(plyr)
  
  s <- length(Y)                # number of subjects
  
  # collapse all the subjects together and scale each
  tens <- max(1, round(s*0.1))
  Z <- laply(1:s, function(i) {
    if(!(i%%tens)) cat(round(i/s,2)*100, "%..", sep="")
    scale(Y[[i]])
  }, .parallel=parallel)
  cat("\n")
  
  # resize
  dim(Z) <- c(dim(Z)[1]*dim(Z)[2], dim(Z)[3])
  
  return(Z)
}


#--- MASK ---#

# 1. Do the group masking and save

## Copy the group mask from the task-based results
#grp_masks <- Sys.glob(file.path(grp_dir, "*", "task", "*_task.mema", "mask.nii.gz"))
mask_file   <- Sys.glob(file.path(grp_dir, runtype, "task", "*_task.mema", "mask.nii.gz"))
grp_mask    <- read.mask(mask_file)

## Get the harvard-oxford mask and use it as a prior
prior_file  <- "/mnt/nfs/psych/rparcellate/rois/ho_maxprob25.nii.gz"
prior_mask  <- read.mask(prior_file)

## Combine the two and save them!!!
hdr         <- read.nifti.header(mask_file)
mask        <- grp_mask & prior_mask
write.nifti(mask, hdr, outfile=file.path(outdir, "group_mask.nii.gz"), overwrite=T)


#--- TEMPORALLY CONCATENATE ---#

# 2. Then temporally concatenate and save

## get all the eventstat files
bio_files   <- file.path(base_dir, subjects, runtype, "task/eventstats_01", "es_standardized_bio_avg_percent.nii.gz")
phys_files  <- file.path(base_dir, subjects, runtype, "task/eventstats_01", "es_standardized_phys_avg_percent.nii.gz")
files       <- c(bio_files, phys_files)

## load all the data
Ys          <- llply(files, function(fn) {
  img <- read.big.nifti(fn)
  img <- deepcopy(img, cols=mask)
  as.matrix(img)
}, .progress="text")

## temporally concatenate
dat         <- tconcat(Ys)

## save
hdr         <- read.nifti.header(files[1])
hdr$dim[4]  <- nrow(dat)
write.nifti(t(dat), hdr, mask, outfile=file.path(outdir, "group_tconcat.nii.gz"), overwrite=T)

## clean
rm(Ys); gc(F,T)
rm(dat); gc(F,T)


#--- PARCELLATE ---#

# Load all the region growing shiz
source("/mnt/nfs/psych/rparcellate/command/lib/region_growing.R")

# Paths to the data
func_file   <- file.path(outdir, "group_tconcat.nii.gz")
mask_file   <- file.path(outdir, "group_mask.nii.gz")

# Run
outdir2     <- file.path(outdir, "region_growing")
if (file.exists(outdir2)) system(sprintf("rm -r %s", outdir2))
if (!file.exists(outdir2)) dir.create(outdir2)
parcels     <- region_growing_wrapper(func_file, mask_file, prior_file, outdir=outdir2, roi.scale=10000)
