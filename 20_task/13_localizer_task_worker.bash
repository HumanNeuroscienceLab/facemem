#!/usr/bin/env bash

[[ `which afni` != "/mnt/nfs/share/afni/current/afni" ]] && export PATH="/mnt/nfs/share/afni/current/afni":${PATH}


#--- USER ARGS ---#

if [ $# != 2 ]; then
  echo "usage: $0 subject nthreads"
  exit 1
fi

subject="$1"
nthreads="$2"


#--- MY ARGS ---#

model="SPMG1(11.5)"
runtype="Localizer"

base=/mnt/nfs/psych/faceMemoryMRI/analysis/subjects
sdir=${base}/${subject}/${runtype}
tdir="/mnt/nfs/psych/faceMemoryMRI/scripts/timing"


#--- RUN ---#

mkdir ${sdir}/task 2> /dev/null
rm -rf ${sdir}/task/smoother_preproc_spmg1.reml

task_analysis.rb -i ${sdir}/preproc/filtered_func_run01.nii.gz ${sdir}/preproc/filtered_func_run02.nii.gz \
  -m ${sdir}/mask.nii.gz \
  -b ${sdir}/mean_func.nii.gz \
  --output ${sdir}/task/smoother_preproc_spmg1.reml \
  --tr 1 \
  --polort 0 \
  --oresiduals \
  --motion ${sdir}/motion.1D \
  --stim face ${tdir}/allruns_FaceBody01_Face.txt "${model}" \
  --stim house ${tdir}/allruns_FaceBody01_House.txt "${model}" \
  --stim body ${tdir}/allruns_FaceBody01_Body.txt "${model}" \
  --glt face_gt_house 'SYM: +face -house' \
  --glt house_gt_face 'SYM: -face +house' \
  --glt face_n_body_gt_house 'SYM: +face +body -2*house' \
  --glt house_gt_face_n_body 'SYM: -face -body +2*house' \
  --regdir ${sdir}/reg \
  --threads ${nthreads} #--overwrite

#  --covars compcor ${sdir}/compcor.1D \