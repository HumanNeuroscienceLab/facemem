#!/usr/bin/env bash

# This transforms the time-series data into standard space

function run() {
  echo "$@"
  eval "$@"
  return $?
}


#--- SETUP ---#

export PATH=/mnt/nfs/share/afni/current:${PATH}

basedir="/mnt/nfs/psych/faceMemoryMRI/analysis"

subject="tb9645"
runtype="Questions"
fname="func_concat"
conditions="bio phys"
nthreads=2

afni_regdir="${basedir}/subjects/${subject}/${runtype}/reg"
fsl_regdir="${basedir}/fsl/${runtype}/${subject}/run01.feat"
splitdir="${basedir}/subjects/${subject}/${runtype}/preproc/split_ts"


#--- RUN ---#

run "cd ${splitdir}"

for condition in ${conditions}; do
  run "gen_applywarp.rb -i ${fname}_${condition}.nii.gz -r ${afni_regdir} -w 'exfunc-to-standard' -o ${fname}_${condition}_to_standard.nii.gz --dxyz 2 -threads ${nthreads}"
  run "applywarp -i ${debugdir}/fsl_preproc.nii.gz -r ${fsldir}/reg/standard.nii.gz -o ${debugdir}/fsl_preproc_in_std.nii.gz -w ${fsldir}/reg/example_func2standard_warp.nii.gz --interp=trilinear"
done

# The output will be saved into 2mm standard and 3mm standard
# Let's see which works better


# Also we will run the fnirt output as well




run "gen_applywarp.rb -i ${debugdir}/afni_preproc.nii.gz -r ${afnidir}/reg -w 'exfunc-to-standard' -o ${debugdir}/afni_preproc_in_std.nii.gz --dxyz 2"
