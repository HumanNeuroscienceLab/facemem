#!/usr/bin/env Rscript

#--- SETUP ---#

cat("Setup\n")

library(plyr)

# Set threads/forks
library(doMC)
#registerDoMC(16)
registerDoMC(20)

# settings
subjects      <- as.character(as.matrix(read.table("../sublist_all.txt")))
runtypes      <- c("Questions", "NoQuestions")
conditions    <- c("bio", "phys")
region        <- "task_pos_peaks_n59"

# input paths
basedir       <- "/mnt/nfs/psych/faceMemoryMRI"


#--- READ TIME-SERIES ---#

cat("\nRead in Time-Series Data\n")

tslsts <- llply(runtypes, function(runtype) {
  cat("\nRuntype:", runtype, "\n")
  llply(conditions, function(condition) {
    cat("...condition:", condition, "\n")
    tdirs     <- file.path(basedir, "analysis/subjects", subjects, runtype, "ts")
    tfiles    <- file.path(tdirs, sprintf("%s_%s.1D", region, condition))
    tlsts     <- llply(tfiles, function(fn) as.matrix(read.table(fn)), .progress="text")
    tlsts
  })
})
names(tslsts) <- runtypes
names(tslsts[[1]]) <- conditions
names(tslsts[[2]]) <- conditions

cat("...scale\n")
stslsts <- llply(runtypes, function(runtype) {
  cat("\nRuntype:", runtype, "\n")
  llply(conditions, function(condition) {
    cat("...condition:", condition, "\n")
    stlsts  <- llply(tslsts[[runtype]][[condition]], scale, .parallel=T)
    stlsts
  })
})
names(stslsts) <- runtypes
names(stslsts[[1]]) <- conditions
names(stslsts[[2]]) <- conditions

## easier variable name
tlists <- tslsts
slists <- stslsts


#--- Read in Connectivity Data ---#

cat("\nRead in Connectivity Data\n")

cat("...raw\n")
rmats <- laply(runtypes, function(runtype) {
  cat("\nRuntype:", runtype, "\n")
  laply(conditions, function(condition) {
    cat("...condition:", condition, "\n")
    conndirs  <- file.path(basedir, "analysis/subjects", subjects, runtype, "connectivity")
    rfiles    <- file.path(conndirs, sprintf("conn_rmat_%s_%s.1D", region, condition))
    rmats     <- laply(rfiles, function(fn) as.matrix(read.table(fn)), .progress="text")
    rmats
  })
})
names(dim(rmats)) <- c("runtype", "condition", "subject", "region", "region")


#--- GROUP PC ESTIMATE ---#

source("undirected_functions/alg_pc.R")

tconcat <- function(sdats, numCores=16, to.scale=T, verbose=T) 
{
  library(bigmemory)
  
  nSubs       <- length(sdats)
  
  registerDoMC(numCores)
  lens      <- sapply(sdats, nrow)
  sinds     <- c(0, cumsum(lens)[-length(lens)]) + 1
  einds     <- cumsum(lens)
  grp.sdat  <- big.matrix(sum(lens), ncol(sdats[[1]]), init=0, shared=T)
  l_ply(seq_along(sdats), function(i) {
    sdat                <- sdats[[i]]
    if (to.scale) sdat  <- scale(sdat)
    
    row_inds            <- sinds[i]:einds[i]
    grp.sdat[row_inds,] <- sdat
  }, .parallel=T)
  
  ## check
  # all.equal(tail(grp.sdat[,1]), tail(sdats[[length(sdats)]][,peaks[1]]))
  
  as.matrix(grp.sdat)
}

Z1 <- tconcat(slists$Questions$bio)
Z2 <- tconcat(slists$Questions$phys)
Z3 <- tconcat(slists$NoQuestions$bio)
Z4 <- tconcat(slists$NoQuestions$phys)
Z  <- rbind(Z1,Z2,Z3,Z4)
#lh <- 1:29

#registerDoMC(1)
#pMat  <- conn_pc_pvals(Z[,-lh], numCores=20)
#aMat  <- (pMat < 0.05)*1
#diag(aMat) <- 0
#registerDoMC(20)

# Here, they are all connected!!!
srois <- c(
  2, # LOC
  3, # OFA
  8, # FFA
  6, # vATL
  18 # temporal pole
)
snames <- c("LOC", "OFA", "FFA", "vATL", "TempPole")
registerDoMC(1)
## PC algorithm
pMat  <- conn_pc_pvals(Z[,srois], numCores=20)
registerDoMC(20)
aMat  <- (pMat < 0.05)*1 # even with p < 0.01, same
diag(aMat) <- 0
colnames(aMat) <- snames
rownames(aMat) <- snames
## Correlation
rMat <- round(cor(Z[,srois]), 2)
colnames(rMat) <- snames
rownames(rMat) <- snames
## show some corrs and adjs
cat("Group Average Conn Outputs\n")
print(rMat)
print(aMat)


#--- FUNCTIONS ---#

# Load all the directional functions
source("directed_functions/lofs.R")
#source("directed_functions/pwling.R")
source("directed_functions/patel.R")

upper <- function(x) x[upper.tri(x)]

#conn_skew <- function(gadj, sdat, rmat) {
#  # no skewness correction
#  res <- pwling(t(sdat), -3, S=gadj, to.scale=F, C=rmat, verbose=F)
#  res$dag
#}
#
#conn_rskew <- function(gadj, sdat, rmat) {
#  # no skewness correction
#  res <- pwling(t(sdat), -4, S=gadj, to.scale=F, C=rmat, verbose=F)
#  res$dag
#}
#
#conn_R3 <- function(gadj, sdat, rmat=NULL) {
#  dag <- lofs.r3(gadj, sdat, to.scale=F)
#  dag
#}
#
#conn_R4 <- function(gadj, sdat, rmat) {
#  res   <- lofs.r4(gadj, sdat, cordat=rmat, to.scale=F, verbose=F)
#  res$dag
#}

conn_R4_raw <- function(gadj, sdat, rmat, ...) {
  res   <- lofs.r4(gadj, sdat, cordat=rmat, to.scale=F, ...)
  res$W
}

conn_patel <- function(gadj, dat, rmat=NULL) {
  res   <- patel.tau(dat, gadj, to.scale=F, verbose=F)
  res$dag
}



#--- 

# Patel's Tau on concatenated data
res.patel.qbio  <- conn_patel(aMat, Z1[,srois])
res.patel.qphys <- conn_patel(aMat, Z2[,srois])
## noq
res.patel.nqbio  <- conn_patel(aMat, Z3[,srois])
res.patel.nqphys <- conn_patel(aMat, Z4[,srois])

# R4 (Questions)
ri <- 1 # Questions
dir.mats <- laply(1:length(conditions), function(ci) {
  cat("Condition:", conditions[ci], "\n")
  
  laply(1:length(subjects), function(si) {
    cat("...subject:", subjects[si], "\n")
    
    ts   <- tlists[[ri]][[ci]][[si]] # time-series
    sts  <- slists[[ri]][[ci]][[si]] # scaled time-series
    rmat <- rmats[ri,ci,si,,]        # correlation matrix

    conn_R4_raw(aMat, sts[,srois], rmat[srois,srois])
  }, .progress="none", .parallel=T)
})
names(dim(dir.mats)) <- c("conditions", "subjects", "parcels", "parcels")

## get averages
mres <- apply(dir.mats, c(1,3,4), mean)
dimnames(mres) <- list(condition=conditions, rows=snames, cols=snames)
print(round(mres[1,,], 2)) # bio
print(round(mres[2,,], 2)) # phys

## do paired t-tests (bio vs phys)
tres <- apply(dir.mats, c(3,4), function(x) {
  if (all(x==1)) {
    return(0)
  } else {
    return(t.test(x[1,], x[2,])$statistic)
  }
})
colnames(tres) <- snames
rownames(tres) <- snames

## do R4 on the concatenated data
r4.concat.bio <- conn_R4_raw(aMat, Z1[,srois], cor(Z1[,srois]))
r4.concat.phys <- conn_R4_raw(aMat, Z2[,srois], cor(Z2[,srois]))
dimnames(r4.concat.bio) <- list(rows=snames, cols=snames)
dimnames(r4.concat.phys) <- list(rows=snames, cols=snames)
print(round(r4.concat.bio, 2))
print(round(r4.concat.phys, 2))

# R4 (NoQuestions)
ri <- 2 # NoQuestions
dir.mats <- laply(1:length(conditions), function(ci) {
  cat("Condition:", conditions[ci], "\n")
  
  laply(1:length(subjects), function(si) {
    cat("...subject:", subjects[si], "\n")
    
    ts   <- tlists[[ri]][[ci]][[si]] # time-series
    sts  <- slists[[ri]][[ci]][[si]] # scaled time-series
    rmat <- rmats[ri,ci,si,,]        # correlation matrix
    
    conn_R4_raw(aMat, sts[,srois], rmat[srois,srois])
  }, .progress="none", .parallel=T)
})
names(dim(dir.mats)) <- c("conditions", "subjects", "parcels", "parcels")

## get averages
mres <- apply(dir.mats, c(1,3,4), mean)

## do paired t-tests (bio vs phys)
tres <- apply(dir.mats, c(3,4), function(x) {
  if (all(x==1)) {
    return(0)
  } else {
    return(t.test(x[1,], x[2,])$statistic)
  }
})
colnames(tres) <- snames
rownames(tres) <- snames

