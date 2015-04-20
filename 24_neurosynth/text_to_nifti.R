#!/usr/bin/env Rscript

# Convert from a 1D file to nifti file

suppressMessages(library(niftir))

args    <- commandArgs(trailingOnly = TRUE)
infile  <- args[1]
outfile <- args[2]

if (!file.exists(infile)) stop("input file", infile, "doesn't exist")

fsldir  <- Sys.getenv("FSLDIR")
ref_hdr <- read.nifti.header(file.path(fsldir, "data/standard/MNI152_T1_2mm.nii.gz"))

dat <- as.matrix(read.table(infile))
dim(dat) <- c(dim(dat)[1], 1, 1, 1, dim(dat)[2])
  
hdr <- ref_hdr
hdr$dim <- dim(dat)
hdr$pixdim <- c(2,2,2,1,1)
  
invisible(write.nifti(dat, hdr, outfile=outfile))
