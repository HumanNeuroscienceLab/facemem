#!/usr/bin/env bash

# Gather one run for one subject with the AFNI and the FSL pipelines
# In the case of the AFNI, I try to get it to be at the same point
# as the FSL's.

function run() {
  echo "$@"
  eval "$@"
  return $?
}


#--- PATHS ---#

basedir="/data/psych/faceMemoryMRI"
workdir="${basedir}/analysis/scratch/debug_one_run"
mkdir ${workdir} 2> /dev/null

afnidir=${basedir}/analysis/subjects/tb9226/Questions/mc
fsldir=${basedir}/analysis/fsl/Questions/tb9226/run01.feat


#--- GATHER THE DATA ---#

run "cd ${workdir}"

# FSL
run "ln -s ${fsldir}/filtered_func_data.nii.gz fsl_preproc.nii.gz"

# AFNI (needs some processing)
run "ln -s ${afnidir}/func_run01_volreg.nii.gz afni_mc.nii.gz"
## mean
run "3dTstat -prefix afni_mean.nii.gz afni_mc.nii.gz"
## mask
run "3dAutomask -prefix afni_mask.nii.gz -dilate 1 afni_mc.nii.gz"
## smooth 
run "3dBlurInMask -input afni_mc.nii.gz -FWHM 4 -mask afni_mask.nii.gz -prefix afni_smooth.nii.gz"
## mean
run "3dTstat -prefix afni_smooth_mean.nii.gz afni_smooth.nii.gz"
## scale
run "3dcalc -a afni_smooth.nii.gz -b afni_smooth_mean.nii.gz -c afni_mask.nii.gz -expr 'c * min(200, a/b*100)*step(a)*step(b)' -prefix afni_preproc.nii.gz"
