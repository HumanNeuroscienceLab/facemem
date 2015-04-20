#!/usr/bin/env Rscript

# Basically looking into getting the clusters from the overlap regions
# see /mnt/nfs/psych/faceMemoryMRI/analysis/groups/Combo/overlap

# What I want to do is get the group-level average eventstats
# and concatenate the bio and phys output for the Questions and NoQuestions runs
# Then I want to cluster (but only with neighbors)


###
# Setup

suppressMessages(library(niftir))
source("searchlight.R")

base          <- "/mnt/nfs/psych/faceMemoryMRI"
overlap.dir   <- file.path(base, "analysis/groups/Combo/overlap")
overlap.file  <- file.path(overlap.dir, "clust_overlap_masked.nii.gz")


###
# Functions

read_data <- function(func_file, mask, to.scale=T) {
  func  <- read.big.nifti(func_file)
  func  <- deepcopy(func, cols=mask, rows=4:nrow(func))
  if (to.scale) {
    func <- scale_fast(func, to.copy=F)
  }
  as.matrix(func)
}


###
# Load

n <- 3

hdr     <- read.nifti.header(overlap.file)
oclusts <- read.mask(overlap.file, NULL)
mask    <- oclusts == n

# files should be NoQ-bio, NoQ-phys, Q-bio, Q-phys
esfiles <- Sys.glob(file.path(base, "analysis/groups/*/task/smoother_eventstats_01/es_standardized_*_avg_percent.nii.gz"))
# read in the files
esdats  <- llply(esfiles, read_data, mask, .progress="text")
# temporally concatenace
Z       <- laply(esdats, function(x) x)
dim(Z)  <- c(dim(Z)[1]*dim(Z)[2], dim(Z)[3])
esdat   <- Z
rm(Z); rm(esdats)

nvoxs   <- sum(mask)
ntpts   <- nrow(esdat)

# Actually let's select only some of those clusters!

###
# Do some of the clustering?

# Get the neighbors for each voxel (i.e., node)
mask3d  <- read.nifti.image(overlap.file)==n
neis    <- find_neighbors_masked(mask3d, nei.opt=3, verbose=T)
## convert the neis from list to a matrix
mat.neis<- matrix(0, nvoxs, nvoxs)
for (i in 1:length(neis)) mat.neis[i,neis[[i]]] <- 1
diag(mat.neis) <- 1

# Compute similarity between all voxels in overlap
# and then mask this by the neighbors
smat    <- cor(esdat)
smat    <- smat * mat.neis


tmp.cls <- llply(seq(2,20,by=4), function(k) kmeans(smat, k, iter.max=200, nstart=20), .progress="text")
write.nifti(tmp.cls[[2]]$cluster, hdr, mask, outfile="tmpclust_kmeans.nii.gz", datatype=2, overwrite=T)

library(dynamicTreeCut)
dmat    <- sqrt(2 * (1 - cor(esdat)))
d       <- as.dist(dmat)
d       <- dist(t(esdat))
dmat    <- as.matrix(d)
hc      <- hclust(d, method="ward.D2")
tmp.cl2 <- cutreeDynamic(hc, minClusterSize=20, distM=dmat)
table(tmp.cl2)
write.nifti(tmp.cl2, hdr, mask, outfile="tmpclust_treecut.nii.gz", datatype=2, overwrite=T)


library(fpc)
dmat    <- sqrt(2 * (1 - smat))
d       <- as.dist(dmat)
tmp.cl3 <- dbscan(d, 0.2)

mydata <- d
wss <- (nrow(mydata)-1)*sum(apply(mydata,2,var))
  for (i in 2:15) wss[i] <- sum(kmeans(mydata,
                                       centers=i)$withinss)


c(50850.41, sapply(tmp.cls, function(x) x$tot.withinss))

sapply(tmp.cls, function(x) x$tot.withinss)

#source("/mnt/nfs/psych/rparcellate/command/lib/region_growing.R")
