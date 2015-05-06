#!/usr/bin/env bash

# This script will run global connectivity for a single subject


function run() {
  echo "$@"
  eval "$@"
  return $?
}


###
# USER ARGS

if [ $# != 3 ]; then
  echo "usage: $0 subject runtype nthreads"
  exit 1
fi

subject="$1"
runtype="$2"
nthreads="$3"


###
# SETTINGS

export OMP_NUM_THREADS=${nthreads}
#res=4
res=3
conds="bio phys"


###
# PATHS

base="/mnt/nfs/psych/faceMemoryMRI"
sdir=${base}/analysis/subjects
resdir=${sdir}/${subject}/${runtype}/connectivity/task_residuals.reml
mask=${base}/analysis/groups/${runtype}/global/mask.nii.gz


###
# RUN

for cond in ${conds}; do
  echo "3dTcorrMap for ${cond}"
  3dTcorrMap \
    -overwrite \
    -input ${resdir}/residuals_${cond}_to_std_${res}mm.nii.gz \
    -mask ${mask} \
    -polort 0 \
    -Zmean ${resdir}/gcor_zmean_${cond}_${res}mm.nii.gz \
    -VarThreshN 0.1 0.3 0.1 ${resdir}/gcor_thresh_${cond}_${res}mm.nii.gz
done

