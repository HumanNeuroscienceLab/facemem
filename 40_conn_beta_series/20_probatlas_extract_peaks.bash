#!/usr/bin/env bash

###
# PATHS
###

subjects=$(cat ../sublist_all.txt)
runtypes="Questions NoQuestions"

basedir="/mnt/nfs/psych/faceMemoryMRI"
std_roifile2="${basedir}/scripts/connpaper/rois/face_gt_house+scene.nii.gz"
std_roifile3="${basedir}/scripts/connpaper/rois/face_gt_house+scene_3mm.nii.gz"
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


####
## Transform ROIs to 3mm space
####

run "3dresample -inset ${std_roifile2} -master ${FSLDIR}/data/standard/MNI152_T1_3mm_brain.nii.gz -prefix ${std_roifile3}"


###
# Extract TS
###
echo "Extract the TS"

conds="bio phys"

function extract_peaks_ts() {
  run "cd $1"
  indir="task/beta_series_spmg1_nocompcor.reml/reg_standard"
  for cond in ${conds}; do
    run "3dROIstats -mask ${std_roifile3} -quiet ${indir}/beta_series_${cond}.nii.gz > ts/beta_series_${roiname}_${cond}.1D"
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
