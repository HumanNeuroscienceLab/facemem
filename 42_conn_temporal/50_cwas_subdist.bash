#!/usr/bin/env bash

#res=4
res=3

std_mask=${FSLDIR}/data/standard/tissuepriors/${res}mm/gray_20perc.nii.gz
std=${FSLDIR}/data/standard/MNI152_T1_${res}mm_brain.nii.gz
base="/mnt/nfs/psych/faceMemoryMRI"
sdir=${base}/analysis/subjects

runtype="Questions"
echo $runtype

echo "saving bio"
ls ${sdir}/*/${runtype}/connectivity/task_residuals.reml/residuals_bio_to_std_${res}mm.nii.gz
ls ${sdir}/*/${runtype}/connectivity/task_residuals.reml/residuals_bio_to_std_${res}mm.nii.gz > z_taskresids_${runtype}.txt
echo "saving phys"
ls ${sdir}/*/${runtype}/connectivity/task_residuals.reml/residuals_phys_to_std_${res}mm.nii.gz
ls ${sdir}/*/${runtype}/connectivity/task_residuals.reml/residuals_phys_to_std_${res}mm.nii.gz >> z_taskresids_${runtype}.txt
echo

echo "running cwas"
outdir="${base}/analysis/groups/${runtype}/cwas/task_residuals_${res}mm.subdist"
connectir_subdist.R -i z_taskresids_${runtype}.txt \
  --automask1 \
  --brainmask1 ${std_mask} \
  --ztransform \
  --bg $std \
  --memlimit 36 \
  --forks 16 \
  --threads 1 \
  $outdir
