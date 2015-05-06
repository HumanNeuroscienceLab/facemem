#!/usr/bin/env bash

# Runs 3dttest+ on the resulting maps

base="/mnt/nfs/psych/faceMemoryMRI"
subsdir="${base}/analysis/subjects"
name="prob_fh"
odir="${base}/analysis/groups/Localizer/${name}.dr"
mkdir ${odir} 2> /dev/null

# Create mask
3dMean -overwrite -mask_inter -prefix ${odir}/grp_mask.nii.gz ${subsdir}/*/Localizer/reg_standard/mask.nii.gz
3dcalc -overwrite -a ${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask_dil.nii.gz -b ${odir}/grp_mask.nii.gz -expr 'step(a)*step(b)' -prefix ${odir}/mask.nii.gz

# Run Analysis
3dttest++ -overwrite \
  -paired \
  -mask ${odir}/mask.nii.gz \
  -setA ${subsdir}/*/Localizer/dr/${name}_stage2_Z_to_std0000.nii.gz \
  -labelA face \
  -setB ${subsdir}/*/Localizer/dr/${name}_stage2_Z_to_std0001.nii.gz \
  -labelB scene \
  -toz \
  -prefix ${odir}/stat_bucket.nii.gz

ln -s $FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz ${odir}/standard_2mm.nii.gz
ln -s $FSLDIR/data/standard/MNI152_T1_1mm_brain.nii.gz ${odir}/standard_1mm.nii.gz

# Detect the peaks
## first extract the face result
3dcalc -overwrite -a ${odir}/stat_bucket.nii.gz'[3]' -expr a -prefix ${odir}/zstat_face.nii.gz
## smooth
3dBlurInMask -overwrite -input ${odir}/zstat_face.nii.gz -FWHM 4 -mask ${odir}/mask.nii.gz -prefix ${odir}/zstat_face_blurred.nii.gz
## detect those peaks
3dExtrema -maxima -volume -closure -sep_dist 16 -mask_file ${odir}/mask.nii.gz ${odir}/zstat_face_blurred.nii.gz > ${odir}/peaks.txt
# note that afni gets the L/R wrong relative to what we are used to with FSL
# so we need to slip the x-axis sign
tail ${odir}/peaks.txt
tail -n+11 ${odir}/peaks.txt | awk '{print -1*$3,-1*$4,$5}' > ${odir}/peaks_simple.txt
cat -n ${odir}/peaks_simple.txt | awk '{print -$2,$3,$4,$1}' > ${odir}/peaks_use.txt
## generate spheres
cat ${odir}/peaks_use.txt | 3dUndump -overwrite -prefix ${odir}/peaks.nii.gz -master $FSLDIR/data/standard/MNI152_T1_2mm.nii.gz -mask ${odir}/mask.nii.gz -xyz -srad 6 -


adir="${base}/analysis/groups/mni152/anat"
3dBlurInMask -overwrite -input ${odir}/zstat_face.nii.gz -FWHM 4 -mask ${adir}/lh_antfusiform.nii.gz -prefix ${odir}/zstat_face_blurred.nii.gz
## detect those peaks
3dExtrema -maxima -volume -closure -sep_dist 16 -mask_file ${adir}/lh_antfusiform.nii.gz ${odir}/zstat_face_blurred.nii.gz > ${odir}/peaks.txt
# note that afni gets the L/R wrong relative to what we are used to with FSL
# so we need to slip the x-axis sign
tail ${odir}/peaks.txt
tail -n+11 ${odir}/peaks.txt | awk '{print -1*$3,-1*$4,$5}' > ${odir}/peaks_simple.txt
cat -n ${odir}/peaks_simple.txt | awk '{print -$2,$3,$4,$1}' > ${odir}/peaks_use.txt
## generate spheres
cat ${odir}/peaks_use.txt | 3dUndump -overwrite -prefix ${odir}/peaks.nii.gz -master $FSLDIR/data/standard/MNI152_T1_2mm.nii.gz -mask ${adir}/lh_antfusiform.nii.gz -xyz -srad 6 -

