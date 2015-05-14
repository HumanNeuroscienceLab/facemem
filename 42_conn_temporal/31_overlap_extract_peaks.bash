#!/usr/bin/env bash

###
# PATHS
###

subjects=$(cat ../sublist_all.txt)
runtypes="Questions NoQuestions"

basedir="/mnt/nfs/psych/faceMemoryMRI"
std_roifile2="${basedir}/scripts/connpaper/rois/overlap_peaks.nii.gz"
roiname="overlap_peaks_n41"


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


# ASSUME THAT ROIs ARE ALREADY IN SUBJECT SPACE


###
# Extract TS
###
echo "Extract the TS"

conds="bio phys"

function extract_peaks_ts() {
  run "cd $1"
  for cond in ${conds}; do
    run "3dROIstats -mask rois/${roiname}.nii.gz -quiet connectivity/task_residuals.reml/residuals_${cond}.nii.gz > connectivity/task_residuals.reml/ts_${roiname}_${cond}.1D"
  done
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
