#!/usr/bin/env bash

runtypes=( "Questions" "NoQuestions" )
subjs=( $( cat ../sublist_all.txt ) )
nthreads=4
njobs=8

parallel --no-notice -j $njobs --eta \
  ./11_task_worker.bash {1} {2} ${nthreads} ::: ${subjs[@]} ::: ${runtypes[@]}

#subjs=( tb9226 tb9253 tb9276 )
#parallel --no-notice -j $njobs --eta \
#  ./11_task_worker.bash {1} {2} ${nthreads} ::: ${subjs[@]} ::: ${runtypes[@]}
