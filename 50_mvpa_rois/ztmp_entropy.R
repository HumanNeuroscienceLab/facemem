# This script is meant to get some results for the entropy analyses.

library(plyr)
library(biganalytics)
library(doMC)
registerDoMC(cores=16)

scriptdir <- "/mnt/nfs/psych/faceMemoryMRI/scripts/connpaper"
setwd(file.path(scriptdir, "50_mvpa_rois"))

#runtypes  <- c("Questions", "NoQuestions")
runtypes  <- "Questions"
conds     <- c("bio", "phys")
subjects  <- as.character(as.matrix(read.table("../sublist_all.txt")))

# ROIs
srois <- c(
  1, # L FFA
  2 # L vATL
)
snames  <- c("L FFA", "L vATL")
scols   <- tolower(sub(" ", ".", snames))
sfnames <- tolower(sub(" ", "", snames))

# Paths
base <- "/mnt/nfs/psych/faceMemoryMRI"
grpbase <- file.path(base, "analysis/groups")

# Do the entropy business
library(entropy)
runtype <- runtypes[1]
df2 <- ldply(subjects, function(subject) {
  cat("\n==", subject, "==\n")
  sdir    <- file.path(base, "analysis/subjects", subject, runtype)
  
  # Read in all the roi and condition data
  lst.dat <- llply(srois, function(iroi) {
    ldply(conds, function(cond) {
      tsfile  <- file.path(sdir, "ts", sprintf("bs_classify_%s_%s.1D", sfnames[iroi], cond))
      dat     <- read.table(tsfile)
      data.frame(lab=rep(cond,nrow(dat)), dat)
    })
  })
  names(lst.dat) <- scols
  
  # The labels to predict
  ylabs <- lst.dat[[1]]$lab
  ys    <- 2-as.numeric(ylabs)
  
  # Calculate the entropy. Choose an arbitrary cutoff of 20.
  dat <- as.matrix(lst.dat[[1]][,-1])
  es1 <- laply(1:nrow(dat), function(ti) {
    FNN::entropy(dat[1,], k=10)[10]
  })
  dat <- as.matrix(lst.dat[[2]][,-1])
  es2 <- laply(1:nrow(dat), function(ti) {
    FNN::entropy(dat[1,], k=10)[10]
  })
  
  # Return the entropy of all the trials
  data.frame(
    subject=subject, 
    condition=ylabs, 
    ffa=es1, 
    vatl=es2
  )
}, .parallel=T)
ddply(df2, .(condition), colwise(mean, .(ffa, vatl)))  # this isn't any different

# Do the differential entropy
library(FNN)
runtype <- runtypes[1]
df <- ldply(subjects, function(subject) {
  cat("\n==", subject, "==\n")
  sdir    <- file.path(base, "analysis/subjects", subject, runtype)
  
  # Read in all the roi and condition data
  lst.dat <- llply(srois, function(iroi) {
    ldply(conds, function(cond) {
      tsfile  <- file.path(sdir, "ts", sprintf("bs_classify_%s_%s.1D", sfnames[iroi], cond))
      dat     <- read.table(tsfile)
      data.frame(lab=rep(cond,nrow(dat)), dat)
    })
  })
  names(lst.dat) <- scols
  
  # The labels to predict
  ylabs <- lst.dat[[1]]$lab
  ys    <- 2-as.numeric(ylabs)
  
  # Calculate the entropy. Choose an arbitrary cutoff of 20.
  dat <- as.matrix(lst.dat[[1]][,-1])
  es1 <- laply(1:nrow(dat), function(ti) {
    x <- discretize(dat[ti,], 20, r=range(dat))
    entropy::entropy(x)
  })
  dat <- as.matrix(lst.dat[[2]][,-1])
  es2 <- laply(1:nrow(dat), function(ti) {
    x <- discretize(dat[ti,], 20, r=range(dat))
    entropy::entropy(x)
  })
  
  # Return the entropy of all the trials
  data.frame(
    subject=subject, 
    condition=ylabs, 
    ffa=es1, 
    vatl=es2
  )
}, .parallel=T)
ddply(df, .(condition), colwise(mean, .(ffa, vatl)))
tmp <- ddply(df, .(subject, condition), colwise(mean, .(ffa, vatl)))
t.test(subset(tmp, condition=="bio")$ffa, subset(tmp, condition=="phys")$ffa, paired=T)
t.test(subset(tmp, condition=="bio")$vatl, subset(tmp, condition=="phys")$vatl, paired=T)

# Do the compression
## I need to find my previous code "archive/38_parcel_info/14_compression.R"
suppressMessages(library(niftir))
compressed_nifti_sizes <- function(dat, digits=0, odt='short') {
  dat <- round(dat, digits)
  
  tmpfile1 <- tempfile(pattern="cs1_", fileext=".nii")
  tmpfile2 <- tempfile(pattern="cs2_", fileext=".nii.gz")
  #tmpfile3 <- tempfile(pattern="cs3_", fileext=".nii.bz2")
  #tmpfile4 <- tempfile(pattern="cs4_", fileext=".nii.xz")
  
  hdr <- create.header(dim=dim(dat), pixdim=c(1,1))
  hdr$datatype <- switch(typeof(odt), 
                         char = 2,   # unsigned
                         short = 4,  # signed
                         int = 8,    # signed
                         float = 16, # unsigned
                         double = 64,# unsigned
                         ushort = 512, 
                         uint = 768
  )
  write.nifti(dat, hdr, outfile=tmpfile1)
  write.nifti(dat, hdr, outfile=tmpfile2)
  #write.nifti(dat, hdr, outfile=tmpfile3)
  #write.nifti(dat, hdr, outfile=tmpfile4)
  
  s1 <- file.info(tmpfile1)$size/1024 # Kb
  s2 <- file.info(tmpfile2)$size/1024
  #s3 <- file.info(tmpfile3)$size/1024
  #s4 <- file.info(tmpfile4)$size/1024
  
  #file.remove(tmpfile1, tmpfile2, tmpfile3, tmpfile4)
  file.remove(tmpfile1, tmpfile2)
  
  #c(none=s1, gzip=s2, bzip2=s3, xz=s4)
  c(none=s1, gzip=s2)
}

runtype <- runtypes[1]
df3 <- ldply(subjects, function(subject) {
  cat("\n==", subject, "==\n")
  sdir    <- file.path(base, "analysis/subjects", subject, runtype)
  
  # Read in all the roi and condition data
  lst.dat <- llply(srois, function(iroi) {
    ldply(conds, function(cond) {
      tsfile  <- file.path(sdir, "ts", sprintf("bs_classify_%s_%s.1D", sfnames[iroi], cond))
      dat     <- read.table(tsfile)
      data.frame(lab=rep(cond,nrow(dat)), dat)
    })
  })
  names(lst.dat) <- scols
  
  # The labels to predict
  ylabs <- lst.dat[[1]]$lab
  ys    <- 2-as.numeric(ylabs)
  
  # Calculate the entropy. Choose an arbitrary cutoff of 20.
  dat <- as.matrix(lst.dat[[1]][,-1])
  es1 <- laply(1:nrow(dat), function(ti) {
    compressed_nifti_sizes(dat[ti,,drop=F], digits=0)/ncol(dat)
  })
  dat <- as.matrix(lst.dat[[2]][,-1])
  es2 <- laply(1:nrow(dat), function(ti) {
    compressed_nifti_sizes(dat[ti,,drop=F], digits=0)/ncol(dat)
  })
  
  # Return the entropy of all the trials
  data.frame(
    subject=subject, 
    condition=ylabs, 
    ffa=es1*1024, # to bytes
    vatl=es2*1024 # to bytes
  )
}, .parallel=F) # due to the file I/O, turned off the parallel
ddply(df3, .(condition), colwise(mean, .(ffa.gzip, vatl.gzip)))
tmp <- ddply(df3, .(subject, condition), colwise(mean, .(ffa.gzip, vatl.gzip)))
t.test(subset(tmp, condition=="bio")$ffa.gzip, subset(tmp, condition=="phys")$ffa.gzip, paired=T)
t.test(subset(tmp, condition=="bio")$vatl.gzip, subset(tmp, condition=="phys")$vatl.gzip, paired=T)
