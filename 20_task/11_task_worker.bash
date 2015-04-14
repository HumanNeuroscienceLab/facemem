#!/usr/bin/env bash

[[ `which afni` != "/mnt/nfs/share/afni/current/afni" ]] && export PATH="/mnt/nfs/share/afni/current/afni":${PATH}


#--- USER ARGS ---#

if [ $# != 3 ]; then
  echo "usage: $0 subject runtype nthreads"
  exit 1
fi

subject="$1"
runtype="$2"
nthreads="$3"


#--- MY ARGS ---#

model="SPMG1(4)"

base=/mnt/nfs/psych/faceMemoryMRI/analysis/subjects
sdir=${base}/${subject}/${runtype}
tdir="/mnt/nfs/psych/faceMemoryMRI/scripts/timing"


#--- RUN ---#

mkdir ${sdir}/task 2> /dev/null
rm -rf ${sdir}/task/smoother_preproc_spmg1.reml

task_analysis.rb -i ${sdir}/preproc/filtered_func_run*.nii.gz \
  -m ${sdir}/mask.nii.gz \
  -b ${sdir}/mean_func.nii.gz \
  --output ${sdir}/task/smoother_preproc_spmg1.reml \
  --tr 1 \
  --polort 0 \
  --motion ${sdir}/motion.1D \
  --covars compcor ${sdir}/compcor.1D \
  --stim bio ${tdir}/allruns_faceMemory01_${subject}_${runtype}_bio "${model}" \
  --stim phys ${tdir}/allruns_faceMemory01_${subject}_${runtype}_phys "${model}" \
  --glt bio_gt_phys 'SYM: +bio -phys' \
  --glt phys_gt_bio 'SYM: -bio +phys' \
  --regdir ${sdir}/reg \
  --threads ${nthreads} #--overwrite

# TODO:
# - add vthr and cthr options
