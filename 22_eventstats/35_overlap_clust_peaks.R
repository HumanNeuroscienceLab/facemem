orig_rois <- rois
rois      <- "overlap"
all.df <- ldply(rois, function(roi) {
  ldply(runtypes, function(runtype) {
    ldply(subjects, function(subject) {
      # Load the data
      # ret <- list(trial=matrix(trial x time x region), timing, ntpts)
      lst.dat <- load.data(subject, runtype, roi, 
                           basedir="~/Dropbox/Research/facemem/data/ts", 
                           prestim=5, poststim=19)   
      
      # Remove the baseline
      lst.dat <- remove.baseline(lst.dat, baseline.tpts=-3:-1)
      ## to check
      ## round(as.numeric(apply(lst.dat$trial[,3:5,4], 1, mean), 2))
      
      # Get the mean time-series per condition via a smoothed fit
      ave.df  <- smoothed.average.by.condition(lst.dat, new.tr=0.5)
      
      # Return dataframe with additional information
      cbind(data.frame(
        roi.set = roi, 
        runtype = runtype, 
        subject = subject
      ), ave.df)
    }, .progress="text")
  })
})

all.ave.arr <- daply(all.df, .(roi.set, runtype, region, condition, tpts), function(x) {
  mean(x$mean)
})

# skip the first 4 points and the last 3 points
inds <- 1:dim(all.ave.arr)[4]
inds <- inds[-c(1:4,(length(inds)-3+1):length(inds))]
tmp <- all.ave.arr[1,,,inds]
tmp <- aperm(tmp, c(1,3,2))
dim(tmp) <- c(dim(tmp)[1], dim(tmp)[2]*dim(tmp)[3])
tmp <- t(tmp)

library(dynamicTreeCut)
#d <- dist(t(tmp))
d <- as.dist(2*sqrt(1-cor(tmp)))
dmat <- as.matrix(d)
hc <- hclust(d)
res <- cutreeDynamic(hc, minClusterSize=2, distM=dmat)
lapply(sort(unique(res)), function(i) which(as.numeric(res)==i))

# add difference curve and then cluster
tmp2 <- tmp
tmp2 <- rbind(tmp2, t(all.ave.arr[1,,1,inds] - all.ave.arr[1,,2,inds]))
d <- as.dist(2*sqrt(1-cor(tmp2)))
dmat <- as.matrix(d)
hc <- hclust(d)
res <- cutreeDynamic(hc, minClusterSize=2, distM=dmat)
lapply(sort(unique(res)), function(i) which(as.numeric(res)==i))

plot.ts(tmp[,res==1][,1:10])
plot.ts(tmp[,res==2])
plot.ts(tmp[,res==6])

library(sparcl)
ColorDendrogram(hc, y=res, branchlength=3)

#   2,   # L vATL
#   5,   # L PHC
#   4,   # L RSC
#   40,   # R PCC
#   16,  # L dACC
#   7,   # R dACC
#   17,  # B midCC
#   31,  # L fOp/Ins
#   25,  # R fOp/Ins
#   8,   # L fOrb
#   30  # R fOrb

# So using the difference appears to have been the key to get nicer clusters!
# sdf.

plot.ts(tmp[,res==1][,1:10])


all.ave.df <- ddply(all.df, .(roi.set, runtype, region, condition, tpts), function(x) {
  res <- t.test(x$mean)
  agree <- max(table(sign(x$mean)))/nrow(x)
  c(response=mean(x$mean), pval=res$p.value, agree=agree)
})

