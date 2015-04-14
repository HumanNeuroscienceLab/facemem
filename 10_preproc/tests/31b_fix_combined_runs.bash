#!/usr/bin/env bash

# There are NaNs saved in the combined and split runs.
# Here we fix those errors by resaving it

function run() {
  echo "$@"
  eval "$@"
  return $?
}

subject="$1"


#--- SETUP ---#

export PATH=/mnt/nfs/share/afni/current:${PATH}

basedir="/mnt/nfs/psych/faceMemoryMRI/analysis"

runtype="Questions"
#fnames="func_concat func_concat_mc func_concat_mc_compcor_top5 func_concat_mc_compcor_sim"
fnames="func_concat_fsl"
conditions="bio phys"

splitdir="${basedir}/subjects/${subject}/${runtype}/preproc/split_ts"


#--- RUN ---#

run "cd ${splitdir}"
run "mkdir tests"

for fname in $fnames; do
  echo
  echo "covars: ${fname}"
  for condition in ${conditions}; do
    echo "-- condition: ${condition}"
    run "3dcalc -overwrite -a ${fname}_${condition}.nii.gz -expr 'a' -prefix ${fname}_${condition}.nii.gz"
  done
done
