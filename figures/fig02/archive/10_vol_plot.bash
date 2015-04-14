#!/usr/bin/env bash

# 1. Plot data on slices
# 2. Plot data on surface

basedir="/mnt/nfs/psych/faceMemoryMRI"
runtypes="Questions NoQuestions"
thr=1.96

outdir="${basedir}/figures/fig02_task_activity"
mkdir ${outdir} 2> /dev/null

curdir=$(pwd)
cd ../../lib
for runtype in ${runtypes}; do
  echo
  echo "${runtype}"
  
  lruntype=$( echo $runtype | tr '[:upper:]' '[:lower:]' )

  indir=${basedir}/analysis/groups/${runtype}/task/${lruntype}_task_smoother.mema/easythresh
  infile1=${indir}/thresh_zstat_bio_gt_phys.nii.gz
  infile2=${indir}/thresh_zstat_phys_gt_bio.nii.gz
  infile3=${indir}/thresh_zstat_bio_vs_phys.nii.gz
  
  echo "...combine inputs"
  3dcalc -overwrite -a ${infile1} -b ${infile2} -expr 'a-b' -prefix ${infile3}
  
  echo
  echo "...afni"
  ./plot_afni_slices.bash ${infile3} ${thr} ${outdir}/${lruntype}_volume
  
  #echo
  #echo "...pysurfer"
  #./plot_pysurfer.py -i ${infile3} -t ${thr} -o ${outdir}/${lruntype}_surface
  
  echo
done
