#!/usr/bin/env bash

subjs=( $( cat ../sublist_all.txt ) )
nthreads=3
njobs=13

parallel --no-notice -j $njobs --eta \
  ./13_localizer_task_worker.bash {} ${nthreads} ::: ${subjs[@]}
