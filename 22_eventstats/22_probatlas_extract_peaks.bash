#!/usr/bin/env bash

###
# PATHS
###

subjects=$(cat ../sublist_all.txt)
runtypes="Questions NoQuestions"

basedir="/mnt/nfs/psych/faceMemoryMRI"
std_roifile="${basedir}/scripts/connpaper/rois/face_gt_house+scene.nii.gz"
roiname="prob_atlas_peaks_n146"


###
# GENERAL FUNCTIONS
###

function run() {
  echo "$@"
  eval "$@"
  return $?
}

function die() {
  echo "$@"
  exit 2
}


###
# Transform ROIs to native space
###
echo "Transform ROIs to native space"

function transform_peaks_to_native() {
  run "cd $1"
  run "gen_applywarp.rb --overwrite -i ${std_roifile} -r reg -w 'standard-to-exfunc' -o rois/${roiname}.nii.gz --interp nn"
  run "3dcalc -overwrite -a rois/${roiname}.nii.gz -b mask.nii.gz -expr 'a*step(b)' -prefix rois/${roiname}.nii.gz"
  run "cd -"
}

#subject=tb9226
#runtype=Questions
for runtype in ${runtypes}; do
  echo
  echo "runtype: $runtype"
  for subject in ${subjects}; do
    echo "subject: ${subject}"
    transform_peaks_to_native "${basedir}/analysis/subjects/${subject}/${runtype}"
    echo
  done
done


###
# Extract TS
###
echo "Extract the TS"

function extract_peaks_ts() {
  run "cd $1"
  run "3dROIstats -mask rois/${roiname}.nii.gz -quiet filtered_func_data.nii.gz > ts/${roiname}.1D"
  run "cd -"
}

#subject=tb9226
#runtype=Questions
for runtype in ${runtypes}; do
  echo
  echo "runtype: $runtype"
  for subject in ${subjects}; do
    echo "subject: ${subject}"
    extract_peaks_ts "${basedir}/analysis/subjects/${subject}/${runtype}"
    echo
  done
done
