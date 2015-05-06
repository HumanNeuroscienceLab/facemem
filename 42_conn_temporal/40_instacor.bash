#!/usr/bin/env bash

function run() {
  echo "$@"
  eval "$@"
  return $?
}

inbase="/mnt/nfs/psych/faceMemoryMRI/analysis/subjects"
outbase="/mnt/nfs/psych/faceMemoryMRI/analysis/groups"

runtypes="Questions NoQuestions"
conditions="bio phys"

res=3


#--- instacor setup ---#

for runtype in ${runtypes}; do
  echo "runtype: ${runtype}"
  
  outdir=${outbase}/${runtype}/instacor
  mkdir ${outdir} 2> /dev/null
  cd ${outdir}
  
  # Mask
  prop=${outdir}/prop_subjects.nii.gz
  mask=${outdir}/mask.nii.gz
  run "3dMean -prefix ${prop} ${inbase}/*/${runtype}/reg_standard/mask_${res}mm.nii.gz"
  run "3dresample -inset $FSLDIR/data/standard/MNI152_T1_1mm_brain_mask.nii.gz -master $FSLDIR/data/standard/MNI152_T1_${res}mm_brain.nii.gz -prefix mask_std.nii.gz -rmode NN"
  run "3dcalc -a ${prop} -b mask_std.nii.gz -expr 'equals(a,1)*step(b)' -prefix ${mask}"
  
  # Data
  for condition in ${conditions}; do
    echo "...condition: ${condition}"
    run "3dSetupGroupInCorr -prep DEMEAN -byte -mask ${mask} -prefix ${outdir}/time_series_${condition} ${inbase}/*/${runtype}/connectivity/task_residuals.reml/residuals_${condition}_to_std_${res}mm.nii.gz"
  done
  
  # Underlay
  run "ln -s $FSLDIR/data/standard/MNI152_T1_1mm_brain.nii.gz standard_1mm.nii.gz"
  run "ln -s $FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz standard_2mm.nii.gz"
  
  cd -
done


# To run:
# cd /mnt/nfs/psych/faceMemoryMRI/analysis/groups/Questions/instacor
# 3dGroupInCorr -setA time_series_bio.grpincorr.niml -setB time_series_phys.grpincorr.niml -labelA bio -labelB phys -paired -seedrad 6
# afni -niml -yesplugouts
