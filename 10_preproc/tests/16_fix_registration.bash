#!/usr/bin/env bash

# This switches to using the FSL registration

subjects=$( cat ../sublist_all.txt )
runtypes="Questions"

function run() {
  echo "$@"
  eval "$@"
  return $?
}


###
# ANAT
###

# Move old folders
#for subj in ${subjects}; do
#  run "mv /mnt/nfs/psych/faceMemoryMRI/analysis/subjects/${subj}/anat/reg /mnt/nfs/psych/faceMemoryMRI/analysis/subjects/${subj}/anat/reg_afni"
#done

## Run new registration
#base=/mnt/nfs/psych/faceMemoryMRI/analysis/subjects
#njobs=8
#parallel --no-notice -j $njobs --eta \
#  anat_register_to_standard.rb -i ${base}/{}/anat/brain.nii.gz -o ${base}/{}/anat/reg fsl --input-head ${base}/{}/anat/head.nii.gz ::: ${subjects}


###
# FUNC
###

## Move old folders
#for subj in ${subjects}; do
#  for runtype in ${runtypes}; do
#    run "mv /mnt/nfs/psych/faceMemoryMRI/analysis/subjects/${subj}/${runtype}/reg /mnt/nfs/psych/faceMemoryMRI/analysis/subjects/${subj}/${runtype}/reg_afni"
#  done
#done

# Threshold wmseg
#for subj in ${subjects}; do
#  for runtype in ${runtypes}; do
#    echo
#    run "cd /mnt/nfs/psych/faceMemoryMRI/analysis/subjects/${subj}/anat/segment"
#    run "fslmaths highres_pve_2.nii.gz -thr 0.5 -bin wmseg.nii.gz"
#    run "cd -"
#  done
#done

# Run new registration
base=/mnt/nfs/psych/faceMemoryMRI/analysis/subjects
njobs=8
#parallel --no-notice -j $njobs --eta \
#  func_register_to_highres.rb -e ${base}/{1}/{2}/preproc/mean_func.nii.gz -a ${base}/{1}/anat/brain.nii.gz -o ${base}/{1}/{2}/reg fsl --anat-head ${base}/{1}/anat/head.nii.gz --wmseg ${base}/{1}/anat/segment/wmseg.nii.gz ::: ${subjects} ::: ${runtypes}

parallel --no-notice -j $njobs --eta \
  func_register_to_standard.rb -e ${base}/{1}/{2}/reg -a ${base}/{1}/anat/reg fsl ::: ${subjects} ::: ${runtypes}
