#!/usr/bin/env bash

[[ `which afni` != "/mnt/nfs/share/afni/current/afni" ]] && export PATH="/mnt/nfs/share/afni/current/afni":${PATH}

###
# USER ARGS

if [[ $# -ne 3 ]]; then
  echo "usage: $0 subject runtype nthreads"
  exit 2
fi

subject="$1"
runtype="$2"
nthreads="$3"

#subject="tb9226"
#runtype="Questions"
#nthreads=2

export OMP_NUM_THREADS=${nthreads}


###
# PATHS

sdir="/mnt/nfs/psych/faceMemoryMRI/analysis/subjects/${subject}/${runtype}"
mkdir ${sdir}/connectivity/task_residuals.reml 2> /dev/null


###
# RUN

echo
echo "deconvolve"
3dDeconvolve \
  -overwrite \
  -jobs 4 \
  -force_TR 1 -polort 0 \
  -input ${sdir}/preproc/filtered_func_run0?.nii.gz \
  -mask ${sdir}/mask.nii.gz \
  -num_stimts 13 \
  -stim_times 1 /mnt/nfs/psych/faceMemoryMRI/scripts/timing/allruns_faceMemory01_tb9226_Questions_bio 'SPMG1(4)' -stim_label 1 bio \
  -stim_times 2 /mnt/nfs/psych/faceMemoryMRI/scripts/timing/allruns_faceMemory01_tb9226_Questions_phys 'SPMG1(4)' -stim_label 2 phys \
  -stim_file 3 "${sdir}/motion.1D[0]" -stim_base 3 -stim_label 3 roll \
  -stim_file 4 "${sdir}/motion.1D[1]" -stim_base 4 -stim_label 4 pitch \
  -stim_file 5 "${sdir}/motion.1D[2]" -stim_base 5 -stim_label 5 yaw \
  -stim_file 6 "${sdir}/motion.1D[3]" -stim_base 6 -stim_label 6 dS \
  -stim_file 7 "${sdir}/motion.1D[4]" -stim_base 7 -stim_label 7 dL \
  -stim_file 8 "${sdir}/motion.1D[5]" -stim_base 8 -stim_label 8 dP \
  -stim_file 9 "${sdir}/compcor5.1D[0]" -stim_base 9 -stim_label 9 comp1 \
  -stim_file 10 "${sdir}/compcor5.1D[1]" -stim_base 10 -stim_label 10 comp2 \
  -stim_file 11 "${sdir}/compcor5.1D[2]" -stim_base 11 -stim_label 11 comp3 \
  -stim_file 12 "${sdir}/compcor5.1D[3]" -stim_base 12 -stim_label 12 comp4 \
  -stim_file 13 "${sdir}/compcor5.1D[4]" -stim_base 13 -stim_label 13 comp5 \
  -noFDR -nobucket \
  -x1D ${sdir}/connectivity/task_residuals.reml/xmat.1D \
  -xjpeg ${sdir}/connectivity/task_residuals.reml/xmat.jpg \
  -x1D_stop

echo
echo "remlfit"
infiles="$(ls -d ${sdir}/preproc/filtered_func_run0?.nii.gz | tr '\n' ' ')"
3dREMLfit \
  -overwrite \
  -matrix ${sdir}/connectivity/task_residuals.reml/xmat.1D \
  -input "${infiles}" \
  -mask ${sdir}/mask.nii.gz \
  -noFDR -verb \
  -Rerrts ${sdir}/connectivity/task_residuals.reml/residuals.nii.gz
