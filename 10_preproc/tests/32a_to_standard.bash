#!/usr/bin/env bash

# This transforms the time-series data into standard space
# It does this using the FSL and AFNI based registrations
# It only uses the rawest form of the concatenated data

function run() {
  echo "$@"
  eval "$@"
  return $?
}


#--- SETUP ---#

export PATH=/mnt/nfs/share/afni/current:${PATH}
subjs=( $( cat sublist_14.txt ) )
njobs=8


#--- RUN ---#

parallel --no-notice -j $njobs --eta \
  bash 32b_worker.bash {} ::: ${subjs[@]}
