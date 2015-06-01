
#--- SETUP ---#

cat("Setup\n")

library(plyr)
library(bigmemory)
library(biganalytics)
suppressMessages(library(niftir))

# Set threads/forks
library(doMC)
registerDoMC(15)

# settings
subjects      <- as.character(as.matrix(read.table("../sublist_all.txt")))
runtypes      <- c("Questions", "NoQuestions")
conditions    <- c("bio", "phys")
region        <- "parcels_group_localizer_n0658"

# input paths
basedir       <- "/mnt/nfs/psych/faceMemoryMRI"

roidir        <- file.path(basedir, "analysis/groups/Localizer/parcels_migp")
roifile       <- file.path(roidir, "group_region_growing/parcels_relabel.nii.gz")
bgfile        <- file.path(Sys.getenv("FSLDIR"), "data/standard/MNI152_T1_2mm.nii.gz")

# output paths
grpdir        <- file.path(basedir, "analysis/groups")


#--- Functions ---#

rois2voxelwise <- function(roi.data, vox.rois) {
    vox.data <- vector("numeric", length(vox.rois))
    for (ri in 1:nrois)
        vox.data[vox.rois==urois[ri]] <- roi.data[ri]
    return(vox.data)
}


#--- Read in Data ---#

cat("\nRead in Connectivity Data\n")

zmats <- laply(runtypes, function(runtype) {
  cat("\nRuntype:", runtype, "\n")
  laply(conditions, function(condition) {
    cat("...condition:", condition, "\n")
    conndirs  <- file.path(basedir, "analysis/subjects", subjects, runtype, "connectivity")
    zfiles    <- file.path(conndirs, sprintf("zmat_%s_%s.1D", region, condition))
    zmats     <- laply(zfiles, function(fn) as.matrix(read.table(fn)), .progress="text")
    zmats
  })
})
names(dim(zmats)) <- c("runtype", "condition", "subject", "region", "region")

# Ns
nsubs    <- length(subjects)
nregions <- dim(zmats)[4]


#--- Bootstrap Analysis ---#

# Also save the maps
niters     <- 500
vatl.maps  <- big.matrix(nregions, niters, init=0, shared=T)
vatl.ranks <- laply(1:niters, function(i) {
  if (!(i %% 10)) cat(i,".")
  
  sample.subs     <- sample(1:nsubs, 10)
  sample.zmats    <- zmats[1,,sample.subs,,]
  
  # Get difference between the connectivity (Bio > Phys)
  # Then reshape to be matrix and big matrix
  pair.zmats      <- sample.zmats[1,,,] - sample.zmats[2,,,]
  dim(pair.zmats) <- c(dim(pair.zmats)[1], prod(dim(pair.zmats)[-1]))
  pair.zmats      <- as.big.matrix(pair.zmats, shared=F)
  # Compute summary stats and then tvals
  pair.means <- colmean(pair.zmats)
  pair.sds   <- colsd(pair.zmats)
  pair.tvals <- pair.means/(pair.sds/sqrt(nsubs))
  dim(pair.tvals) <- c(nregions,nregions)
  # Get significance
  pair.pvals <- pt(pair.tvals, nrow(pair.zmats)-1, lower.tail=T) # one-tailed p-values
  pair.zvals <- qt(pair.pvals, Inf, lower.tail=T)
  # Clean up
  pair.tvals[is.na(pair.tvals)] <- 0
  pair.pvals[is.na(pair.pvals)] <- 1
  pair.zvals[is.na(pair.zvals)] <- 0
  rm(pair.zmats)
  # Save maps
  vatl.maps[,i] <- pair.zvals[,397]
  # Summarize
  #summary.pair <- cbind(colSums(pair.zvals>1.96), colSums(pair.zvals<(-1.96)))
  summary <- colSums(pair.zvals>1.96)
  ranking <- rank(summary)
  # Give back the vATL ROI rank
  ranking[397]
}, .parallel=T)
vatl.ranks <- nregions - vatl.ranks + 1


#--- Permutation Analysis ---#

# We can also run a permutation test
# so what we want to do is shuffle the signs (in that way we do a sign rank test)
q.zmats <- zmats[1,,,,]
time <- proc.time()
registerDoMC(15)
nperms  <- 500
perms <- laply(1:nperms, function(i) {
  if (!(i %% 50)) cat(i,".")
  
  if (i==1) {
    shuffle.sign  <- rep(1, nsubs)
  } else {
    shuffle.sign  <- sample(c(1,-1), nsubs, rep=T)
  }
  
  # Get difference between the connectivity (Bio > Phys)
  # Then reshape to be matrix and big matrix
  pair.zmats      <- q.zmats[1,,,] - q.zmats[2,,,]
  dim(pair.zmats) <- c(dim(pair.zmats)[1], prod(dim(pair.zmats)[-1]))
  # apply the swapping of condition
  pair.zmats      <- sweep(pair.zmats, 1, shuffle.sign, FUN="*")
  # To big matrix
  pair.zmats      <- as.big.matrix(pair.zmats, shared=F)
  # Compute summary stats and then tvals
  pair.means      <- colmean(pair.zmats)
  pair.sds        <- colsd(pair.zmats)
  pair.tvals      <- pair.means/(pair.sds/sqrt(nsubs))
  dim(pair.tvals) <- c(nregions,nregions)
  # Get significance
  pair.pvals      <- pt(pair.tvals, nrow(pair.zmats)-1, lower.tail=T) # one-tailed p-values
  pair.zvals      <- qt(pair.pvals, Inf, lower.tail=T)
  # Clean up
  pair.tvals[is.na(pair.tvals)] <- 0
  pair.pvals[is.na(pair.pvals)] <- 1
  pair.zvals[is.na(pair.zvals)] <- 0
  rm(pair.zmats)
  # Summarize
  summary.pair <- cbind(colSums(pair.zvals>1.96), colSums(pair.zvals<(-1.96)))
  summary.pair
}, .parallel=T)
new.time <- proc.time()
new.time - time

# Calculate the pvalues
pvals <- apply(perms, c(2,3), function(x) sum(x>=x[1])/length(x))


#--- Original Maps ---#

# Get difference between the connectivity (Bio > Phys)
# Then reshape to be matrix and big matrix
pair.zmats      <- q.zmats[1,,,] - q.zmats[2,,,]
dim(pair.zmats) <- c(dim(pair.zmats)[1], prod(dim(pair.zmats)[-1]))
# To big matrix
pair.zmats      <- as.big.matrix(pair.zmats, shared=F)
# Compute summary stats and then tvals
pair.means      <- colmean(pair.zmats)
pair.sds        <- colsd(pair.zmats)
pair.tvals      <- pair.means/(pair.sds/sqrt(nsubs))
dim(pair.tvals) <- c(nregions,nregions)
# Get significance
pair.pvals      <- pt(pair.tvals, nrow(pair.zmats)-1, lower.tail=T) # one-tailed p-values
pair.zvals      <- qt(pair.pvals, Inf, lower.tail=T)
# Clean up
pair.tvals[is.na(pair.tvals)] <- 0
pair.pvals[is.na(pair.pvals)] <- 1
pair.zvals[is.na(pair.zvals)] <- 0
rm(pair.zmats)

# Get the average between condtions
ave.zmats      <- (q.zmats[1,,,] + q.zmats[2,,,])/2
dim(ave.zmats) <- c(dim(ave.zmats)[1], prod(dim(ave.zmats)[-1]))
# To big matrix
ave.zmats      <- as.big.matrix(ave.zmats, shared=F)
# Compute summary stats and then tvals
ave.means      <- colmean(ave.zmats)
ave.sds        <- colsd(ave.zmats)
ave.tvals      <- ave.means/(ave.sds/sqrt(nsubs))
dim(ave.tvals) <- c(nregions,nregions)
# Get significance
ave.pvals      <- pt(ave.tvals, nrow(ave.zmats)-1, lower.tail=T) # one-tailed p-values
ave.zvals      <- qt(ave.pvals, Inf, lower.tail=T)
# Clean up
ave.tvals[is.na(ave.tvals)] <- 0
ave.pvals[is.na(ave.pvals)] <- 1
ave.zvals[is.na(ave.zvals)] <- 0
rm(ave.zmats)


#--- SAVE ---#

cat("\nSave\n")

# STANDARD SPACE ROIs
# Load the mask/rois and to get a count of the # of ROIs
# These are only used for the output (as are in standard space)
hdr         <- read.nifti.header(roifile)
rois        <- read.mask(roifile, NULL)
mask        <- rois != 0
rois        <- rois[mask]
urois       <- sort(unique(rois))
urois       <- urois[urois!=0]
nrois       <- length(urois)


runtype <- runtypes[1]
cat("runtype:", runtype, "\n")

outdir <- file.path(grpdir, runtype, "cmaps", sprintf("ts_%s_bootstrap+perms.sca", region))
if (!file.exists(outdir)) dir.create(outdir, recursive=T)

file.copy(roifile, file.path(outdir, "parcels.nii.gz"))
file.copy(bgfile, file.path(outdir, "standard.nii.gz"))
write.nifti(mask, hdr, outfile=file.path(outdir, "mask.nii.gz"))

# Summary Measure
outfile1 <- file.path(outdir, "summary_bio_gt_phys.1D")
outfile2 <- file.path(outdir, "summary_bio_gt_phys.nii.gz")
write.table(perms[1,,1], file=outfile1, row.names=F, col.names=F, quote=F)
system(sprintf("Rscript roi_to_voxelwise.R %s %s %s", outfile1, roifile, outfile2))

outfile1 <- file.path(outdir, "summary_phys_gt_bio.1D")
outfile2 <- file.path(outdir, "summary_phys_gt_bio.nii.gz")
write.table(perms[1,,2], file=outfile1, row.names=F, col.names=F, quote=F)
system(sprintf("Rscript roi_to_voxelwise.R %s %s %s", outfile1, roifile, outfile2))  

# Significance of Summary
outfile1 <- file.path(outdir, "pvals_bio_gt_phys.1D")
outfile2 <- file.path(outdir, "pvals_bio_gt_phys.nii.gz")
write.table(pvals[,1], file=outfile1, row.names=F, col.names=F, quote=F)
system(sprintf("Rscript roi_to_voxelwise.R %s %s %s", outfile1, roifile, outfile2))

outfile1 <- file.path(outdir, "pvals_phys_gt_bio.1D")
outfile2 <- file.path(outdir, "pvals_phys_gt_bio.nii.gz")
write.table(pvals[,2], file=outfile1, row.names=F, col.names=F, quote=F)
system(sprintf("Rscript roi_to_voxelwise.R %s %s %s", outfile1, roifile, outfile2))

# Thresholded summary measure
infile1 <- file.path(outdir, "summary_bio_gt_phys.nii.gz")
infile2 <- file.path(outdir, "pvals_bio_gt_phys.nii.gz")
outfile <- file.path(outdir, "thresh_summary_bio_gt_phys.nii.gz")
cmd <- sprintf("3dcalc -a %s -b %s -expr 'a*step((1-b)-0.95)' -prefix %s", infile1, infile2, outfile)
system(cmd)

infile1 <- file.path(outdir, "summary_phys_gt_bio.nii.gz")
infile2 <- file.path(outdir, "pvals_phys_gt_bio.nii.gz")
outfile <- file.path(outdir, "thresh_summary_phys_gt_bio.nii.gz")
cmd <- sprintf("3dcalc -a %s -b %s -expr 'a*step((1-b)-0.95)' -prefix %s", infile1, infile2, outfile)
system(cmd)

# only save the t-statistic map of interest
soutdir <- file.path(outdir, "smaps")
if (!file.exists(soutdir)) dir.create(soutdir, recursive=T)
ris <- c(397)
for (ri in ris) {
  cat("...roi", ri, "\n")
  outfile <- file.path(soutdir, sprintf("zstats_bio_gt_phys_%04i.nii.gz", ri))
  voxs <- rois2voxelwise(pair.zvals[,ri], rois)
  write.nifti(voxs, hdr, mask, outfile=outfile, overwrite=T)
}
for (ri in ris) {
  cat("...roi", ri, "\n")
  outfile <- file.path(soutdir, sprintf("zstats_bio+phys_%04i.nii.gz", ri))
  voxs <- rois2voxelwise(ave.zvals[,ri], rois)
  write.nifti(voxs, hdr, mask, outfile=outfile, overwrite=T)
}

# Save the bootstrap results of the vATL rank
outfile <- file.path(outdir, "bootstrap_vatl_ranks.txt")
write.table(vatl.ranks, file=outfile, row.names=F, col.names=F)

# Save the bootstrap connectivity maps
save.vatl.maps  <- big.matrix(nregions, niters, init=0, shared=T, 
                              backingpath=outdir, 
                              backingfile="bootstrap_vatl_maps.bin", 
                              descriptorfile="bootstrap_vatl_maps.desc")
deepcopy(x=vatl.maps, y=save.vatl.maps)
flush(save.vatl.maps); rm(save.vatl.maps); gc()

# note these results aren't significant after multiple comparisons correction





# Get difference between the connectivity (Bio > Phys)
# Then reshape to be matrix and big matrix
pair.zmats      <- zmats[2,1,,,] - zmats[2,2,,,]
dim(pair.zmats) <- c(dim(pair.zmats)[1], prod(dim(pair.zmats)[-1]))
# apply the swapping of condition
pair.zmats      <- sweep(pair.zmats, 1, shuffle.sign, FUN="*")
# To big matrix
pair.zmats      <- as.big.matrix(pair.zmats, shared=F)
# Compute summary stats and then tvals
pair.means      <- colmean(pair.zmats)
pair.sds        <- colsd(pair.zmats)
pair.tvals      <- pair.means/(pair.sds/sqrt(nsubs))
dim(pair.tvals) <- c(nregions,nregions)
# Get significance
pair.pvals      <- pt(pair.tvals, nrow(pair.zmats)-1, lower.tail=T) # one-tailed p-values
pair.zvals      <- qt(pair.pvals, Inf, lower.tail=T)
# Clean up
pair.tvals[is.na(pair.tvals)] <- 0
pair.pvals[is.na(pair.pvals)] <- 1
pair.zvals[is.na(pair.zvals)] <- 0
rm(pair.zmats)
# Summarize
summary.pair <- cbind(colSums(pair.zvals>1.96), colSums(pair.zvals<(-1.96)))
