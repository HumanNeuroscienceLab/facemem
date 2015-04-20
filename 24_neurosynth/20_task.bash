#!/usr/bin/env bash

# This will run the task analysis (main effects) on the neurosynth temporal regression data
# It outputs everything as 1D files, which I can later convert back to voxelwise data

# Use older afni
export PATH=/mnt/nfs/share/afni/current:$PATH

if [[ $# -eq 0 ]]; then
  echo "usage: $0 roi-name (njobs [16])"
  exit 2
fi

name="$1"
njobs=${2:-16}

###
runtypes=( "Questions" "NoQuestions" )
subjs=( $( cat ../sublist_all.txt ) )
nthreads=1 # will be disabled bc too few voxels
parallel --no-notice -j $njobs --eta \
  ./20_task_worker.bash --subject={1} --runtype={2} --region=${name} --nthreads=${nthreads} ::: ${subjs[@]} ::: ${runtypes[@]}

#./20_task_worker.bash --subject=tb9226 --runtype=Questions --region=ri_maps_01 --nthreads=1