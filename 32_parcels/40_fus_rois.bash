#!/usr/bin/env bash

# Use freesurfer segmented MNI152 brain to get the fusiform
# Only take y values between -30 and -60 to get the mid-fusiform
# Above -30 is the ant-fusiform and behind -60 is the post-fusiform
# Dilate the fusiform mask by 1
# and also fill any holes between collatoral and inferior temporal sulci
# Multiply by the face>house probabilistic atlas

run() {
  echo "$@"
  eval "$@"
  return $?
}

mni="/mnt/nfs/psych/faceMemoryMRI/analysis/groups/mni152"
std="${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz"

indir="${mni}/freesurfer/aparc_DKTatlas40"
roidir="/mnt/nfs/psych/faceMemoryMRI/analysis/groups/Localizer/parcels_migp"
pardir="${roidir}/group_region_growing"
outdir="/mnt/nfs/psych/faceMemoryMRI/analysis/groups/Localizer/parcels_migp/rois"
ow=" -overwrite"

run "mkdir ${outdir} 2> /dev/null"

# copy over the parcellations into the other directory
echo
echo "Soft-link parcellations"
run "ln -sf ${pardir}/parcels_relabel.nii.gz ${outdir}/parcels.nii.gz"

echo
echo "Use freesurfer segmented MNI152 brain to get the fusiform"
run "3dresample${ow} -inset ${indir}/lh_fusiform.nii.gz -master ${std} -prefix ${outdir}/lh_fusiform.nii.gz"
run "3dresample${ow} -inset ${indir}/rh_fusiform.nii.gz -master ${std} -prefix ${outdir}/rh_fusiform.nii.gz"

echo
echo "Dilate the fusiform mask and fill holes"
run "3dmask_tool -overwrite -inputs ${outdir}/lh_fusiform.nii.gz -dilate_input 2 -1 -fill_holes -prefix ${outdir}/lh_fusiform.nii.gz"
run "3dmask_tool -overwrite -inputs ${outdir}/rh_fusiform.nii.gz -dilate_input 2 -1 -fill_holes -prefix ${outdir}/rh_fusiform.nii.gz"
run "3dcalc${ow} -a ${outdir}/lh_fusiform.nii.gz -b ${outdir}/rh_fusiform.nii.gz -expr 'a+b' -prefix ${outdir}/fusiform.nii.gz"

echo
echo "Only take y values between -30 and -60 to get the mid-fusiform"
run "3dcalc${ow} -a ${std} -expr 'step(y-28)*step(62-y)' -prefix ${outdir}/tmp_slices_mask.nii.gz"
run "3dcalc${ow} -a ${outdir}/lh_fusiform.nii.gz -b ${outdir}/tmp_slices_mask.nii.gz -expr 'a*b' -prefix ${outdir}/lh_midfusiform.nii.gz"
run "3dcalc${ow} -a ${outdir}/rh_fusiform.nii.gz -b ${outdir}/tmp_slices_mask.nii.gz -expr 'a*b' -prefix ${outdir}/rh_midfusiform.nii.gz"
run "3dcalc${ow} -a ${outdir}/lh_midfusiform.nii.gz -b ${outdir}/rh_midfusiform.nii.gz -expr 'a+b' -prefix ${outdir}/midfusiform.nii.gz"

echo
echo "Only take y values above -30 to get the ant-fusiform"
run "3dcalc${ow} -a ${std} -expr 'step(30-y)' -prefix ${outdir}/tmp_slices_mask.nii.gz"
run "3dcalc${ow} -a ${outdir}/lh_fusiform.nii.gz -b ${outdir}/tmp_slices_mask.nii.gz -expr 'a*b' -prefix ${outdir}/lh_antfusiform.nii.gz"
run "3dcalc${ow} -a ${outdir}/rh_fusiform.nii.gz -b ${outdir}/tmp_slices_mask.nii.gz -expr 'a*b' -prefix ${outdir}/rh_antfusiform.nii.gz"
run "3dcalc${ow} -a ${outdir}/lh_antfusiform.nii.gz -b ${outdir}/rh_antfusiform.nii.gz -expr 'a+b' -prefix ${outdir}/antfusiform.nii.gz"

echo
echo "Only take y values below -60 to get the post-fusiform"
run "3dcalc${ow} -a ${std} -expr 'step(y-60)' -prefix ${outdir}/tmp_slices_mask.nii.gz"
run "3dcalc${ow} -a ${outdir}/lh_fusiform.nii.gz -b ${outdir}/tmp_slices_mask.nii.gz -expr 'a*b' -prefix ${outdir}/lh_postfusiform.nii.gz"
run "3dcalc${ow} -a ${outdir}/rh_fusiform.nii.gz -b ${outdir}/tmp_slices_mask.nii.gz -expr 'a*b' -prefix ${outdir}/rh_postfusiform.nii.gz"
run "3dcalc${ow} -a ${outdir}/lh_postfusiform.nii.gz -b ${outdir}/rh_postfusiform.nii.gz -expr 'a+b' -prefix ${outdir}/postfusiform.nii.gz"
