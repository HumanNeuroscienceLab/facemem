#!/usr/bin/env bash

subjs=( $( cat ../sublist_all.txt ) )
nthreads=1
njobs=13

parallel --no-notice -j $njobs --eta \
  ./60_dr_worker.bash {}  ::: ${subjs[@]}
