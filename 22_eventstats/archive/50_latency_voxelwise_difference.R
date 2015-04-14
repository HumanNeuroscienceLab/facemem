#!/usr/bin/env Rscript

# This script applies the David Brinda's difference measure
# to the voxelwise data

#--- SETUP ---#
datadir       <- "/mnt/nfs/psych/faceMemoryMRI/analysis/subjects"
timingdir     <- "/mnt/nfs/psych/faceMemoryMRI/scripts/timing"
grpdir        <- "/mnt/nfs/psych/faceMemoryMRI/analysis/groups"

subjects      <- as.character(read.table("../sublist_all.txt")[,])
runtypes      <- c("Questions", "NoQuestions")
conditions    <- c("bio","phys")

source("50_latency_voxelwise_worker.R")

# Now all the above is a lot of code. Can we create one function that runs all of this?
library(doMC)
registerDoMC(16)

tpts          <- -5:19
baseline.inds <- c(3,5)
overwrite     <- F

maskfile      <- file.path(grpdir, "Questions/task/questions_task_smoother.mema/mask.nii.gz")
hdr           <- read.nifti.header(maskfile)
mask          <- read.mask(maskfile)

#--- FUNCTIONS ---#
# reads the average data in standard space
read_ave_data <- function(mask, subject, runtype, condition) {
  # paths
  scan_dir      <- file.path(datadir, subject, runtype)
  ts_file       <- file.path(scan_dir, "latency", paste(condition, "ave_percent_to_std.nii.gz", sep="_"))
  # read
  dat           <- read.big.nifti(ts_file, shared=F)
  mdat          <- deepcopy(dat, cols=mask, shared=T)
  rm(dat); gc(F,T)
  
  mdat
}


#for (runtype in runtypes) {
#  cat("\n===\n")
#  cat(runtype, "\n")
runtype <- "Questions"

outdir        <- file.path(grpdir, runtype, "task", "prop_diffs.stats")
if (!file.exists(outdir)) dir.create(outdir)

#--- GET DIFFERENCES ---#  
# note that i have calculated the averages elsewhere
# also note that these averages have had the baseline (-3:-1s) removed
s.diffdats <- lapply(subjects, function(subject) {
  cat("subject:", subject, "\n")
  
  ## load data and timing
  cat("...load and read\n")
  nvoxs         <- sum(mask)
  dats <- lapply(conditions, function(condition) {
    read_ave_data(mask, subject, runtype, condition)
  })
  names(dats) <- conditions
  
  ## save the difference data
  cat("...setup saving\n")
  ntpts         <- length(tpts)
  vox.diffdat   <- big.matrix(ntpts, nvoxs, shared=T)
  
  ## process data (get the average/difference)
  cat("...process data\n")
  vox.diffdat[,] <- dats$bio[,] - dats$phys[,]
  
  ## clean
  cat("...clean\n")
  rm(dats); gc(F,T)
  
  return(vox.diffdat)
})

#--- STAT MEASURE ON DIFFERENCES ---#  
## exclude 5th subject
subjects    <- subjects[-5]
s.diffdats  <- s.diffdats[-5]

nsubjects   <- length(subjects)
tpts        <- -5:19
onset       <- which(tpts==0)
offset      <- which(tpts==16)
vox.props   <- big.matrix(ntpts, nvoxs, init=0, shared=T)
vox.pvals   <- big.matrix(ntpts, nvoxs, init=0, shared=T)

# loop through each voxel
# then through each subject to combine the average event time-series
cat("...calculating difference measure, voxelwise\n")
fiveperc      <- floor(nvoxs*0.05)
vox.ave.props <- laply(1:nvoxs, function(vox) {
  if (!(vox %% fiveperc)) cat(floor(vox/nvoxs*100), "%...", sep="")
  
  # onset:offset x nsubjects
  dif <- sapply(1:nsubjects, function(si) {
    s.diffdats[[si]][onset:offset,vox]
  })
  
  # calculate the proportion of times the difference curves had the same sign
  # and take the average of this across time
  ## (NOTE: think there was an error with ntimes with old code...)
  props     <- rowMeans(dif>0) # ave diff that's pos per tpt
  props     <- sapply(props, function(x) max(x, 1-x))
  ave.props <- mean(props)
  # save proportion time-series
  vox.props[onset:offset,vox] <- props
  
  # p-values
  pvals     <- apply(dif, 1, function(x) wilcox.test(x)$p.value)
  vox.pvals[onset:offset,vox] <- -log10(pvals)
  
  return(ave.props)
}, .parallel=T)

# save the 3D file
cat("...saving 3D\n")
outfile <- file.path(outdir, "average_proportion_of_subjects.nii.gz")
write.nifti(vox.ave.props, hdr, mask, outfile=outfile, overwrite=T)

# save the 4D file
cat("...saving 4D\n")
new.hdr1 <- hdr
new.hdr1$dim <- c(hdr$dim, ntpts)
new.hdr1$pixdim <- c(hdr$pixdim, 1)

outfile1 <- file.path(outdir, "ts_proportion_of_subjects.nii.gz")
bigni <- as.big.nifti4d(vox.props, new.hdr1, mask)
write.nifti(bigni, outfile=outfile1, overwrite=T)

outfile2 <- file.path(outdir, "ts_pvals.nii.gz")
bigni <- as.big.nifti4d(vox.pvals, new.hdr1, mask)
write.nifti(bigni, outfile=outfile2, overwrite=T)

# save just the R data
ave.diff <- vox.ave.props
pval.diff <- vox.pvals[,]
ts.diff <- vox.props[,]
outfile <- file.path(outdir, "data.rda")
save(ave.diff, pval.diff, ts.diff, mask, hdr, file=outfile)
rm(ts.diff); rm(ave.diff); rm(pval.diff); gc(F,T)

# copy over standard
stdfile <- file.path(Sys.getenv("FSLDIR"), "data/standard/MNI152_T1_2mm_brain.nii.gz")
outfile <- file.path(outdir, "standard_2mm.nii.gz")
file.symlink(stdfile, outfile)

cat("...cleaning\n")
rm(s.diffdats); gc(F,T)
rm(vox.props); gc(F,T)
