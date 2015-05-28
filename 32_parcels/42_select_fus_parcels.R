#!/usr/bin/env Rscript

# This script will find the parcels that overlap with the different fusiform ROIs

#--- SETUP ---#

cat("\nSetup\n")

suppressMessages(library(niftir))
library(plyr)

# Set threads/forks
library(doMC)
registerDoMC(4)

# Basics
basedir     <- "/mnt/nfs/psych/faceMemoryMRI/analysis/groups/Localizer/parcels_migp"
roidir      <- file.path(basedir, "rois")

# Paths to the data
mask_file   <- file.path(basedir, "group_mask.nii.gz")
parcel_file <- file.path(roidir, "parcels.nii.gz")

# Paths to the fusiform ROIs
hemis       <- c("lh", "rh")
parts       <- c("antfusiform", "midfusiform", "postfusiform")
opts        <- expand.grid(list(hemi=hemis, part=parts))
opts$region <- paste(opts$hemi, opts$part, sep="_")
opts$sregion<- paste(opts$hemi, sub("fusiform", "", opts$part), sep="_")
opts$file   <- file.path(roidir, paste(opts$region, "nii.gz", sep="."))


#--- READ ---#

cat("\nRead\n")

mask        <- read.mask(mask_file)
hdr         <- read.nifti.header(mask_file)
parcels     <- read.mask(parcel_file, NULL)[mask]
uparcels    <- sort(unique(parcels[parcels!=0]))


#--- SELECT ---#

cat("\nSelect Parcels\n")

# Gets the parcels that overlap wtih the fusiform ROI and the % overlap
parcel_overlap <- function(fus_file, parcels, mask) {
  cat(fus_file, "\n")
  fus       <- read.mask(fus_file)[mask]
  overlap   <- parcels[fus]
  select_parcels <- sort(unique(overlap))
  percent_overlap <- sapply(select_parcels, function(p) sum(overlap==p)/sum(parcels==p))*100
  # return the percent overlap across all parcels
  ret       <- vector("numeric", length(unique(parcels)))
  ret[select_parcels] <- percent_overlap
  ret
}

# Collect the overlaps with each ROI
overlaps <- laply(opts$file, parcel_overlap, parcels, mask, .parallel=T)
overlaps <- t(overlaps)
colnames(overlaps) <- opts$sregion

# only include ROIs that overlap more than 10% with the fusiform
# that is more than 10% of the parcel is in the fusiform
toverlaps <- overlaps
toverlaps[toverlaps<10] <- 0
cat(sum(rowSums(toverlaps>0)>0), "regions found\n")

# select only those regions where there is overlap
soverlaps <- toverlaps[rowSums(toverlaps>0)>0,]

# find which regions have the most overlap (?)
most.overlap <- apply(soverlaps, 1, which.max)

# create new data frame
df <- data.frame(
  parcel = rownames(soverlaps), 
  hemi   = opts$hemi[most.overlap], 
  part   = opts$part[most.overlap], 
  region = opts$region[most.overlap]
)

# show the summaries
print(df)
table(df$hemi, df$part)

# add new numbers for labeling?
rdf <- ddply(df, .(hemi, part), function(x) {
  x$reparcel <- (as.integer(x$hemi)-1)*100 + (as.integer(x$part)-1)*20 + 1:nrow(x)
  x
})

#--- SAVE ---#

cat("\nSave\n")

# save the table
write.csv(df, file=file.path(basedir, "fusiform_parcels_dataframe.csv"), row.names=F)

# save all the regions into one file.
fus_parcels <- parcels * 0
fus_parcels_relabel <- parcels * 0
fix <- function(x) as.integer(as.character(x))
for (i in 1:nrow(df)) {
  parcel_i <- fix(rdf$parcel[i])
  fus_parcels[parcels==parcel_i] <- fix(rdf$parcel[i])
  fus_parcels_relabel[parcels==parcel_i] <- fix(rdf$reparcel[i])
}
write.nifti(fus_parcels, hdr, mask, outfile=file.path(roidir, "fusiform_parcels.nii.gz"), overwrite=T)
write.nifti(fus_parcels_relabel, hdr, mask, outfile=file.path(roidir, "fusiform_parcels_relabel.nii.gz"), overwrite=T)

