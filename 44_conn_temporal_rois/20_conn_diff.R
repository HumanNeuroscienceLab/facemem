#!/usr/bin/env Rscript

# This script will compute the connectivity between our 6 ROIs 
# and then get the difference in connectivity between conditions

library(plyr)
library(doMC)
registerDoMC(16)

r2t <- function(r, kappa) {
  t = r*sqrt((kappa-1)/(1-r*r))
  return(t) # df = kappa-1
}


###
# SETUP

subjects <- as.character(as.matrix(read.table("../sublist_all.txt")))

# We want to select a subset of the extract ROIs for our analyses
srois <- c(
  3,  # R OFA
  1,  # R FFA
  69, # R vATL
  32, # R vATL (ant)
  8,  # L OFA
  2,  # L FFA
  62,  # L vATL
  26  # L vATL (ant)
)
snames  <- c("R OFA", "R FFA", "R vATL", "R vATL-2", 
             "L OFA", "L FFA", "L vATL", "L vATL-2")

conds   <- c("bio", "phys")

genname <- "prob_atlas"
ifname  <- "${genname}_peaks_n146"


###
# PATHS

runtype <- "NoQuestions"

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

## zmats is same thing as above
## cept now r's => z's
#zmats <- laply(conds, function(cond) {
#  cat("Condition:", cond, "\n")
#  
#  # Get the names of all the time-series files for this condition
#  tsfiles   <- file.path(tdirs, sprintf("ts_prob_atlas_peaks_n146_%s.1D", cond))
#  
#  laply(tsfiles, function(tsfile) {
#    # Read in the time-series file
#    # but only keep the ROIs of especial interest
#    ts.mat    <- as.matrix(read.table(tsfile))
#    ts.mat    <- ts.mat[,srois]
#    colnames(ts.mat) <- snames
#    # Compute correlation between ROIs
#    r.mat     <- cor(ts.mat)
#    # Convert correlations to z-scores
#    z.mat   <- atanh(r.mat)/sqrt(nrow(ts.mat)-3)
#    diag(z.mat) <- 1
#    return(z.mat)
#  }, .parallel=TRUE)
#})

# Note: this procedure works better than doing the fischer ztransform
zmats <- laply(conds, function(cond) {
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
    # Convert correlations to z-scores
    t.mat    <- r2t(r.mat, nrow(ts.mat))
    diag(t.mat) <- 0
    z.mat    <- matrix(0, nrow(t.mat), ncol(t.mat))
    z.mat[t.mat>0] <- qt(pt(t.mat[t.mat>0], nrow(ts.mat)-1, lower.tail=F), Inf, lower.tail=F)
    z.mat[t.mat<0] <- qt(pt(t.mat[t.mat<0], nrow(ts.mat)-1, lower.tail=T), Inf, lower.tail=T)
    colnames(z.mat) <- snames
    rownames(z.mat) <- snames
    return(z.mat)
  }, .parallel=TRUE)
})

corrplot

###
# DIFFERENCE BTW CONDITIONS

# Let's do a paired t-test for each pair of ROIs between the two conditions
# We'll only use the z-score values here

tstats <- apply(zmats, c(3,4), function(x) {
  if (all(x==0)) return(0)
  t.test(x[1,], x[2,], paired=T)$statistic
})

pvals <- apply(zmats, c(3,4), function(x) {
  if (all(x==0)) return(0)
  t.test(x[1,], x[2,], paired=T)$p.value
})

pvals1 <- apply(zmats, c(3,4), function(x) {
  if (all(x==0)) return(0)
  wilcox.test(x[1,], x[2,], paired=T)$p.value
})

round(tstats, 2)
round(pvals, 3)
round(pvals1, 3)

# ok so it appears that the 



# For fun let's try linear regression and use the beta's instead

bmats <- laply(conds, function(cond) {
  cat("Condition:", cond, "\n")
  
  # Get the names of all the time-series files for this condition
  tsfiles   <- file.path(tdirs, sprintf("ts_prob_atlas_peaks_n146_%s.1D", cond))
  
  laply(tsfiles, function(tsfile) {
    # Read in the time-series file
    # but only keep the ROIs of especial interest
    ts.mat    <- as.matrix(read.table(tsfile))
    ts.mat    <- ts.mat[,srois]
    colnames(ts.mat) <- snames
    # Compute regression between ROIs
    b.mat     <- laply(1:ncol(ts.mat), function(i) {
      fit <- lm(ts.mat ~ ts.mat[,i])
      fit$coefficients[2,]
    })
    diag(b.mat) <- 0
    colnames(b.mat) <- snames
    rownames(b.mat) <- snames
    return(b.mat)
  }, .parallel=TRUE)
})

pvals <- apply(bmats, c(3,4), function(x) {
  if (all(x==0)) return(0)
  t.test(x[1,], x[2,], paired=T)$p.value
})
round(pvals, 2)

pvals <- apply(bmats, c(3,4), function(x) {
  if (all(x==0)) return(0)
  wilcox.test(x[1,], x[2,], paired=T)$p.value
})
round(pvals, 2)



# for some reason the t-statistic doesn't work
tmats <- laply(conds, function(cond) {
  cat("Condition:", cond, "\n")
  
  # Get the names of all the time-series files for this condition
  tsfiles   <- file.path(tdirs, sprintf("ts_prob_atlas_peaks_n146_%s.1D", cond))
  
  laply(tsfiles, function(tsfile) {
    # Read in the time-series file
    # but only keep the ROIs of especial interest
    ts.mat    <- as.matrix(read.table(tsfile))
    ts.mat    <- ts.mat[,srois]
    colnames(ts.mat) <- snames
    # Compute regression between ROIs
    t.mat     <- laply(1:ncol(ts.mat), function(i) {
      fit <- lm(ts.mat ~ ts.mat[,i])
      summ<- summary(fit)
      lapply(summ, function(x) x$coefficients[2,3])
    })
    diag(t.mat) <- 0
    colnames(t.mat) <- snames
    rownames(t.mat) <- snames
    return(t.mat)
  }, .parallel=TRUE)
})
pvals <- apply(tmats, c(3,4), function(x) {
  if (all(x==0)) return(0)
  t.test(x[1,], x[2,], paired=T)$p.value
})
round(pvals, 2)

