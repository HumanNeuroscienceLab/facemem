#!/usr/bin/env bash

std_mask=${FSLDIR}/data/standard/tissuepriors/3mm/gray_20perc.nii.gz
std=${FSLDIR}/data/standard/MNI152_T1_3mm_brain.nii.gz
base="/mnt/nfs/psych/faceMemoryMRI"
sdir=${base}/analysis/subjects

runtype="Questions"
echo $runtype

echo "saving bio"
ls ${sdir}/*/${runtype}/task/beta_series_spmg1_nocompcor.reml/reg_standard/beta_series_bio.nii.gz
ls ${sdir}/*/${runtype}/task/beta_series_spmg1_nocompcor.reml/reg_standard/beta_series_bio.nii.gz > z_betaseries_${runtype}.txt
echo "saving phys"
ls ${sdir}/*/${runtype}/task/beta_series_spmg1_nocompcor.reml/reg_standard/beta_series_phys.nii.gz
ls ${sdir}/*/${runtype}/task/beta_series_spmg1_nocompcor.reml/reg_standard/beta_series_phys.nii.gz >> z_betaseries_${runtype}.txt
echo

#tmpdir=$(mktemp -d)
#echo "masking ${tmpdir}"
#i=0
#while read fn; do
#  i=$(( $i + 1 ))
#  echo $i
#  fslmaths ${fn} -Tstd -bin ${tmpdir}/mask_${i}.nii.gz
#done < z_betaseries_${runtype}.txt
#3dMean -mask_inter -prefix ${tmpdir}/grp_mask.nii.gz ${tmpdir}/mask_*.nii.gz
#fslmaths ${tmpdir}/grp_mask.nii.gz -mas ${std_mask} ${tmpdir}/grp_mask_gray.nii.gz

echo "running cwas"
outdir="${base}/analysis/groups/${runtype}/cwas/beta_series_3mm_nocompcor.subdist"
connectir_subdist.R -i z_betaseries_${runtype}.txt \
  --automask1 \
  --brainmask1 ${std_mask} \
  --ztransform \
  --bg $std \
  --memlimit 36 \
  --forks 16 \
  --threads 1 \
  $outdir

#rm -r ${tmpdir}
