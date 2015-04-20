#!/usr/bin/env bash

# This script will 

function run() {
  echo "$@"
  eval "$@"
  return $?
}


###
# Setup

base="/mnt/nfs/psych/faceMemoryMRI"
grpdir="${base}/analysis/groups"
outdir="${grpdir}/Combo/overlap"
cd ${outdir}


###
# Peak Detection

# 0. Setup Inputs
run "ln -s ${grpdir}/Questions/task/questions_task_smoother.mema/easythresh/thresh_zstat_bio_vs_phys.nii.gz orig_questions.nii.gz"
run "ln -s ${grpdir}/NoQuestions/task/noquestions_task_smoother.mema/easythresh/thresh_zstat_bio_vs_phys.nii.gz orig_noquestions.nii.gz"
run "3dcalc -a ${grpdir}/Questions/task/questions_task_smoother.mema/mask.nii.gz -b ${grpdir}/NoQuestions/task/noquestions_task_smoother.mema/mask.nii.gz -expr 'a*b' -prefix mask.nii.gz"

# 1. Create the overlap map
#    - binarized and threshold zstat versions
echo "overlap map"
run "3dcalc -a orig_questions.nii.gz -b orig_noquestions.nii.gz -expr 'step(a)*step(b)*((a+b)/2)' -prefix overlap_zstat.nii.gz"
run "3dcalc -a orig_questions.nii.gz -b orig_noquestions.nii.gz -expr 'step(a)*step(b)' -prefix overlap_bin.nii.gz"
run "mask_"

# 2. Create version with only grey-matter
#    - fill in the middle part with R
echo "grey matter masked"
run "3dcalc -a overlap_zstat.nii.gz -b ho_maxprob25_edit.nii.gz -expr 'a*step(b)' -prefix overlap_zstat_masked.nii.gz"
run "3dcalc -a overlap_bin.nii.gz -b ho_maxprob25_edit.nii.gz -expr 'a*step(b)' -prefix overlap_bin_masked.nii.gz"
run "3dcalc -a mask.nii.gz -b ho_maxprob25_edit.nii.gz -expr 'a*step(b)' -prefix mask_masked.nii.gz"

# 3. Smooth the map by some amount
fwhm=6
echo "smooth by ${fwhm}"
run "3dBlurInMask -overwrite -input overlap_zstat.nii.gz -mask overlap_bin.nii.gz -FWHM ${fwhm} -prefix overlap_zstat_smooth.nii.gz"
run "3dBlurInMask -overwrite -input overlap_zstat_masked.nii.gz -mask overlap_bin_masked.nii.gz -FWHM ${fwhm} -prefix overlap_zstat_masked_smooth.nii.gz"

## 4. Spatially cluster the map
#echo "spatial cluster"
#run "3dclust -overwrite -savemask overlap_clust_masked.nii.gz -dxyz=1 3 25 overlap_bin_masked.nii.gz > clust_table.txt"
#nclusts=$( grep -v '#' clust_table.txt | wc -l )
#for (( i = 1; i <= ${nclusts}; i++ )); do
#  run "3dcalc -a overlap_clust_masked.nii.gz -expr 'step(equals(a,$i))' -prefix overlap_clust_masked_k${i}.nii.gz"
#done

# 4. Do the peak detection
echo "peak detection"
run "rm overlap_peaks_masked_simple.txt overlap_peaks_masked_use.txt"
run "touch overlap_peaks_masked_simple.txt overlap_peaks_masked_use.txt"
#for (( i = 1; i <= ${nclusts}; i++ )); do
#  run "3dExtrema -maxima -volume -closure -sep_dist 16 -mask_file overlap_clust_masked_k${i}.nii.gz overlap_zstat_masked_smooth.nii.gz > overlap_peaks_masked_k${i}.txt"
#  tail -n+11 overlap_peaks_masked_k${i}.txt | awk '{print -1*$3,-1*$4,$5}' >> overlap_peaks_masked_simple.txt
#  tail overlap_peaks_masked_k${i}.txt
#done
run "3dExtrema -maxima -volume -closure -sep_dist 16 -mask_file overlap_bin_masked.nii.gz overlap_zstat_masked_smooth.nii.gz > overlap_peaks_masked.txt"
tail -n+11 overlap_peaks_masked.txt | awk '{print -1*$3,-1*$4,$5}' > overlap_peaks_masked_simple.txt
# note that afni gets the L/R wrong relative to what we are used to with FSL
# so we need to slip the x-axis sign
cat -n overlap_peaks_masked_simple.txt | awk '{print -$2,$3,$4,$1}' > overlap_peaks_masked_use.txt

# 5. Generate the spheres
echo "generate peak spheres/rois"
cat overlap_peaks_masked_use.txt | 3dUndump -overwrite -prefix peaks_masked.nii.gz -master $FSLDIR/data/standard/MNI152_T1_2mm.nii.gz -mask mask_masked.nii.gz -xyz -srad 6 -

# 6. Mask the spheres by the overlap mask (dilated by 1)
run "3dmask_tool -overwrite -input overlap_bin_masked.nii.gz -dilate_input 1 -prefix overlap_bin_masked_dil.nii.gz"
run "3dcalc -overwrite -a overlap_bin_masked_dil.nii.gz -b mask.nii.gz -expr 'step(a)*step(b)' -prefix overlap_bin_masked_dil.nii.gz"
run "3dcalc -overwrite -a peaks_masked.nii.gz -b overlap_bin_masked_dil.nii.gz -expr 'a*step(b)' -prefix peaks_masked_masked.nii.gz"

# copy over at the end
run "3dcalc -a peaks_masked_masked.nii.gz -expr a -prefix ${base}/scripts/connpaper/rois/overlap_peaks.nii.gz -byte"
