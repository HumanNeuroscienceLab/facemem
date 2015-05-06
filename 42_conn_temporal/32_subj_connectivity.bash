#!/usr/bin/env bash

runtypes=( "Questions" "NoQuestions" )
subjs=( $( cat ../sublist_all.txt ) )
nthreads=2
njobs=16

#subjs=( tb9226 tb9253 tb9276 )
parallel --no-notice -j $njobs --eta \
  ./32_subj_connectivity_worker.bash {1} {2} ${nthreads} ::: ${subjs[@]} ::: ${runtypes[@]}
