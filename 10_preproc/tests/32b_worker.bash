#!/usr/bin/env bash

# This transforms the time-series data into standard space
# It does this using the FSL and AFNI based registrations
# It only uses the rawest form of the concatenated data

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
nthreads=2

afni_regdir="${basedir}/subjects/${subject}/${runtype}/reg"
fsl_regdir="${basedir}/fsl/${runtype}/${subject}/run01.feat"
splitdir="${basedir}/subjects/${subject}/${runtype}/preproc/split_ts"


#--- RUN ---#

run "cd ${splitdir}"
run "mkdir tests"

for fname in $fnames; do
  echo
  echo "covars: ${fname}"
  for condition in ${conditions}; do
    echo "-- condition: ${condition}"
    #run "gen_applywarp.rb -i ${fname}_${condition}.nii.gz -r ${afni_regdir} -w 'exfunc-to-standard' -o tests/${fname}_${condition}_to_standard_afni.nii.gz --dxyz 2 --threads ${nthreads}"
    run "applywarp -i ${fname}_${condition}.nii.gz -r ${fsl_regdir}/reg/standard.nii.gz -o tests/${fname}_${condition}_to_standard_fsl.nii.gz -w ${fsl_regdir}/reg/example_func2standard_warp.nii.gz --interp=spline"
  done
done

#gen_applywarp.rb -i ${fname}_${condition}.nii.gz -r ${afni_regdir} -w 'exfunc-to-standard' -o tests/${fname}_${condition}_to_standard_afni_linear.nii.gz --dxyz 2 --threads ${nthreads}
# fnirt
# 4m 11s to do the trilinear
# 73m for sinc
# 7m for spline
#time applywarp -i ${fname}_${condition}.nii.gz -r ${fsl_regdir}/reg/standard.nii.gz -o tests/${fname}_${condition}_to_standard_fsl_linear.nii.gz -w ${fsl_regdir}/reg/example_func2standard_warp.nii.gz --interp=trilinear
#time applywarp -i ${fname}_${condition}.nii.gz -r ${fsl_regdir}/reg/standard.nii.gz -o tests/${fname}_${condition}_to_standard_fsl_sinc.nii.gz -w ${fsl_regdir}/reg/example_func2standard_warp.nii.gz --interp=sinc
#time applywarp -i ${fname}_${condition}.nii.gz -r ${fsl_regdir}/reg/standard.nii.gz -o tests/${fname}_${condition}_to_standard_fsl_spline.nii.gz -w ${fsl_regdir}/reg/example_func2standard_warp.nii.gz --interp=spline
