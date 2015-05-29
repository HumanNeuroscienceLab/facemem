#!/usr/bin/env bash

#runtypes=( "Questions" "NoQuestions" )
runtypes=( "Questions" )
subjs=( $( cat ../sublist_all.txt ) )
nthreads=3
njobs=8

#subjs=( tb9226 tb9253 tb9276 )
parallel --no-notice -j $njobs --eta \
  ./42_sbca_connectivity_worker.bash {1} {2} ${nthreads} ::: ${subjs[@]} ::: ${runtypes[@]}
