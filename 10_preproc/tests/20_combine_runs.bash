#!/usr/bin/env bash


#--- SETTINGS ---#

njobs=6
nthreads=4

#subjs=( $( cat ../sublist_all.txt ) )
subjs=( $( cat sublist_14.txt ) )
runtype="Questions"

base0="/mnt/nfs/psych/faceMemoryMRI/analysis"
basedir="/mnt/nfs/psych/faceMemoryMRI/analysis/subjects"


#--- RUN ---#

## Make logs directory
#for subj in ${subjs[@]}; do
#  mkdir ${basedir}/${subj}/${runtype}/preproc/logs
#  mv ${basedir}/${subj}/${runtype}/preproc/log_* ${basedir}/${subj}/${runtype}/preproc/logs/
#done

## CONCAT COMPCOR TS
#parallel --no-notice -j $njobs --eta "cat ${basedir}/{}/${runtype}/preproc/compcor_run*/compcor_comps_ncomp.1D > ${basedir}/{}/${runtype}/preproc/compcor_concat_ncomp.1D" ::: ${subjs[@]}
#
#parallel --no-notice -j $njobs --eta "cat ${basedir}/{}/${runtype}/preproc/compcor_run*/compcor_comps_nsim.1D > ${basedir}/{}/${runtype}/preproc/compcor_concat_nsim.1D" ::: ${subjs[@]}

# TODO: add combining without removing anything

# TODO: try to keep the task effects (like by regressing out the task effects? or maybe )

## Original
#parallel --no-notice -j $njobs --eta \
#  func_combine_runs.rb \
#    -i ${basedir}/{}/${runtype}/preproc/filtered_func_run*.nii.gz \
#    -m ${basedir}/{}/${runtype}/preproc/mask.nii.gz \
#    -o ${basedir}/{}/${runtype}/preproc/func_concat \
#    --tr 1 \
#    --polort 0 \
#    --njobs ${nthreads} \
#    --log ${basedir}/{}/${runtype}/preproc/logs/func_concat ::: ${subjs[@]}

## MC
#parallel --no-notice -j $njobs --eta \
#  func_combine_runs.rb \
#    -i ${basedir}/{}/${runtype}/preproc/filtered_func_run*.nii.gz \
#    -m ${basedir}/{}/${runtype}/preproc/mask.nii.gz \
#    -o ${basedir}/{}/${runtype}/preproc/func_concat_mc \
#    --tr 1 \
#    --motion ${basedir}/{}/${runtype}/preproc/mc/func_motion_demean.1D \
#    --polort 0 \
#    --njobs ${nthreads} \
#    --log ${basedir}/{}/${runtype}/preproc/logs/func_concat_mc ::: ${subjs[@]}
#
## MC + COMCOR - TOP 5
#parallel --no-notice -j $njobs --eta \
#  func_combine_runs.rb \
#    -i ${basedir}/{}/${runtype}/preproc/filtered_func_run*.nii.gz \
#    -m ${basedir}/{}/${runtype}/preproc/mask.nii.gz \
#    -o ${basedir}/{}/${runtype}/preproc/func_concat_mc_compcor_top5 \
#    --tr 1 \
#    --motion ${basedir}/{}/${runtype}/preproc/mc/func_motion_demean.1D \
#    --covars compcor_top5 ${basedir}/{}/${runtype}/preproc/compcor_concat_ncomp.1D \
#    --polort 0 \
#    --njobs ${nthreads} \
#    --log ${basedir}/{}/${runtype}/preproc/logs/func_concat_mc_compcor_top5 ::: ${subjs[@]}
#    
## MC + COMCOR - TOP AUTO
#parallel --no-notice -j $njobs --eta \
#  func_combine_runs.rb \
#    -i ${basedir}/{}/${runtype}/preproc/filtered_func_run*.nii.gz \
#    -m ${basedir}/{}/${runtype}/preproc/mask.nii.gz \
#    -o ${basedir}/{}/${runtype}/preproc/func_concat_mc_compcor_sim \
#    --tr 1 \
#    --motion ${basedir}/{}/${runtype}/preproc/mc/func_motion_demean.1D \
#    --covars compcor_top5 ${basedir}/{}/${runtype}/preproc/compcor_concat_nsim.1D \
#    --polort 0 \
#    --njobs ${nthreads} \
#    --log ${basedir}/{}/${runtype}/preproc/logs/func_concat_mc_compcor_sim ::: ${subjs[@]}
#
#fsl_regdir="${basedir}/fsl/${runtype}/${subject}/run01.feat"

parallel --no-notice -j $njobs --eta \
  func_combine_runs.rb \
    -i ${base0}/fsl/${runtype}/{}/run*.feat/filtered_func_data.nii.gz \
    -m ${base0}/fsl/${runtype}/{}/run01.feat/mask.nii.gz \
    -o ${basedir}/{}/${runtype}/preproc/func_concat_fsl \
    --tr 1 \
    --polort 0 \
    --njobs ${nthreads} \
    --log ${basedir}/{}/${runtype}/preproc/logs/func_concat_fsl ::: ${subjs[@]}
