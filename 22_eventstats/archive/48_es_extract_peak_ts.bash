#!/usr/bin/env bash

# This script extracts the time-series from the peaks selected based on the main-effects of the task effect

subjects=$(cat ../sublist_all.txt)
runtypes="Questions NoQuestions"

basedir="/mnt/nfs/psych/faceMemoryMRI"
std_roifile="${basedir}/analysis/groups/Questions/task/questions_task_smoother.mema/conn_peaks/pos_peaks.nii.gz"
roiname="task_pos_peaks_n59"


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
# Extract TS
###
echo "Extract the TS"

function extract_peaks_ts() {
  run "cd $1"
  run "3dROIstats -mask rois/${roiname}.nii.gz -quiet task/smoother_eventstats_01/es_bio_avg_percent.nii.gz > ts/es_bio_${roiname}.1D"
  run "3dROIstats -mask rois/${roiname}.nii.gz -quiet task/smoother_eventstats_01/es_phys_avg_percent.nii.gz > ts/es_phys_${roiname}.1D"
  run "cd -"
}

for runtype in ${runtypes}; do
  echo
  echo "runtype: $runtype"
  for subject in ${subjects}; do
    echo "subject: ${subject}"
    extract_peaks_ts "${basedir}/analysis/subjects/${subject}/${runtype}"
    echo
  done
done

