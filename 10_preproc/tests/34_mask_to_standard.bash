#!/usr/bin/env bash

# Transform the functional mask to standard space for each subject

#std_mask=$FSLDIR/data/standard/MNI152_T1_2mm_brain_mask_dil.nii.gz
basedir="/mnt/nfs/psych/faceMemoryMRI/analysis"
inbase="/mnt/nfs/psych/faceMemoryMRI/analysis/subjects"
runtype="Questions"
subjs=$( cat sublist_14.txt )

# Generate masks in standard space
parallel --no-notice -j 16 --eta \
  applywarp -i ${inbase}/{}/${runtype}/preproc/mask.nii.gz -r ${basedir}/fsl/${runtype}/{}/run01.feat/reg/standard.nii.gz -o ${inbase}/{}/${runtype}/preproc/mask_to_standard.nii.gz -w ${basedir}/fsl/${runtype}/{}/run01.feat/reg/example_func2standard_warp.nii.gz --interp=nn ::: ${subjs}  
