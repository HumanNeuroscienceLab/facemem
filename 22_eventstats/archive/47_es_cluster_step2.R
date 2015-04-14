library(dynamicTreeCut)

setwd("/data/psych/faceMemoryMRI/analysis/groups/Questions/task/eventstats_cluster_01")

dat   <- read.table("group_parcel.1D")
dd    <- dist(dat)
dmat  <- as.matrix(dd)
hc    <- hclust(dd)
cl    <- cutreeDynamic(hc, minClusterSize=10, distM=dmat)
write.table(cl, file="group_parcel_clust.txt", row.names=F, col.names=F, quote=F)

rois2voxelwise <- function(roi.data, vox.rois) {
    vox.data <- vector("numeric", length(vox.rois))

    urois <- sort(unique(vox.rois))
    urois <- urois[urois!=0]
    nrois <- length(urois)

    for (ri in 1:nrois)
        vox.data[vox.rois==urois[ri]] <- roi.data[ri]

    return(vox.data)
}

suppressMessages(library(niftir))
res <- rois2voxelwise(cl, read.mask("region_growing/parcels_relabel.nii.gz", NULL))

hdr <- read.nifti.header("region_growing/parcels_relabel.nii.gz")
write.nifti(res, hdr, outfile="group_parcel_clust.nii.gz", overwrite=T)

system("/mnt/nfs/psych/faceMemoryMRI/scripts/connpaper/20_task/roi_to_voxelwise.R group_parcel_clust.txt region_growing/parcels_relabel.nii.gz group_parcel_clust.nii.gz")



cl    <- kmeans(dat, 20, iter.max=200, nstart=2)
res   <- rois2voxelwise(cl$cluster, read.mask("region_growing/parcels_relabel.nii.gz", NULL))
hdr   <- read.nifti.header("region_growing/parcels_relabel.nii.gz")
write.nifti(res, hdr, outfile="group_parcel_clust_kmeans20.nii.gz", overwrite=T)
