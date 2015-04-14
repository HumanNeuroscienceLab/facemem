#!/usr/bin/env Rscript

# Fits the bio and phys coefficients to the data
# Saves the single fitted time-series for each voxel

###
# USER ARGS
###

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) stop("usage: $0 subject runtype")
subject <- args[1]
runtype <- args[2]


###
# PATHS
###

base <- "/mnt/nfs/psych/faceMemoryMRI/analysis/subjects"
sdir <- file.path(base, subject, runtype)
idir <- file.path(sdir, "task/latency_analysis_p2.reml")


###
# FUNCTIONS
###

suppressMessages(library(niftir))

xmat_labs <- function(fn) {
  str <- system(sprintf("grep ColumnLabels %s | sed s/'#  ColumnLabels = '//", fn), intern=T)
  str <- gsub("\"", "", str)
  cols <- strsplit(str, ' ; ')[[1]]
  cols
}


###
# PROCESS
###

setwd(idir)

cat("Read in the regressors\n")
clabs <- xmat_labs("xmat.1D")
xmat  <- as.matrix(read.table("xmat.1D"))
rxmat <- xmat[,grep("bio|phys",clabs)] # keep only the main task regressors

cat("Read in the betas\n")
## bio
bio   <- read.big.nifti("beta_series_bio.nii.gz")
mask  <- read.mask("mask.nii.gz")
bio   <- deepcopy(bio, cols=mask)
## phys
phys  <- read.big.nifti("beta_series_phys.nii.gz")
mask  <- read.mask("mask.nii.gz")
phys  <- deepcopy(phys, cols=mask)
## combine
dat   <- rbind(as.matrix(bio), as.matrix(phys))
rm(bio, phys); gc(F,T)

cat("Get the fitted response\n")
fit   <- rxmat %*% dat # tpts x voxels

cat("Save\n")
hdr <- read.nifti.header("beta_series_bio.nii.gz")
hdr$dim[4] <- nrow(rxmat)
write.nifti(t(fit), hdr, mask, outfile="fitted_response.nii.gz", overwrite=T)
## fix due to my function keeping bad floats
system("3dcalc -overwrite -a fitted_response.nii.gz -expr a -prefix fitted_response.nii.gz") # need to fix my code...
