#!/usr/bin/env bash

runtypes=( "Questions" "NoQuestions" )
subjs=( $( cat ../sublist_all.txt ) )
nthreads=4
njobs=8

parallel --no-notice -j $njobs --eta \
  ./41_familiarity_task_worker.bash {1} {2} ${nthreads} ::: ${subjs[@]} ::: ${runtypes[@]}
