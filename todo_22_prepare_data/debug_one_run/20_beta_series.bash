#!/usr/bin/env bash

# Here I want to compute the beta-series for both
# With the computation being done here in functional space
# and then transforming the output to standard space as well
# And then I want to also have the input in standard space

function run() {
  echo "$@"
  eval "$@"
  return $?
}


#--- PATHS ---#

basedir="/mnt/nfs/psych/faceMemoryMRI"
workdir="${basedir}/analysis/scratch/debug_one_run/bs"
mkdir ${workdir} 2> /dev/null
debugdir="${basedir}/analysis/scratch/debug_one_run"

afnidir=${basedir}/analysis/subjects/tb9226/Questions
fsldir=${basedir}/analysis/fsl/Questions/tb9226/run01.feat

timeDir="${basedir}/scripts/timing"


#--- SETUP ---#

basis="spmg1"
model='SPMG1(4)'

run "cd ${workdir}"
run "export PATH=/mnt/nfs/share/afni/current:$PATH"
run "export OMP_NUM_THREADS=10"
run "which afni"


#--- XMAT ---#

echo
echo "timing"
run "awk '{print \$1}' ${timeDir}/faceMemory01_tb9226_Questions_run01_bio > timing_bio"
run "awk '{print \$1}' ${timeDir}/faceMemory01_tb9226_Questions_run01_phys > timing_phys"

# This should be the same for everything
echo
echo "deconvolve (xmat)"
3dDeconvolve \
    -input ${debugdir}/fsl_preproc.nii.gz \
    -force_TR 1 \
    -polort 2 \
    -num_stimts 2 \
    -stim_times_IM 1 timing_bio ${model} \
    -stim_times_IM 2 timing_phys ${model} \
    -stim_label 1 bio \
    -stim_label 2 phys \
    -noFDR \
    -nobucket \
    -x1D xmat.1D \
    -xjpeg xmat.jpg \
    -x1D_stop


#--- FUNCTIONAL REMLFIT ---#

echo
echo "fsl - remlfit"
3dREMLfit -matrix xmat.1D \
    -input ${debugdir}/fsl_preproc.nii.gz \
    -mask ${debugdir}/afni_mask.nii.gz \
    -noFDR \
    -Rbeta fsl_beta_series_in_func.nii.gz \
    -Rerrts fsl_residuals_in_func.nii.gz \
    -verb

echo
echo "afni - remlfit"
3dREMLfit -matrix xmat.1D \
    -input ${debugdir}/afni_preproc.nii.gz \
    -mask ${debugdir}/afni_mask.nii.gz \
    -noFDR \
    -Rbeta afni_beta_series_in_func.nii.gz \
    -Rerrts afni_residuals_in_func.nii.gz \
    -verb


#--- SUB-BRICKS ---#

pipelines="fsl afni"
spaces="in_func"

for pipeline in ${pipelines}; do
  echo
  echo "pipeline: ${pipeline}"
  for space in ${spaces}; do
    echo "space: ${space}"
    run "afni_buc2time.R -i ${pipeline}_beta_series_${space}.nii.gz -s 'bio|phys' -o ${pipeline}_beta_series_${space}_all.nii.gz"
    run "afni_buc2time.R -i ${pipeline}_beta_series_${space}.nii.gz -s 'bio' -o ${pipeline}_beta_series_${space}_bio.nii.gz"
    run "afni_buc2time.R -i ${pipeline}_beta_series_${space}.nii.gz -s 'phys' -o ${pipeline}_beta_series_${space}_phys.nii.gz"
  done
done


#--- FUNCTIONAL TO STANDARD ---#

echo
echo "fsl - func to std"
run "applywarp -i ${debugdir}/fsl_preproc.nii.gz -r ${fsldir}/reg/standard.nii.gz -o ${debugdir}/fsl_preproc_in_std.nii.gz -w ${fsldir}/reg/example_func2standard_warp.nii.gz --interp=trilinear"
run "applywarp -i fsl_beta_series_in_func_all.nii.gz -r ${fsldir}/reg/standard.nii.gz -o fsl_beta_series_in_func_in_std_all.nii.gz -w ${fsldir}/reg/example_func2standard_warp.nii.gz --interp=trilinear"
run "applywarp -i fsl_beta_series_in_func_bio.nii.gz -r ${fsldir}/reg/standard.nii.gz -o fsl_beta_series_in_func_in_std_bio.nii.gz -w ${fsldir}/reg/example_func2standard_warp.nii.gz --interp=trilinear"
run "applywarp -i fsl_beta_series_in_func_phys.nii.gz -r ${fsldir}/reg/standard.nii.gz -o fsl_beta_series_in_func_in_std_phys.nii.gz -w ${fsldir}/reg/example_func2standard_warp.nii.gz --interp=trilinear"

echo
echo "afni - func to std"
run "gen_applywarp.rb -i ${debugdir}/afni_preproc.nii.gz -r ${afnidir}/reg -w 'exfunc-to-standard' -o ${debugdir}/afni_preproc_in_std.nii.gz --dxyz 2"
run "gen_applywarp.rb -i afni_beta_series_in_func_all.nii.gz -r ${afnidir}/reg -w 'exfunc-to-standard' -o afni_beta_series_in_func_in_std_all.nii.gz --dxyz 2"
run "gen_applywarp.rb -i afni_beta_series_in_func_bio.nii.gz -r ${afnidir}/reg -w 'exfunc-to-standard' -o afni_beta_series_in_func_in_std_bio.nii.gz --dxyz 2"
run "gen_applywarp.rb -i afni_beta_series_in_func_phys.nii.gz -r ${afnidir}/reg -w 'exfunc-to-standard' -o afni_beta_series_in_func_in_std_phys.nii.gz --dxyz 2"

echo "mask"
run "gen_applywarp.rb -i ${debugdir}/afni_mask.nii.gz -r ${afnidir}/reg -w 'exfunc-to-standard' -o ${debugdir}/afni_mask_in_std.nii.gz --interp NN --dxyz 2"


#--- STANDARD REMLFIT ---#

echo
echo "fsl - remlfit"
run "3dREMLfit -matrix xmat.1D \
    -input ${debugdir}/fsl_preproc_in_std.nii.gz \
    -mask ${debugdir}/afni_mask_in_std.nii.gz \
    -noFDR \
    -Rbeta fsl_beta_series_in_std.nii.gz \
    -Rerrts fsl_residuals_in_std.nii.gz \
    -verb"

echo
echo "afni - remlfit"
run "3dREMLfit -matrix xmat.1D \
    -input ${debugdir}/afni_preproc_in_std.nii.gz \
    -mask ${debugdir}/afni_mask_in_std.nii.gz \
    -noFDR \
    -Rbeta afni_beta_series_in_std.nii.gz \
    -Rerrts afni_residuals_in_std.nii.gz \
    -verb"


#--- SUB-BRICKS ---#

pipelines="fsl afni"
spaces="in_std"

for pipeline in ${pipelines}; do
  echo
  echo "pipeline: ${pipeline}"
  for space in ${spaces}; do
    echo "space: ${space}"
    run "afni_buc2time.R -i ${pipeline}_beta_series_${space}.nii.gz -s 'bio|phys' -o ${pipeline}_beta_series_${space}_all.nii.gz"
    run "afni_buc2time.R -i ${pipeline}_beta_series_${space}.nii.gz -s 'bio' -o ${pipeline}_beta_series_${space}_bio.nii.gz"
    run "afni_buc2time.R -i ${pipeline}_beta_series_${space}.nii.gz -s 'phys' -o ${pipeline}_beta_series_${space}_phys.nii.gz"
  done
done