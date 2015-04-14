#!/usr/bin/env Rscript

#--- SETUP ---#

cat("Setup\n")

library(plyr)

# Set threads/forks
library(doMC)
#registerDoMC(16)
registerDoMC(20)

source("undirected_functions/alg_pc.R")
#source("undirected_functions/alg_huge.R")
#source("undirected_functions/alg_glmnet.R")

# settings
subjects      <- as.character(as.matrix(read.table("../sublist_all.txt")))
runtypes      <- c("Questions", "NoQuestions")
conditions    <- c("bio", "phys")
region        <- "task_pos_peaks_n59"

# input paths
basedir       <- "/mnt/nfs/psych/faceMemoryMRI"


#--- FUNCTIONS ---#

# Output is ntpts x nparcels
read_in_data  <- function(basedir, subject, runtype, condition, region) {
  tsdir   <- file.path(basedir, "analysis/subjects", subject, runtype, "ts")
  tsfile  <- file.path(tsdir, sprintf("%s_%s.1D", region, condition))
  dat     <- as.matrix(read.table(tsfile))
  return(dat)
}

# Output is the correlation matrix
calc_connectivity <- function(dat) {
  cmat        <- cor(dat)
  zmat        <- atanh(cmat) * sqrt(nrow(dat) - 3)
  diag(zmat)  <- 0
  list(r=cmat, z=zmat)
}

# Saves the correlations for later running
save_connectivity <- function(res, basedir, subject, runtype, condition, region) {
  conndir <- file.path(basedir, "analysis/subjects", subject, runtype, "connectivity")
  if (!file.exists(conndir)) dir.create(conndir)
  
  rfile   <- file.path(conndir, sprintf("conn_rmat_%s_%s.1D", region, condition))
  write.table(res$r, file=rfile, quote=F, row.names=F, col.names=F)
  
  zfile   <- file.path(conndir, sprintf("conn_zmat_%s_%s.1D", region, condition))
  write.table(res$z, file=zfile, quote=F, row.names=F, col.names=F)
}

calc_pc <- function(dat) {
  pMat  <- conn_pc_pvals(dat)
  aMat  <- (pMat < 0.05)*1
  diag(aMat) <- 0
  list(p=pMat, a=aMat)
}

save_pc <- function(res, basedir, subject, runtype, condition, region) {
  conndir <- file.path(basedir, "analysis/subjects", subject, runtype, "connectivity")
  if (!file.exists(conndir)) dir.create(conndir)
  
  pfile   <- file.path(conndir, sprintf("pc_pmat_%s_%s.1D", region, condition))
  write.table(res$p, file=pfile, quote=F, row.names=F, col.names=F)
  
  afile   <- file.path(conndir, sprintf("pc_amat_%s_%s.1D", region, condition))
  write.table(res$a, file=afile, quote=F, row.names=F, col.names=F)
}


#--- CONNECTIVITY ---#

cat("\n\nConnectivity\n")

opts <- expand.grid(list(subj=subjects, runt=runtypes, cond=conditions))
d_ply(opts, .(subj, runt, cond), function(opt) {
  subject   <- as.character(opt$subj)
  runtype   <- as.character(opt$runt)
  condition <- as.character(opt$cond)
  
  cat("subject:", subject, "- runtype:", runtype, 
      "- condition:", condition, "\n")
  
  dat <- read_in_data(basedir, subject, runtype, condition, region)
  res <- calc_connectivity(dat)
  save_connectivity(res, basedir, subject, runtype, condition, region)
}, .parallel=T)


#--- PC ---#

cat("\n\nPC\n")

opts <- expand.grid(list(subj=subjects, runt=runtypes, cond=conditions))
d_ply(opts, .(subj, runt, cond), function(opt) {
  subject   <- as.character(opt$subj)
  runtype   <- as.character(opt$runt)
  condition <- as.character(opt$cond)
  
  cat("subject:", subject, "- runtype:", runtype, 
      "- condition:", condition, "\n")
  
  dat <- read_in_data(basedir, subject, runtype, condition, region)
  res <- calc_pc(dat)
  save_pc(res, basedir, subject, runtype, condition, region)

}, .parallel=T)
