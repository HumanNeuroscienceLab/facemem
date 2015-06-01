#!/usr/bin/env bash

# Get's the center of mass for the vATL parcel

parcel <- system("3dCM rois/voxs_parcel397.nii.gz", intern=T)
parcel <- as.numeric(strsplit(parcel, "  ")[[1]])
parcel <- parcel * c(-1,-1,1)
aFus <- c(-42, -28, -20)
vATL <- c(-34, -6, -34)

mat <- rbind(parcel=parcel, aFus=aFus, vATL=vATL)
mat <- round(mat, 1)
colnames(mat) <- c("x", "y", "z")
print(mat)

dist(mat)
