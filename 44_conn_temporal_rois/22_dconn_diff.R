#!/usr/bin/env Rscript

library(plyr)
library(doMC)
registerDoMC(16)

source("undirected_functions/alg_pc.R")


###
# SETUP

subjects <- as.character(as.matrix(read.table("../sublist_all.txt")))
# We want to select a subset of the extract ROIs for our analyses
srois <- c(
  3,  # R OFA
  1,  # R FFA
  69, # R vATL
  8,  # L OFA
  2,  # L FFA
  62  # L vATL
)
snames  <- c("R OFA", "R FFA", "R vATL", 
             "L OFA", "L FFA", "L vATL")
conds   <- c("bio", "phys")
region  <- "prob_atlas_peaks_n146"


###
# PATHS

runtype <- "Questions"

base    <- "/mnt/nfs/psych/faceMemoryMRI"
sdirs   <- file.path(base, "analysis/subjects", subjects, runtype)
tdirs   <- file.path(sdirs, "connectivity/task_residuals.reml")


###
# CONNECTIVITY

# rmats is 
# 2 x 16 x 6 x 6
# conditions x subjects x rois x rois
rmats <- laply(conds, function(cond) {
  cat("Condition:", cond, "\n")
  
  # Get the names of all the time-series files for this condition
  tsfiles   <- file.path(tdirs, sprintf("ts_prob_atlas_peaks_n146_%s.1D", cond))
  
  laply(tsfiles, function(tsfile) {
    # Read in the time-series file
    # but only keep the ROIs of especial interest
    ts.mat    <- as.matrix(read.table(tsfile))
    ts.mat    <- ts.mat[,srois]
    colnames(ts.mat) <- snames
    # Compute correlation between ROIs
    r.mat     <- cor(ts.mat)
    return(r.mat)
  }, .parallel=TRUE)
})

# Get the time-series
slists <- llply(conds, function(cond) {
  cat("Condition:", cond, "\n")
  
  # Get the names of all the time-series files for this condition
  tsfiles   <- file.path(tdirs, sprintf("ts_%s_%s.1D", region, cond))
  
  llply(tsfiles, function(tsfile) {
    # Read in the time-series file
    # but only keep the ROIs of especial interest
    ts.mat    <- as.matrix(read.table(tsfile))
    ts.mat    <- ts.mat[,srois]
    colnames(ts.mat) <- snames
    scale(ts.mat)
  }, .parallel=TRUE)
})

# Compile all subjects time-series for each condition
tsmats <- llply(conds, function(cond) {
  cat("Condition:", cond, "\n")
  
  # Get the names of all the time-series files for this condition
  tsfiles   <- file.path(tdirs, sprintf("ts_%s_%s.1D", region, cond))
  
  ldply(tsfiles, function(tsfile) {
    # Read in the time-series file
    # but only keep the ROIs of especial interest
    ts.mat    <- as.matrix(read.table(tsfile))
    ts.mat    <- ts.mat[,srois]
    ts.mat    <- scale(ts.mat)
    colnames(ts.mat) <- snames
    return(ts.mat)
  }, .parallel=TRUE)
})
Z1 <- as.matrix(tsmats[[1]])
Z2 <- as.matrix(tsmats[[2]])
tsmat <- rbind(Z1, Z2)

# Can now get the connections across everyone
pMat  <- conn_pc_pvals(tsmat, numCores=12)
aMat  <- (pMat < 0.05)*1
diag(aMat) <- 0
colnames(aMat) <- snames
rownames(aMat) <- snames
# THIS IS GREAT! It doesn't keep the R OFA-vATL although does keep L OFA to vATL

source("directed_functions/lofs.R")

conn_R4_raw <- function(gadj, sdat, rmat, ...) {
  res   <- lofs.r4(gadj, sdat, cordat=rmat, to.scale=F, ...)
  res$W
}

# R4 (Questions)
ri <- 1 # Questions
dir.mats <- laply(1:length(conds), function(ci) {
  cat("Condition:", conds[ci], "\n")
  
  laply(1:length(subjects), function(si) {
    cat("...subject:", subjects[si], "\n")
    
    sts  <- slists[[ci]][[si]] # scaled time-series
    rmat <- rmats[ci,si,,]     # correlation matrix

    conn_R4_raw(aMat, sts, rmat)
  }, .progress="none", .parallel=T)
})

#names(dim(dir.mats)) <- c("conditions", "subjects", "parcels", "parcels")

## get averages
mres <- apply(dir.mats, c(1,3,4), mean)
dimnames(mres) <- list(condition=conds, rows=snames, cols=snames)
print(round(mres[1,,], 2)) # bio
print(round(mres[2,,], 2)) # phys

## do paired t-tests (bio vs phys)
tres <- apply(dir.mats, c(3,4), function(x) {
  if (all(x==1) || all(x==0)) {
    return(0)
  } else {
    return(t.test(x[1,], x[2,], paired=T)$statistic)
  }
})
colnames(tres) <- snames
rownames(tres) <- snames

pres <- apply(dir.mats, c(3,4), function(x) {
  if (all(x==1) || all(x==0)) {
    return(0)
  } else {
    return(t.test(x[1,], x[2,], paired=T)$p.value)
  }
})
colnames(pres) <- snames
rownames(pres) <- snames

pres2 <- apply(dir.mats, c(3,4), function(x) {
  if (all(x==1) || all(x==0)) {
    return(0)
  } else {
    return(wilcox.test(x[1,], x[2,], paired=T)$p.value)
  }
})
colnames(pres2) <- snames
rownames(pres2) <- snames

round(tres, 3)
round(pres, 2)
round(pres2, 2)


## do R4 on the concatenated data
r4.concat.bio <- conn_R4_raw(aMat, Z1, cor(Z1))
r4.concat.phys <- conn_R4_raw(aMat, Z2, cor(Z2))
dimnames(r4.concat.bio) <- list(rows=snames, cols=snames)
dimnames(r4.concat.phys) <- list(rows=snames, cols=snames)
print(round(r4.concat.bio, 2))
print(round(r4.concat.phys, 2))


## do R4 on subsets of the concatenated data
## i think its M[i,j] i => j (or maybe it's actually j->i)
ltsmats <- llply(conds, function(cond) {
  cat("Condition:", cond, "\n")
  
  # Get the names of all the time-series files for this condition
  tsfiles   <- file.path(tdirs, sprintf("ts_%s_%s.1D", region, cond))
  
  llply(tsfiles, function(tsfile) {
    # Read in the time-series file
    # but only keep the ROIs of especial interest
    ts.mat    <- as.matrix(read.table(tsfile))
    ts.mat    <- ts.mat[,srois]
    ts.mat    <- scale(ts.mat)
    colnames(ts.mat) <- snames
    return(ts.mat)
  }, .parallel=TRUE)
})

library(cvTools)
nsubs <- length(subjects)
k     <- 10
folds <- cvFolds(nsubs, K=k) # R=2 for two repeats
res <- laply(1:k, function(ki) {
  cat("Fold ", ki, "\n")
  
  Zbio  <- do.call("rbind", ltsmats[[1]][folds$which==ki])
  Zphys <- do.call("rbind", ltsmats[[2]][folds$which==ki])
  
  r4.concat.bio <- conn_R4_raw(aMat, Zbio, cor(Zbio))
  r4.concat.phys <- conn_R4_raw(aMat, Zphys, cor(Zphys))
  
  dimnames(r4.concat.bio) <- list(rows=snames, cols=snames)
  dimnames(r4.concat.phys) <- list(rows=snames, cols=snames)
  
  r4.concat.bio - r4.concat.phys
}, .parallel=T)

bio.gt.phys <- apply(sign(res)==1, c(2,3), mean)
phys.gt.bio <- apply(sign(res)==(-1), c(2,3), mean)
