#!/usr/bin/env bash

[[ `which afni` != "/mnt/nfs/share/afni/current/afni" ]] && export PATH="/mnt/nfs/share/afni/current/afni":${PATH}

# This script will run a beta-series with the aim of getting the fitted model and using that for latency stuff
# The actual beta-series output will be deleted here

#--- USER ARGS ---#

if [ $# != 3 ]; then
  echo "usage: $0 subject runtype nthreads"
  exit 1
fi

subject="$1"
runtype="$2"
nthreads="$3"


#--- MY ARGS ---#

model="SPMG3(4)"

base=/mnt/nfs/psych/faceMemoryMRI/analysis/subjects
sdir=${base}/${subject}/${runtype}
tdir="/mnt/nfs/psych/faceMemoryMRI/scripts/timing"
stddir="/mnt/nfs/share/fsl/current/data/standard"

#--- RUN ---#

mkdir ${sdir}/task 2> /dev/null
rm -rf ${sdir}/task/latency_analysis_p2.reml

# NOTE: COMPCOR ISN'T WORKING RIGHT NOW
beta_series.rb -i ${sdir}/preproc/filtered_func_run*.nii.gz \
  -m ${sdir}/mask.nii.gz \
  -b ${sdir}/mean_func.nii.gz \
  --output ${sdir}/task/latency_analysis_p2.reml \
  --tr 1 \
  --polort 0 \
  --motion ${sdir}/motion.1D \
  --covars compcor ${sdir}/compcor.1D \
  --stim bio ${tdir}/allruns_faceMemory01_${subject}_${runtype}_bio "${model}" \
  --stim phys ${tdir}/allruns_faceMemory01_${subject}_${runtype}_phys "${model}" \
  --threads ${nthreads} #--overwrite
