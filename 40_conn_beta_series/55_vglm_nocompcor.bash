#!/usr/bin/env bash

#Rscript 50_vglm_setup.R

std_mask=${FSLDIR}/data/standard/tissuepriors/3mm/gray_20perc.nii.gz
std=${FSLDIR}/data/standard/MNI152_T1_3mm_brain.nii.gz
base="/mnt/nfs/psych/faceMemoryMRI"
sdir=${base}/analysis/subjects

runtype="Questions"
echo $runtype

echo "saving bio"
ls ${sdir}/*/${runtype}/task/beta_series_spmg1_nocompcor.reml/reg_standard/beta_series_bio.nii.gz | head -n 2
ls ${sdir}/*/${runtype}/task/beta_series_spmg1_nocompcor.reml/reg_standard/beta_series_bio.nii.gz > z_betaseries_${runtype}.txt
echo "saving phys"
ls ${sdir}/*/${runtype}/task/beta_series_spmg1_nocompcor.reml/reg_standard/beta_series_phys.nii.gz | head -n 2
ls ${sdir}/*/${runtype}/task/beta_series_spmg1_nocompcor.reml/reg_standard/beta_series_phys.nii.gz >> z_betaseries_${runtype}.txt
echo

echo "running voxelwise sbca"
cwas_mask="${base}/analysis/groups/${runtype}/cwas/beta_series_3mm.subdist/mask.nii.gz"
outdir="${base}/analysis/groups/${runtype}/sbca/beta_series_3mm_nocompcor.glm"
connectir_glm.R -i z_betaseries_${runtype}.txt \
  --brainmask1 ${cwas_mask} \
  --ztransform \
  --summarize \
  --regressors y_glm_regressors.txt \
  --contrasts y_glm_contrasts.txt \
  --memlimit 48 \
  --forks 20 \
  --threads 1 \
  $outdir
