#!/usr/bin/env bash

function run() {
  echo "$@"
  eval "$@"
  return $?
}


#--- PATHS ---#

basedir="/mnt/nfs/psych/faceMemoryMRI"
workdir="${basedir}/analysis/scratch/debug_one_run/bs"

afnidir=${basedir}/analysis/subjects/tb9226/Questions
fsldir=${basedir}/analysis/fsl/Questions/tb9226/run01.feat

timeDir="${basedir}/scripts/timing"


#--- SETUP ---#

run "cd ${workdir}"
run "export OMP_NUM_THREADS=8"


#--- FUNCTIONAL REMLFIT ---#

echo
echo
echo "=== FUNC ==="

echo
echo "bs - func"
run "3dTcorrelate -autoclip -prefix cor_beta_series_in_func_all.nii.gz fsl_beta_series_in_func_all.nii.gz afni_beta_series_in_func_all.nii.gz"
num=$(3dBrickStat -mean -non-zero cor_beta_series_in_func_all.nii.gz)
echo "... ${num} mean correlation"

echo
echo "residuals - func"
run "3dTcorrelate -autoclip -prefix cor_residuals_in_func.nii.gz fsl_residuals_in_func.nii.gz afni_residuals_in_func.nii.gz"
num=$(3dBrickStat -mean -non-zero cor_residuals_in_func.nii.gz)
echo "... ${num} mean correlation"


#--- FUNC -> STANDARD ---#

echo
echo
echo "=== FUNC TO STANDARD ==="

echo
echo "bs - func to standard"
run "3dTcorrelate -autoclip -prefix cor_beta_series_in_func_in_std_all.nii.gz fsl_beta_series_in_func_in_std_all.nii.gz afni_beta_series_in_func_in_std_all.nii.gz"
num=$(3dBrickStat -mean -non-zero cor_beta_series_in_func_in_std_all.nii.gz)
echo "... ${num} mean correlation"

echo
echo "residuals - func to standard"
run "3dTcorrelate -autoclip -prefix cor_residuals_in_func_in_std.nii.gz fsl_residuals_in_func_in_std.nii.gz afni_residuals_in_func_in_std.nii.gz"
num=$(3dBrickStat -mean -non-zero cor_residuals_in_func_in_std.nii.gz)
echo "... ${num} mean correlation"


#--- STANDARD ---#

echo
echo
echo "=== STANDARD ==="

echo
echo "bs - standard"
run "3dTcorrelate -autoclip -prefix cor_beta_series_in_std_all.nii.gz fsl_beta_series_in_std_all.nii.gz afni_beta_series_in_std_all.nii.gz"
num=$(3dBrickStat -mean -non-zero cor_beta_series_in_std_all.nii.gz)
echo "... ${num} mean correlation"

echo
echo "residuals - standard"
run "3dTcorrelate -autoclip -prefix cor_residuals_in_std.nii.gz fsl_residuals_in_std.nii.gz afni_residuals_in_std.nii.gz"
num=$(3dBrickStat -mean -non-zero cor_residuals_in_std.nii.gz)
echo "... ${num} mean correlation"


#--- REG COMPARISON ---#

echo
echo
echo "=== FUNC TO STANDARD VS STANDARD ==="

echo
echo "bs - fsl"
run "3dTcorrelate -autoclip -prefix cor_beta_series_compare_reg_fsl_all.nii.gz fsl_beta_series_in_func_in_std_all.nii.gz fsl_beta_series_in_std_all.nii.gz"
num=$(3dBrickStat -mean -non-zero cor_beta_series_compare_reg_fsl_all.nii.gz)
echo "... ${num} mean correlation"

echo
echo "bs - afni"
run "3dTcorrelate -autoclip -prefix cor_beta_series_compare_reg_afni_all.nii.gz afni_beta_series_in_func_in_std_all.nii.gz afni_beta_series_in_std_all.nii.gz"
num=$(3dBrickStat -mean -non-zero cor_beta_series_compare_reg_afni_all.nii.gz)
echo "... ${num} mean correlation"
