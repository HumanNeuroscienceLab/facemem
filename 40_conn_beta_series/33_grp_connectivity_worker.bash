#!/usr/bin/env bash

roi="l_atl"
runtype=Questions

genname="prob_atlas"

base="/mnt/nfs/psych/faceMemoryMRI"
subsdir="${base}/analysis/subjects"
grpdir="${base}/analysis/groups"
outdir="${grpdir}/${runtype}/connectivity/beta_series_${genname}"

rois="r_ofa r_ffa r_atl l_ofa l_ffa l_atl"

mkdir ${grpdir}/${runtype}/connectivity 2> /dev/null
mkdir ${outdir} 2> /dev/null
cd ${outdir}

3dMean -overwrite -mask_inter -prefix mask.nii.gz ${subsdir}/tb*/${runtype}/reg_standard/mask_3mm.nii.gz

for roi in ${rois}; do
  echo $roi
  3dttest++ -prefix stats_${roi}.nii.gz -mask mask.nii.gz -setA ${subsdir}/tb*/${runtype}/connectivity/beta_series_${genname}_${roi}_bio.nii.gz -labelA bio -setB ${subsdir}/tb*/${runtype}/connectivity/beta_series_${genname}_${roi}_phys.nii.gz -labelB phys -paired -toz
  echo
done
