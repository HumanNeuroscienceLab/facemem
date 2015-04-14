#!/usr/bin/env bash

basedir="/mnt/nfs/psych/faceMemoryMRI/analysis/subjects"

if [[ $# -ne 3 ]]; then
  echo "usage: $0 subject runtype nthreads"
  exit 1
fi

subject="$1"
runtype="$2"
nthreads="$3"
  
rundir="${basedir}/${subject}/${runtype}"
anatdir="${basedir}/${subject}/anat"
nruns=$( ls -l ${rundir}/preproc/filtered_func_run*.nii.gz | wc -l )

echo
echo "${subject} - ${runtype} - #${nruns} runs"

for (( ri = 1; ri <= ${nruns}; ri++ )); do
  func_compcor.R \
    -i ${rundir}/preproc/filtered_func_run0${ri}.nii.gz \
    -m ${rundir}/preproc/mask.nii.gz \
    -w "${anatdir}/freesurfer/volume/left_cerebral_white_matter.nii.gz ${anatdir}/freesurfer/volume/right_cerebral_white_matter.nii.gz" \
    -c "${anatdir}/freesurfer/volume/left_lateral_ventricle.nii.gz ${anatdir}/freesurfer/volume/right_lateral_ventricle.nii.gz ${anatdir}/freesurfer/volume/csf.nii.gz" \
    -r ${rundir}/reg \
    --hp 200 \
    -o ${rundir}/preproc/compcor_run0${ri} \
    --threads ${nthreads} \
    --ncomp 5 \
    --nsim 100 \
    -v
done
  
# TODO: allow output for compcor to be output prefix!
