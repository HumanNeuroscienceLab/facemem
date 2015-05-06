#!/usr/bin/env bash

#roi="l_atl"
runtypes="Questions NoQuestions"
res=3

base="/mnt/nfs/psych/faceMemoryMRI"
subsdir="${base}/analysis/subjects"
grpdir="${base}/analysis/groups"

for runtype in ${runtypes}; do
  echo ${runtype}

  outdir="${grpdir}/${runtype}/global/voxs_3mm"

  mkdir ${outdir} 2> /dev/null
  cd ${outdir}

  cp -f ${grpdir}/${runtype}/global/mask.nii.gz ${outdir}/mask.nii.gz
  ln -sf $FSLDIR/data/standard/MNI152_T1_1mm_brain.nii.gz standard_1mm.nii.gz
  ln -sf $FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz standard_2mm.nii.gz
  ln -sf $FSLDIR/data/standard/MNI152_T1_3mm_brain.nii.gz standard_3mm.nii.gz

  echo "zmean"
  3dttest++ \
    -overwrite \
    -prefix stats_zmean.nii.gz \
    -mask mask.nii.gz \
    -setA ${subsdir}/tb*/${runtype}/connectivity/task_residuals.reml/gcor_zmean_bio_${res}mm.nii.gz \
    -labelA bio \
    -setB ${subsdir}/tb*/${runtype}/connectivity/task_residuals.reml/gcor_zmean_phys_${res}mm.nii.gz \
    -labelB phys \
    -paired \
    -toz
  
  # For the thresh values, there are three 0.1, 0.2, and 0.3
  # do each separately
  thrs=( 1 2 3 )
  for (( i = 0; i < 3; i++ )); do
    echo "thr ${thrs[$i]}"
    biofiles=$( ls ${subsdir}/tb*/${runtype}/connectivity/task_residuals.reml/gcor_thresh_bio_${res}mm.nii.gz | sed s/'nii.gz$'/"nii.gz[$i]"/g | tr '\n' ' ' )
    physfiles=$( ls ${subsdir}/tb*/${runtype}/connectivity/task_residuals.reml/gcor_thresh_phys_${res}mm.nii.gz | sed s/'nii.gz$'/"nii.gz[$i]"/g | tr '\n' ' ' )
    echo "3dttest++ \
      -overwrite \
      -prefix stats_thresh_${thrs[$i]}.nii.gz \
      -mask mask.nii.gz \
      -setA ${biofiles} \
      -labelA bio \
      -setB ${physfiles} \
      -labelB phys \
      -paired \
      -toz"
    3dttest++ \
      -overwrite \
      -prefix stats_thresh_${thrs[$i]}.nii.gz \
      -mask mask.nii.gz \
      -setA "${biofiles}" \
      -labelA bio \
      -setB "${physfiles}" \
      -labelB phys \
      -paired \
      -toz
  done
  
  echo
done
