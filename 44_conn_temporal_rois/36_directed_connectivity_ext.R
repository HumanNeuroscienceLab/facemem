library(plyr)
library(corrplot)
library(RColorBrewer)
library(knitr)
library(ggplot2)
library(igraph)

setwd("~/Dropbox/Research/facemem/connpaper")

# Make sure to not have any progress when building
#prog <- "none"
prog <- "text"

# We want to select a subset of the extract ROIs for our analyses
subjects <- as.character(as.matrix(read.table("sublist_all.txt")))
runtypes <- c("Questions", "NoQuestions")
conds    <- c("bio", "phys")
# We want to select a subset of the extract ROIs for our analyses
snames1   <- c("R OFA", "R FFA", "R vATL", 
              "L OFA", "L FFA", "L vATL")
srois2 <- c(
  2,   # L PHC
  3   # L RSC
)
snames2 <- c("L PHC", "L RSC")
snames <- c(snames1, snames2)

setwd("~/Dropbox/Research/facemem/connpaper")

# Load all the time-series
cat("time-series\n")
load("data/ts_rois_ofa+ffa+vatl.rda")
dat1 <- dat
load("data/ts_rois_selectoverlap.rda")
dat2 <- dat
rm(dat)
head(dat1$Questions$bio$tb9226)
head(dat2$Questions$bio$tb9226)

# Combine Get the scaled time-series
cat("combine + scaled time-series\n")
scale.dat <- llply(runtypes, function(runtype) {
  ret <- llply(conds, function(cond) {
    ret <- llply(subjects, function(subj) {
      sdat <- cbind(dat1[[runtype]][[cond]][[subj]], 
                    dat2[[runtype]][[cond]][[subj]][,srois2])
      sdat <- scale(sdat)
      colnames(sdat) <- snames
      sdat
    })
    names(ret) <- subjects
    ret
  })
  names(ret) <- conds
  ret
})
names(scale.dat) <- runtypes

cat("correlations\n")
rmats <- laply(runtypes, function(runtype) {
  cat("Runtype:", runtype, "\n")
  laply(conds, function(cond) {
    cat("- Condition:", cond, "\n")
    laply(subjects, function(subject) {
      # Compute correlation between ROI time-series
      ts.mat    <- cbind(dat1[[runtype]][[cond]][[subject]], 
                         dat2[[runtype]][[cond]][[subject]][,srois2])
      r.mat     <- cor(ts.mat)
      return(r.mat)
    }, .progress=prog)
  })
})
dimnames(rmats) <- list(runtype=runtypes, condition=conds, subject=subjects, 
                        roi=snames, roi=snames)



### Predefine Connections
## Keep out the heterotopic
# 0 = no connection; 1 = yes connection
fixed.conn.mat <- matrix(0, length(snames), length(snames), dimnames=list(roi=snames, roi=snames))
# these are the right-hemisphere only connections
fixed.conn.mat[1:3,1:3] <- 1
# now the left-hemisphere connections
fixed.conn.mat[4:8,4:8] <- 1
# keep the diagonals out of this
diag(fixed.conn.mat) <- 0
## Keep the homotopic
diag(fixed.conn.mat[1:3,4:6]) <- 1
diag(fixed.conn.mat[4:6,1:3]) <- 1

### Use the PC algorithm
## Concatenate subject data
# Compile all subjects time-series for each condition and each runtype
concat.scale.dat <- llply(runtypes, function(runtype) {
  cat("Runtype:", runtype, "\n")
  ret <- llply(conds, function(cond) {
    cat("- condition:", cond, "\n")
    #do.call("rbind", scale.dat[[runtype]][[cond]])
    ret <- ldply(subjects, function(subject) {
      scale.dat[[runtype]][[cond]][[subject]]
    }, .parallel=F)
    as.matrix(ret)
  })
  ## we also com
  names(ret) <- conds
  ret
})
names(concat.scale.dat) <- runtypes

# Now collapse across runtype and condition
Z <- rbind(
  concat.scale.dat$Questions$bio, concat.scale.dat$Questions$phys, 
  concat.scale.dat$NoQuestions$bio, concat.scale.dat$NoQuestions$phys
)

## Exclude conditionally independent connections
setwd("~/Dropbox/Research/facemem/connpaper")
source("44_conn_temporal_rois/undirected_functions/alg_pc.R")

pMat  <- conn_pc_pvals(Z, fixedGaps=fixed.conn.mat==1)
aMat  <- (pMat < 0.05)*1 * fixed.conn.mat
diag(aMat) <- 0
dimnames(aMat) <- list(roi=snames, roi=snames)

print(aMat) # all connections are kept



## D Conn

setwd("~/Dropbox/Research/facemem/connpaper")
source("44_conn_temporal_rois/directed_functions/lofs.R")

conn_R4_raw <- function(gadj, sdat, rmat, ...) {
  res   <- lofs.r4(gadj, sdat, cordat=rmat, to.scale=F, ...)
  res$W
}

dir.mats <- laply(1:length(runtypes), function(ri) {
  cat("Runtype:", runtypes[ri], "\n")
  laply(1:length(conds), function(ci) {
    cat("- condition:", conds[ci], "\n")
    laply(1:length(subjects), function(si) {
      #cat("  ...subject:", subjects[si], "\n")
      sts  <- scale.dat[[ri]][[ci]][[si]] # scaled time-series
      rmat <- rmats[ri,ci,si,,]           # correlation matrix
      conn_R4_raw(aMat, sts, rmat, zeta=4)# calc directed connectivity with R4
      # note that the zeta here is the range +/- of the 'beta' values to search
      # during the fitting process
    }, .progress=prog, .parallel=F)
  })
})
dimnames(dir.mats) <- list(runtype=runtypes, condition=conds, subject=subjects, 
                           target=snames, seed=snames)

## Questions
# T-Statistic
tres <- apply(dir.mats[1,,,,], c(3,4), function(x) {
  if (all(x==1) || all(x==0)) {
    return(0)
  } else {
    return(t.test(x[1,], x[2,], paired=T)$statistic)
  }
})
colnames(tres) <- snames
rownames(tres) <- snames

# P-value with wilcox signed rank test
pres2 <- apply(dir.mats[1,,,,], c(3,4), function(x) {
  if (all(x==1) || all(x==0)) {
    return(0)
  } else {
    return(wilcox.test(x[1,], x[2,], paired=T)$p.value)
  }
})
colnames(pres2) <- snames
rownames(pres2) <- snames

cat("Tstat\n")
round(tres, 3)
cat("Pval with wilcox test\n")
round(pres2, 2)


## NoQuestions
# T-Statistic
tres <- apply(dir.mats[2,,,,], c(3,4), function(x) {
  if (all(x==1) || all(x==0)) {
    return(0)
  } else {
    return(t.test(x[1,], x[2,], paired=T)$statistic)
  }
})
colnames(tres) <- snames
rownames(tres) <- snames

# P-value with wilcox signed rank test
pres2 <- apply(dir.mats[2,,,,], c(3,4), function(x) {
  if (all(x==1) || all(x==0)) {
    return(0)
  } else {
    return(wilcox.test(x[1,], x[2,], paired=T)$p.value)
  }
})
colnames(pres2) <- snames
rownames(pres2) <- snames

cat("Tstat\n")
round(tres, 3)
cat("Pval with wilcox test\n")
round(pres2, 2)



# Plot Data
setwd("~/Dropbox/Research/facemem/connpaper")
# Get the coordinates for the 6 ROIs
coords <- as.matrix(read.table("44_conn_temporal_rois/z_coords2.txt"))
dimnames(coords) <- list(roi=snames, dim=c("x","y","z"))

# Just get the average instead for each condition/runtype
ave.dconn <- apply(dir.mats, c(1,2,4,5), mean)

# Average of the paired differene
diff.dconn <- apply(dir.mats, c(1,4,5), function(x) mean(x[1,]-x[2,]))

# Compute the p-values for bio/phys for q/noq
pval.dconn0 <- apply(dir.mats, c(1,2,4,5), function(x) {
  if (all(x==1) || all(x==0)) {
    return(0)
  } else {
    return(wilcox.test(x)$p.value)
  }
})

# Recompute the p-values for the differences bio vs phys
pval.dconn <- laply(1:2, function(ri) {
  apply(dir.mats[ri,,,,], c(3,4), function(x) {
    if (all(x==1) || all(x==0)) {
      return(1)
    } else {
      return(wilcox.test(x[1,], x[2,], paired=T)$p.value)
    }
  })  
})
dimnames(pval.dconn) <- list(runtype=runtypes, target=snames, seed=snames)

library(igraph)
cols2 <- brewer.pal(8, "Dark2")[c(1,3,4)] # Questions, NoQuestions, and Overlap
cols <- brewer.pal(3, "Set1") # Condition colors

old.mar <- par()$mar
par(mar=c(0,0,2,0))

for (ri in 1:2) {
  pmat <- t(pval.dconn[ri,,])
  mat  <- t(diff.dconn[ri,,])
  mat  <- mat * (pmat<0.1)   # threshold matrix with p < 0.1
  g    <- graph.adjacency(mat, mode="directed", weighted=T, diag=F)
  
  # Want extra curves for 1-3 or 4-6 (vATL <-> FFA)
  curves <- apply(get.edges(g, E(g)), 1, function(x) {
    if (all(x %in% c(1,3)) || all(x %in% c(4,6))) {
      return(1)
    } else {
      return(0.4)
    }
  })
  # Want to have dotted lines for feedback
  linetypes <- apply(get.edges(g, E(g)), 1, function(x) {
    # feedback / feedforward
    if (all(x %in% 1:3) || all(x %in% 4:6)) {
      if (x[1] > x[2]) return(2)
      else return(1)
    } else { # homotopic
      return(3)
    }
  })
  # Edge color
  ecolors <- cols[(E(g)$weight < 0)*1 + 1]
  
  plot.igraph(g, 
              edge.width=E(g)$weight*2.5, 
              edge.label=round(E(g)$weight, 2), 
              edge.lty=linetypes, 
              edge.curved=curves, 
              edge.color=ecolors, 
              vertex.size=42,
              vertex.color=cols2[ri], #"red",
              vertex.frame.color= "white",
              vertex.label.color = "white",
              vertex.label.family = "sans",
              layout=coords, 
              main=sprintf("%s : bio vs phys", runtypes[ri]))
}

par(mar=old.mar)
