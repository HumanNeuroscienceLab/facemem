#!/usr/bin/env bash

# This script will generate the same vATL/FFA/OFA ROIs from the probabilistic atlas
# except this time, the ROIs will have a 5 voxel radius more appropriate for classification

function run() {
  echo "$@"
  eval "$@"
  return $?
}

odir="../rois"

# Extract the vATL/FFA/OFA ROIs from the prob atlas peaks
# radius of ROIs is same as that for eventstats analysis
# 1=R OFA, 2=R FFA, 3=R vATL, 4=L OFA, 5=L FFA, 6=L vaTL
run "3dcalc -overwrite -a ${odir}/face_gt_house+scene.nii.gz -expr 'step(equals(a,3))*1+step(equals(a,1))*2+step(equals(a,69))*3+step(equals(a,8))*4+step(equals(a,2))*5+step(equals(a,62))*6'" -prefix ${odir}/classify_probpeaks_small.nii.gz

## Generate larger ROIs for classification
#echo "mask"
#run "3dcalc -overwrite -a /mnt/nfs/psych/faceMemoryMRI/analysis/groups/Combo/overlap/ho_maxprob25.nii.gz -b /mnt/nfs/psych/faceMemoryMRI/analysis/groups/Combo/overlap/mask.nii.gz -expr 'step(equals(a,1)+equals(a,11))*step(b)' -prefix tmp_mask.nii.gz"

#echo "rois"
#run "cat z_coords2.txt | 3dUndump -overwrite -prefix ${odir}/classify_probpeaks.nii.gz -master $FSLDIR/data/standard/MNI152_T1_2mm.nii.gz -mask tmp_mask.nii.gz -xyz -srad 12 -"


## Now generate ROIs specific to the lffa and lvatl
## where we roughly match the size of the two ROIs
#echo "40 -50 -18" | 3dUndump -overwrite -prefix ${odir}/classify_lffa.nii.gz -master $FSLDIR/data/standard/MNI152_T1_2mm.nii.gz -mask tmp_mask.nii.gz -xyz -srad 12 -
#3dBrickStat -count -non-zero ${odir}/classify_lffa.nii.gz

#echo "42 -18 -25" | 3dUndump -overwrite -prefix ${odir}/classify_lvatl.nii.gz -master $FSLDIR/data/standard/MNI152_T1_2mm.nii.gz -mask tmp_mask.nii.gz -xyz -srad 13 -
#3dclust -1noneg -dxyz=1 0 10 ${odir}/classify_lvatl.nii.gz
#3dBrickStat -count -non-zero ${odir}/classify_lvatl.nii.gz


#echo "clean"
#run "rm tmp_mask.nii.gz"
