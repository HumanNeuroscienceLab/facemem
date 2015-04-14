#!/usr/bin/env Rscript

# Takes some scaler ROI data and converts it to be voxelwise

suppressMessages(library(niftir))


#--- ARGS ---#

args    <- commandArgs(trailingOnly = TRUE)
infile  <- args[1]
roifile <- args[2]
outfile <- args[3]

if (length(args) != 3) stop("usage: roi_to_voxelwise.R infile roifile outfile")
if (!file.exists(infile)) stop("input file", infile, "doesn't exist")
if (!file.exists(roifile)) stop("roi file", roifile, "doesn't exist")


#--- FUNCTION ---#

rois2voxelwise <- function(roi.data, vox.rois) {
    vox.data <- vector("numeric", length(vox.rois))

    urois <- sort(unique(vox.rois))
    urois <- urois[urois!=0]
    nrois <- length(urois)

    for (ri in 1:nrois)
        vox.data[vox.rois==urois[ri]] <- roi.data[ri]

    return(vox.data)
}


#--- RUN ---#

# Read
roi.data  <- as.matrix(read.table(infile))
vox.rois  <- read.mask(roifile, NULL)
hdr       <- read.nifti.header(roifile)

# Run
vox.data  <- rois2voxelwise(roi.data, vox.rois)

# Save
invisible(write.nifti(vox.data, hdr, outfile=outfile))

