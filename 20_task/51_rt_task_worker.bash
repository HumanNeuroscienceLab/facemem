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

model1="SPMG1(4)"
model2="dmUBLOCK"

base=/mnt/nfs/psych/faceMemoryMRI/analysis/subjects
sdir=${base}/${subject}/${runtype}
tdir="/mnt/nfs/psych/faceMemoryMRI/scripts/timing"


#--- RUN ---#

mkdir ${sdir}/task 2> /dev/null
rm -rf ${sdir}/task/rt_spmg1.reml

task_analysis.rb -i ${sdir}/preproc/filtered_func_run*.nii.gz \
  -m ${sdir}/mask.nii.gz \
  -b ${sdir}/mean_func.nii.gz \
  --output ${sdir}/task/rt_spmg1.reml \
  --tr 1 \
  --polort 0 \
  --motion ${sdir}/motion.1D \
  --covars compcor ${sdir}/compcor.1D \
  --stim bio ${tdir}/allruns_faceMemory01_${subject}_${runtype}_bio "${model1}" \
  --stim phys ${tdir}/allruns_faceMemory01_${subject}_${runtype}_phys "${model1}" \
  --stim-am2 biort ${tdir}/connpaper/rt_${subject}_${runtype}_bio.1D "${model2}" \
  --stim-am2 physrt ${tdir}/connpaper/rt_${subject}_${runtype}_phys.1D "${model2}" \
  --glt bio_gt_phys 'SYM: +bio -phys' \
  --glt phys_gt_bio 'SYM: -bio +phys' \
  --glt biort_gt_physrt 'SYM: +biort -physrt' \
  --glt physrt_gt_biort 'SYM: -biort +physrt' \
  --regdir ${sdir}/reg \
  --threads ${nthreads} #--overwrite

# TODO:
# - add vthr and cthr options
