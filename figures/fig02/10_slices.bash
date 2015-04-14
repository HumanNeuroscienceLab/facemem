#!/usr/bin/env bash

base=/mnt/nfs/psych/faceMemoryMRI
grp="${base}/analysis/groups"

cd ${grp}/Combo/oblique_slice

echo "all of the overlays are of bio vs phys" > bio_vs_phys


#--- COPY ---#

# Standard
cp $FSLDIR/data/standard/MNI152_T1_1mm_brain.nii.gz standard.nii.gz

# Masked Thresholded Data
3dcalc -a ${grp}/Questions/task/questions_task_smoother.mema/easythresh/thresh_zstat_bio_vs_phys.nii.gz -expr 'step(abs(a))' -prefix clust_questions.nii.gz
3dcalc -a ${grp}/NoQuestions/task/noquestions_task_smoother.mema/easythresh/thresh_zstat_bio_vs_phys.nii.gz -expr 'step(abs(a))' -prefix clust_noquestions.nii.gz

# Unthresholded Data
3dcalc -a ${grp}/Questions/task/questions_task_smoother.mema/zstats_bio_gt_phys.nii.gz -expr 'a' -prefix zstat_questions.nii.gz
3dcalc -a ${grp}/NoQuestions/task/noquestions_task_smoother.mema/zstats_bio_gt_phys.nii.gz -expr 'a' -prefix zstat_noquestions.nii.gz


#--- ROTATE AND STUFF ---#

# Rotate standard brain
3drotate -overwrite -verbose -heptic -prefix standard_rot20.nii.gz -zpad 10 -rotate -20R 0 0 standard.nii.gz

# Rotate and Threshold
names="questions noquestions"
for name in ${names}; do
  ## rotate
  3drotate -overwrite -verbose -cubic -prefix zstat_${name}_rot.nii.gz -zpad 10 -rotate -20R 0 0 zstat_${name}.nii.gz
  3drotate -overwrite -verbose -NN -prefix clust_${name}_rot.nii.gz -zpad 10 -rotate -20R 0 0 clust_${name}.nii.gz
  ## threshold
  3dcalc -a zstat_${name}_rot.nii.gz -b clust_${name}_rot.nii.gz -expr 'step(abs(a)-1.95)*step(b)*a' -prefix thresh_zstat_${name}_rot.nii.gz
  ## scale
  3dcalc -a thresh_zstat_${name}_rot.nii.gz -expr 'step(a-1.95)*(a-1.95) - (step(-1*a-1.95)*(-1*a-1.95))' -prefix thresh_zstat_${name}_rot_scale.nii.gz
  
done

# Combine for Overlap
3dcalc \
  -a thresh_zstat_questions_rot.nii.gz \
  -b thresh_zstat_noquestions_rot.nii.gz \
  -expr 'step(a)*step(b) - step(a*-1)*step(b*-1)' \
  -prefix overlap_rot.nii.gz

#cp $FSLDIR/data/standard/MNI152_T1_0.5mm.nii.gz standard.nii.gz
#3drotate -overwrite -verbose -heptic -prefix standard_rot20.nii.gz -zpad 10 -rotate -20R 0 0 standard.nii.gz
