#!/usr/bin/env bash

#roi="l_atl"
runtype=Questions

genname="prob_atlas"

base="/mnt/nfs/psych/faceMemoryMRI"
subsdir="${base}/analysis/subjects"
grpdir="${base}/analysis/groups"
outdir="${grpdir}/${runtype}/connectivity/tconn_${genname}"

rois="r_ofa r_ffa r_atl r_atl2 l_ofa l_ffa l_atl l_atl2"

mkdir ${grpdir}/${runtype}/connectivity 2> /dev/null
mkdir ${outdir} 2> /dev/null
cd ${outdir}

3dMean -overwrite -mask_inter -prefix mask.nii.gz ${subsdir}/tb*/${runtype}/reg_standard/mask.nii.gz
3dcalc -overwrite -a mask.nii.gz -b $FSLDIR/data/standard/MNI152_T1_2mm_brain_mask_dil.nii.gz -expr 'a*b' -prefix mask.nii.gz

for roi in ${rois}; do
  echo $roi
  3dttest++ \
    -prefix stats_${roi}.nii.gz \
    -mask mask.nii.gz \
    -setA ${subsdir}/tb*/${runtype}/connectivity/task_residuals.reml/std_z_conn_${genname}_${roi}_bio.nii.gz \
    -labelA bio \
    -setB ${subsdir}/tb*/${runtype}/connectivity/task_residuals.reml/std_z_conn_${genname}_${roi}_phys.nii.gz \
    -labelB phys \
    -paired \
    -toz
  echo
done

ln -s $FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz standard_2mm.nii.gz