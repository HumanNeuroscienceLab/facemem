#!/usr/bin/env bash

# Temporal regression on functional data using the reverse inference maps

###
# Functions

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
# User Args

[[ $# -ne 3 ]] && die "usage: $0 subject runtype ri-name"
subject="$1"
runtype="$2"
name="$3" # ri_maps_01


###
# Setup

base="/mnt/nfs/psych/faceMemoryMRI"

# Subject Variables
subdir="${base}/analysis/subjects/${subject}/${runtype}"
subdr="${subdir}/dr"
subdat="${subdir}/filtered_func_data.nii.gz"
subroi="${subdr}/${name}_roi.nii.gz"
subts="${subdr}/${name}_stage1.1D"
mask="${subdir}/mask.nii.gz"


###
# Commands

run "fsl_glm -i $subdat -d $subroi -o $subts --demean -m $mask"
