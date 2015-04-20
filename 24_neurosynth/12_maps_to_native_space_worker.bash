#!/usr/bin/env bash

# Transform the dual regression maps in standard space into each subject's
# own individual space


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

[[ $# -ne 3 ]] && die "usage: $0 subject runtype name"
subject="$1"
runtype="$2"
name="$3"


###
# Setup

base="/mnt/nfs/psych/faceMemoryMRI"

# Input standard reverse inference maps
stdmap="${base}/analysis/groups/mni152/dr/${name}.nii.gz"

# Subject Variables
subdir="${base}/analysis/subjects"
subdr="${subdir}/${subject}/${runtype}/dr"
subroi="${subdr}/${name}_roi.nii.gz"
mask="${subdir}/${subject}/${runtype}/mask.nii.gz"
regdir="${subdir}/${subject}/${runtype}/reg"


###
# Commands

run "mkdir ${subdr} 2> /dev/null"
run "gen_applywarp.rb --overwrite -i ${stdmap} -r ${regdir} -w 'standard-to-exfunc' -o ${subroi}"
run "3dcalc -overwrite -a ${subroi} -b ${mask} -expr 'a*step(b)' -prefix ${subroi}"
