#!/usr/bin/env bash

# Here we will first calculate REHO and global connectivity on the beta-series
# in functional -> standard and standard space
# Then we will get the correlation in the maps between the stimuli

function run() {
  echo "$@"
  eval "$@"
  return $?
}


#--- PATHS ---#

basedir="/mnt/nfs/psych/faceMemoryMRI"
workdir="${basedir}/analysis/scratch/debug_one_run/bs"
debugdir="${basedir}/analysis/scratch/debug_one_run"

afnidir=${basedir}/analysis/subjects/tb9226/Questions
fsldir=${basedir}/analysis/fsl/Questions/tb9226/run01.feat

timeDir="${basedir}/scripts/timing"


#--- SETUP ---#

basis="spmg1"
model='SPMG1(4)'

run "cd ${workdir}"
run "export PATH=/mnt/nfs/share/afni/current:$PATH"
run "export OMP_NUM_THREADS=12"
run "which afni"


#--- APPLY MEASURES ---#

pipelines="fsl afni"
spaces="in_func in_func_in_std in_std"
subsets="all bio phys"

run "ln -sf ${debugdir}/afni_mask_in_std.nii.gz ${debugdir}/afni_mask_in_func_in_std.nii.gz"
run "ln -sf ${debugdir}/afni_mask.nii.gz ${debugdir}/afni_mask_in_func.nii.gz"

for pipeline in ${pipelines}; do
  echo
  echo "pipeline: ${pipeline}"
  for space in ${spaces}; do
    echo "- space: ${space}"
    for subset in ${subsets}; do
      echo "-- subset: ${subset}"
      run "3dReHo -inset ${pipeline}_beta_series_${space}_${subset}.nii.gz -mask ${debugdir}/afni_mask_${space}.nii.gz -prefix ${pipeline}_reho_${space}_${subset}.nii.gz"
      run "3dTcorrMap -input ${pipeline}_beta_series_${space}_${subset}.nii.gz -mask ${debugdir}/afni_mask_${space}.nii.gz -prefix ${pipeline}_gcor_${space}_${subset}.nii.gz"
    done
  done
done


#--- FUNC to STANDARD ---#

echo
echo "func to std"
space="in_func"
space2="in_func_in_std2"

for subset in ${subsets}; do
  echo "- subset: ${subset}"
  
  # fsl
  pipeline="fsl"
  run "applywarp -i ${pipeline}_reho_${space}_${subset}.nii.gz -r ${fsldir}/reg/standard.nii.gz -o ${pipeline}_reho_${space2}_${subset}.nii.gz -w ${fsldir}/reg/example_func2standard_warp.nii.gz --interp=trilinear"
  run "applywarp -i ${pipeline}_gcor_${space}_${subset}.nii.gz -r ${fsldir}/reg/standard.nii.gz -o ${pipeline}_gcor_${space2}_${subset}.nii.gz -w ${fsldir}/reg/example_func2standard_warp.nii.gz --interp=trilinear"
  
  # afni
  pipeline="afni"
  run "gen_applywarp.rb -i ${pipeline}_reho_${space}_${subset}.nii.gz -r ${afnidir}/reg -w 'exfunc-to-standard' -o ${pipeline}_reho_${space2}_${subset}.nii.gz --dxyz 2"  
  run "gen_applywarp.rb -i ${pipeline}_gcor_${space}_${subset}.nii.gz -r ${afnidir}/reg -w 'exfunc-to-standard' -o ${pipeline}_gcor_${space2}_${subset}.nii.gz --dxyz 2"  
done
