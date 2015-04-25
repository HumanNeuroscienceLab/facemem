#!/usr/bin/env bash

# Only relevant for Questions run
runtypes=( "Questions" )
subjs=( $( cat ../sublist_all.txt ) )
nthreads=4
njobs=8

parallel --no-notice -j $njobs --eta \
  ./51_rt_task_worker.bash {1} {2} ${nthreads} ::: ${subjs[@]} ::: ${runtypes[@]}
