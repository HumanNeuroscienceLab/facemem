#' # Intro
#' 
#' ## Recap
#' 
#' Let's recap here.
#' * __Voxelwise-SBCA__: I computed the contrast of Bio vs Phys for the connectivity between all pairs of parcels. Then I took the number of significant changes in connectivity between conditions for each parcel. I found that the most parcel with the most Bio>Phys connectivity changes was in the left vATL (just anterior to my aFus ROI). Suggests the importance of the vATL in linking different areas for biogrpahical knowledge.
#' * __Seed-Based Connectivity (SC) for the vATL Parcel__: Then I computed the seed-based connectivity for the left vATL parcel that was so important in the prior data-driven approach. Actually I wanted to do this after the present analysis so let's pretend that's what actually happened. With that pretend in place, we find a large set of regions in the ventral temporal cortex that have greater connectivity during Bio vs Phys condition with the left vATL. This suggests the importance of the vATL in potentially linking face representations together for biographical knowledge.
#'
#' ## The Plan
#' 
#' Ok so here I want to read in the left vATL ROI time-series as well as the probabilistic ROI timeseries (select the face-selective ROIs). Then I can compute the connectivity between them and figure out if any of those connections are different between conditions.
#' 

#' # Analyses
#' 
#' ## Setup
#' 
#+ setup
library(plyr)

setwd("/mnt/nfs/psych/faceMemoryMRI/scripts/connpaper")

# Make sure to not have any progress when building
prog <- "none"
#prog <- "text"

subjects <- as.character(as.matrix(read.table("sublist_all.txt")))
runtypes <- c("Questions", "NoQuestions")
#runtypes <- c("Questions") # focus on questions
#runtype  <- runtypes[1]
conds    <- c("bio", "phys")

# Load the face-selective ROIs
snames <- c("R IOG", "R mFus", "R aFus", "R vATL", 
            "L IOG", "L mFus", "L aFus", "L vATL")
load("data/ts_rois_ofa+ffa+vatl.rda")
head(dat$Questions$bio$tb9226)

# Load the left vATL parcel time-series
# add as column to the face-selective data
base    <- "/mnt/nfs/psych/faceMemoryMRI"
subsdir <- file.path(base, "analysis/subjects")
for (runtype in runtypes) {
  cat(runtype, "\n")
  for (subject in subjects) {
    for (cond in conds) {
      indir   <- file.path(subsdir, subject, runtype, "connectivity/task_residuals.reml")
      fname   <- file.path(indir, sprintf("ts_parcels_397_%s.1D", cond))
      vts     <- as.numeric(read.table(fname)[,1])
      
      sdat <- dat[[runtype]][[cond]][[subject]]
      sdat <- cbind(sdat, vts)
      colnames(sdat) <- c(colnames(dat[[runtype]][[cond]][[subject]]), "parcel")
      dat[[runtype]][[cond]][[subject]] <- sdat
    }
  }
}
head(dat$Questions$bio$tb9226)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
#' ## Connectivity
#' 
#' ### Person Correlations
#' 
#+ correlate
#snames <- snames[c(5:8,1:4)] # so that it is left to right
rmats <- laply(runtypes, function(runtype) {
  cat("Runtype:", runtype, "\n")
  laply(conds, function(cond) {
    cat("- Condition:", cond, "\n")
    laply(subjects, function(subject) {
      # Compute correlation between ROI time-series
      ts.mat    <- dat[[runtype]][[cond]][[subject]]
      #ts.mat    <- ts.mat[,c(5:8,1:4)]
      r.mat     <- cor(ts.mat)
      return(r.mat)
    }, .progress=prog)
  })
})
dimnames(rmats) <- list(runtype=runtypes, condition=conds, subject=subjects, 
                        roi=c(snames, "parcel"), roi=c(snames, "parcel"))

#' ### R => Z
#' 
#' Here are the relavant functions for this conversion.
#' 
#+ rtoz-funs
r2t <- function(r, kappa) {
  t = r*sqrt((kappa-1)/(1-r*r))
  return(t) # df = kappa-1
}
t2z <- function(t, kappa) {
  t <- as.matrix(t)
  z <- matrix(0, nrow(t), ncol(t))
  z[t>0] <- qt(pt(t[t>0], kappa-1, lower.tail=F), Inf, lower.tail=F)
  z[t<0] <- qt(pt(t[t<0], kappa-1, lower.tail=T), Inf, lower.tail=T)
  z
}
r2z <- function(r, kappa) {
  r <- as.matrix(r)
  t <- r2t(r, kappa)
  z <- t2z(t, kappa)
  z
}
## z => r
t2r <- function(t, df) {
  r <- t/sqrt(t*t+df)
  return(r) # kappa = df+1
}
z2t <- function(z, df) {
  z <- as.matrix(z)
  t <- matrix(0, nrow(z), ncol(z))
  if (any(z>0))
    t[z>0] <- qt(pt(z[z>0], Inf, lower.tail=F), df, lower.tail=F)
  t[z<0] <- qt(pt(z[z<0], Inf, lower.tail=T), df, lower.tail=T)
  t
}
z2r <- function(z, df) {
  t <- z2t(z, df)
  r <- t2r(t, df)
  r
}

#' And now the actual conversion
#+ rtoz
zmats <- laply(runtypes, function(runtype) {
  cat("Runtype:", runtype, "\n")
  laply(conds, function(cond) {
    cat("- Condition:", cond, "\n")
    laply(subjects, function(subject) {
      # Compute correlation between ROI time-series
      ts.mat    <- dat[[runtype]][[cond]][[subject]]
      #ts.mat    <- ts.mat[,c(5:8,1:4)]
      r.mat     <- cor(ts.mat)
      # Convert correlations to z-stats
      z.mat     <- r2z(r.mat, nrow(ts.mat))
      diag(z.mat) <- 0
      # Return
      return(z.mat)
    }, .progress=prog)
  })
})
dimnames(zmats) <- dimnames(rmats)

#' ### Significance Testing
#' 
#' #### Wilcox
#' 
#' Now let's see what's significantly different
#' Note I'll compute the stat for all pairs of connections but only
#' output the values for connectivity changes with the left vatl parcel
#+ sigtest-wilcox, results='hold'
# Try the wilcox first
pMats <- aaply(zmats, c(1,4,5), function(x) {
  if (all(x==0)) {
    return(0)
  } else {
    return(wilcox.test(x[1,], x[2,], paired=T)$p.value)
  }
})
cat("Questions\n")
round(pMats[1,,9], 3)
cat("No Questions\n")
round(pMats[2,,9], 3)

#' #### T-Test
#'
#' Now we try the t-test
#+ sigtest-ttest, results='hold'
# Then the t-test
pMats <- aaply(zmats, c(1,4,5), function(x) {
  if (all(x==0)) {
    return(0)
  } else {
    return(t.test(x[1,], x[2,], paired=T)$p.value)
  }
})
cat("Questions\n")
round(pMats[1,,9], 3)
cat("No Questions\n")
round(pMats[2,,9], 3)

#' Finally the statistic for the t-test
#+ sigtest-ttest2, results='hold'
# Then the t-test statistic
tMats <- aaply(zmats, c(1,4,5), function(x) {
  if (all(x==0)) {
    return(0)
  } else {
    return(t.test(x[1,], x[2,], paired=T)$statistic)
  }
})
cat("Questions\n")
round(tMats[1,,9], 2)
cat("No Questions\n")
round(tMats[2,,9], 2)

#' #### ANOVA
#' ANOVA. Not totally finally.
#+ sigtest-anova
df.zmats <- reshape::melt.array(zmats)
df.zmats <- subset(df.zmats, runtype=="Questions" & (roi!=roi.1) & roi.1=="parcel")
fit <- aov(value ~ condition*roi + Error(subject/(condition*roi)), data=df.zmats)
summary(fit)

#' # Summary
#' 
#' We can see from the results above that the left vATL parcel has changes in 
#' connectivity between conditions for 5/8 ROIs including the:
#' * L IOG
#' * L mFus
#' * L vATL
#' * R IOG
#' * R mFus
#' * R aFus
#' 
#' It's interesting that the L aFus and L/R vATL weren't significant since they are proximal.
#' I might want to look at the seed-based map with the L aFus/vATL seed-based maps...would be
#' interesting if those show partial overlap with the parcel!
