#!/usr/bin/env bash

noqdir="/mnt/nfs/psych/faceMemoryMRI/analysis/groups/NoQuestions/task/noquestions_task_smoother.mema"
cd /mnt/nfs/psych/faceMemoryMRI/analysis/groups/Questions/task/questions_task_smoother.mema
mkdir conn_peaks
cd conn_peaks

# 1. Average the bio and phys results
3dcalc -overwrite -a ../zstats_bio.nii.gz -b ../zstats_phys.nii.gz -expr '(a+b)/2' -prefix zstats_bio_n_phys_q.nii.gz
3dcalc -overwrite -a ${noqdir}/zstats_bio.nii.gz -b ${noqdir}/zstats_phys.nii.gz -expr '(a+b)/2' -prefix zstats_bio_n_phys_noq.nii.gz
3dcalc -overwrite -a zstats_bio_n_phys_q.nii.gz -b zstats_bio_n_phys_noq.nii.gz -expr '(a+b)/2' -prefix zstats_bio_n_phys.nii.gz

#3dcalc -a ../zstats_bio.nii.gz -b ${noqdir}/zstats_bio.nii.gz -expr '(a+b)/2' -prefix zstats_bio.nii.gz

# afni or fsl (fsl seems to include psts)
#/mnt/nfs/psych/faceMemoryMRI/scripts/connpaper/lib/apply_clustsim.R ../ClustSim.NN3 0.05 0.1 zstats_bio_n_phys.nii.gz thresh_zstats_bio_n_phys.nii.gz

# 2. Apply cluster threshold to the combined results
easythresh zstats_bio_n_phys.nii.gz ../mask.nii.gz 1.96 0.05 ../standard_2mm.nii.gz pos_zstats

# 3. mask by grey matter (and remove any remaining small clusters)
3dcalc -overwrite -a ../mask.nii.gz -b /mnt/nfs/psych/rparcellate/rois/ho_maxprob25.nii.gz -expr 'step(a)*step(b)' -prefix mask.nii.gz
3dcalc -overwrite -a thresh_pos_zstats.nii.gz -b mask.nii.gz -expr 'a*step(b)' -prefix thresh_pos_zstats_grey.nii.gz
3dclust -overwrite -savemask clust_pos_zstats_grey_clean.nii.gz -prefix thresh_pos_zstats_grey_clean.nii.gz -1noneg -dxyz=1 0 50 thresh_pos_zstats_grey.nii.gz

# 4. create new mask with combo of HO tissue priors and the cluster of task-based results
#    and smooth within the significant results to make the peak detection a little easier/stable
fwhm=6
3dcalc -overwrite -a /mnt/nfs/psych/rparcellate/rois/ho_maxprob25.nii.gz -b clust_pos_zstats_grey_clean.nii.gz -expr 'step(b)*((a*100)+b)' -prefix clust_ho_mask.nii.gz
#3dBlurInMask -overwrite -input zstats_bio_n_phys.nii.gz -Mmask clust_ho_mask.nii.gz -FWHM ${fwhm} -prefix thresh_pos_zstats_fwhm${fwhm}.nii.gz
3dBlurInMask -overwrite -input zstats_bio.nii.gz -Mmask clust_ho_mask.nii.gz -FWHM ${fwhm} -prefix thresh_pos_zstats_fwhm${fwhm}.nii.gz

#easythresh zstats_bio_n_phys.nii.gz mask.nii.gz 1.96 0.1 ../standard_2mm.nii.gz pos_zstats

## 5. Get the local maxima peak coordinates
#peak_dist=16 # in mm! so this is 8 voxels
#3dExtrema -maxima -volume -closure -sep_dist ${peak_dist} -mask_file mask.nii.gz thresh_pos_zstats_fwhm${fwhm}.nii.gz > pos_peaks_orig.txt
#tail -n+11 pos_peaks_orig.txt | awk '{print -1*$3,-1*$4,$5,$1}' > pos_peaks.txt
#wc -l pos_peaks.txt
#
## 6. Create the peak ROIs with a 6mm (3 voxel) radius
#srad=4
#cat pos_peaks.txt | 3dUndump -overwrite -prefix pos_peaks.nii.gz -master ../standard_2mm.nii.gz -mask mask.nii.gz -xyz -srad ${srad} -
#
#cat pos_peaks.txt | 3dUndump -overwrite -prefix pos_peaks.nii.gz -master ../standard_2mm.nii.gz -mask tmp_mask.nii.gz -xyz -srad ${srad} -
#cat tmp_pos_peaks_2.txt | 3dUndump -overwrite -prefix pos_peaks.nii.gz -master ../standard_2mm.nii.gz -mask tmp_mask.nii.gz -xyz -srad ${srad} -


# unique HO values: 1 2 3 11 12 13
#hovals="1 2 3 11 12 13"
hovals="1 2 11 12"
rm pos_peaks_simple.txt pos_peaks.nii.gz
touch pos_peaks_simple.txt
3dcalc -a mask.nii.gz -expr 'a*0' -prefix pos_peaks.nii.gz
maxval=0
for hoval in ${hovals}; do
  echo
  echo "hoval: ${hoval}"
  
  3dcalc -overwrite -a ../mask.nii.gz -b /mnt/nfs/psych/rparcellate/rois/ho_maxprob25.nii.gz -expr "step(a)*equals(b,${hoval})" -prefix tmp_mask_dil.nii.gz
  3dmask_tool -overwrite -input tmp_mask_dil.nii.gz -prefix tmp_mask.nii.gz -dilate_inputs -1
  
  peak_dist=16 # in mm! so this is 8 voxels
  3dExtrema -maxima -volume -closure -sep_dist ${peak_dist} -mask_file tmp_mask.nii.gz thresh_pos_zstats_fwhm${fwhm}.nii.gz > tmp_pos_peaks.txt
  tail -n+11 tmp_pos_peaks.txt | awk '{print -1*$3,-1*$4,$5}' >> pos_peaks_simple.txt
  
  srad=4
  tail -n+11 tmp_pos_peaks.txt | awk '{print $3,-1*$4,$5}' | awk '{printf("%s %5d\n", $0,NR)}' > tmp_pos_peaks_2.txt
  cat tmp_pos_peaks_2.txt | 3dUndump -overwrite -prefix tmp_pos_peaks.nii.gz -master ../standard_2mm.nii.gz -mask tmp_mask_dil.nii.gz -xyz -srad ${srad} -
  
  maxval=$(3dBrickStat -max -slow pos_peaks.nii.gz)
  3dcalc -overwrite -a pos_peaks.nii.gz -b tmp_pos_peaks.nii.gz -expr "a + (b+${maxval})*step(b)" -prefix pos_peaks_x.nii.gz
  mv pos_peaks_x.nii.gz pos_peaks.nii.gz
  
  tail -n+11 tmp_pos_peaks.txt | wc -l 
  rm tmp_mask.nii.gz tmp_pos_peaks.txt tmp_pos_peaks_2.txt tmp_pos_peaks.nii.gz
done
awk '{printf("%s %5d\n", $0,NR)}' pos_peaks_simple.txt > pos_peaks.txt
wc -l pos_peaks.txt




## 5. Get the local maxima peak coordinates
#peak_dist=16 # in mm! so this is 8 voxels
#3dcalc -overwrite -a ../mask.nii.gz -b /mnt/nfs/psych/rparcellate/rois/ho_maxprob25.nii.gz -expr "step(a)*(equals(b,1)+equals(b,2)+equals(b,11)+equals(b,12))" -prefix tmp_mask.nii.gz
#3dExtrema -maxima -volume -closure -sep_dist ${peak_dist} -mask_file tmp_mask.nii.gz thresh_pos_zstats_fwhm${fwhm}.nii.gz > pos_peaks_orig.txt
#tail -n+11 pos_peaks_orig.txt | awk '{print -1*$3,-1*$4,$5,$1}' > pos_peaks.txt
#wc -l pos_peaks.txt
#
## 6. Create the peak ROIs with a 6mm (3 voxel) radius
#srad=4
#cat pos_peaks.txt | 3dUndump -overwrite -prefix pos_peaks.nii.gz -master ../standard_2mm.nii.gz -mask tmp_mask.nii.gz -xyz -srad ${srad} -

cp /mnt/nfs/psych/rparcellate/rois/ho_maxprob25.nii.gz .