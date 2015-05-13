#!/usr/bin/env bash

# Extracts the beta-series from the probabilistic rois

# Use older afni
export PATH=/mnt/nfs/share/afni/current:$PATH

# Settings
runtypes=( "Questions" "NoQuestions" )
subjs=( $( cat ../sublist_all.txt ) )
nthreads=1 # will be disabled anyway bc too few voxels
njobs=16

parallel --no-notice -j $njobs --eta \
  ./10_beta_series_worker.bash --subject={1} --runtype={2} --region=prob_atlas_peaks_n146 --nthreads=${nthreads} ::: ${subjs[@]} ::: ${runtypes[@]}
