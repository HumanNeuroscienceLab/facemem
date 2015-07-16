#!/usr/bin/env Rscript

# Here we compare the brain activity for Bio > Phys btw the Q and PV conditions
# Specifically, we compute the correlation (unthresholded) and dice (thresholded)

###
# SETUP
###

library(plyr)
suppressMessages(library(niftir))

base <- "/mnt/nfs/psych/faceMemoryMRI"
adir <- file.path(base, "analysis/groups")
runtypes <- c("Questions", "NoQuestions")

s <- sprintf
fp <- file.path

indirs <- sapply(runtypes, function(runtype) fp(adir, runtype, "task", s("%s_task_smoother.mema", tolower(runtype))))
file.exists(indirs)

dice <- function(a,b) (2*sum(a&b))/sum(a+b)
other <- function(a,b) (2*sum(a&b))/sum(a+b)


###
# LOAD DATA
###

# Load the masks
# and get the overlap mask across two tasks
masks <- sapply(indirs, function(indir) read.mask(fp(indir, "mask.nii.gz")))
mask  <- rowSums(masks)==2
fgmask<- read.mask(fp(adir, "mni152/freesurfer/aparc_2mm/lh_fusiform_dil.nii.gz"))

# Load the data

## unthresholded
raw.dat <- sapply(indirs, function(indir) {
  read.nifti.image(fp(indir, "zstats_bio_gt_phys.nii.gz"))[mask]
})

## thresholded
thr.dat <- sapply(indirs, function(indir) {
  read.nifti.image(fp(indir, "easythresh/thresh_zstat_bio_gt_phys.nii.gz"))[mask]
})

## unthresholded only in left fusiform
raw.dat2 <- sapply(indirs, function(indir) {
  read.nifti.image(fp(indir, "zstats_bio_gt_phys.nii.gz"))[(mask&fgmask)]
})



###
# COMPARISONS
###

cor(raw.dat, method="s")[1,2]
cor(raw.dat2, method="s")[1,2]

cor(thr.dat, method="s")[1,2]
dice(thr.dat[,1]!=0, thr.dat[,2]!=0)
other(thr.dat[,1]!=0, thr.dat[,2]!=0)
