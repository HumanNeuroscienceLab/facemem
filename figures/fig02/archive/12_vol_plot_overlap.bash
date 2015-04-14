#!/usr/bin/env bash

# 1. Get overlap
# 2. Plot data on slices
# 3. Plot data on surface

basedir="/mnt/nfs/psych/faceMemoryMRI"
runtypes="Questions NoQuestions"
thr=0

outdir="${basedir}/figures/fig02_task_activity"
mkdir ${outdir} 2> /dev/null

echo
echo "calculate overlaps"
# Calculate overlap (bio>phys)
## overlap_all => 2=questions, 4=noquestions, 6=conjunction
3dcalc \
  -overwrite \
  -a ${basedir}/analysis/groups/Questions/task/questions_task_smoother.mema/easythresh/thresh_zstat_bio_gt_phys.nii.gz \
  -b ${basedir}/analysis/groups/NoQuestions/task/noquestions_task_smoother.mema/easythresh/thresh_zstat_bio_gt_phys.nii.gz \
  -expr '2*step(a)+4*step(b)' \
  -prefix "${outdir}/overlap_all_bio_gt_phys.nii.gz"
3dcalc \
  -overwrite \
  -a ${basedir}/analysis/groups/Questions/task/questions_task_smoother.mema/easythresh/thresh_zstat_bio_gt_phys.nii.gz \
  -b ${basedir}/analysis/groups/NoQuestions/task/noquestions_task_smoother.mema/easythresh/thresh_zstat_bio_gt_phys.nii.gz \
  -expr 'step(a)*step(b)' \
  -prefix "${outdir}/overlap_conjunction_bio_gt_phys.nii.gz"
# Calculate overlap (phys>bio)
## overlap_all => 2=questions, 4=noquestions, 6=conjunction
3dcalc \
  -overwrite \
  -a ${basedir}/analysis/groups/Questions/task/questions_task_smoother.mema/easythresh/thresh_zstat_phys_gt_bio.nii.gz \
  -b ${basedir}/analysis/groups/NoQuestions/task/noquestions_task_smoother.mema/easythresh/thresh_zstat_phys_gt_bio.nii.gz \
  -expr '2*step(a)+4*step(b)' \
  -prefix "${outdir}/overlap_all_phys_gt_bio.nii.gz"
3dcalc \
  -overwrite \
  -a ${basedir}/analysis/groups/Questions/task/questions_task_smoother.mema/easythresh/thresh_zstat_phys_gt_bio.nii.gz \
  -b ${basedir}/analysis/groups/NoQuestions/task/noquestions_task_smoother.mema/easythresh/thresh_zstat_phys_gt_bio.nii.gz \
  -expr 'step(a)*step(b)' \
  -prefix "${outdir}/overlap_conjunction_phys_gt_bio.nii.gz"
# Combine overlaps
3dcalc \
  -overwrite \
  -a "${outdir}/overlap_all_bio_gt_phys.nii.gz" -b "${outdir}/overlap_all_phys_gt_bio.nii.gz" \
  -expr 'a-b' -prefix "${outdir}/overlap_all.nii.gz"
3dcalc \
  -overwrite \
  -a "${outdir}/overlap_conjunction_bio_gt_phys.nii.gz" -b "${outdir}/overlap_conjunction_phys_gt_bio.nii.gz" \
  -expr 'a-b' -prefix "${outdir}/overlap_conjunction.nii.gz"

echo
echo "move one"
curdir=$(pwd)
cd ../../lib

echo
echo "plot"
#suffixes="_bio_gt_phys.nii.gz _phys_gt_bio.nii.gz .nii.gz"
suffixes=".nii.gz"
for suffix in ${suffixes}; do
  echo
  echo "${suffix}"
  
  infile="${outdir}/overlap_conjunction${suffix}"
  
  echo
  echo "...afni"
  ./plot_afni_slices.bash ${infile} ${thr} ${outdir}/overlap_conjunction_volume
  
  #echo
  #echo "...pysurfer"
  #./plot_pysurfer.py -i ${infile} -t ${thr} -o ${outdir}/overlap_conjunction_surface
  
  echo
done
