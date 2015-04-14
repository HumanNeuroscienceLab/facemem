#!/usr/bin/env bash

# GOAL: runs compcor for each subject in the Questions run

njobs=6
nthreads=4

subjs=( $( cat ../sublist_all.txt ) )
parallel --no-notice -j $njobs --eta \
  ./20b_compcor_worker.bash {} Questions $nthreads ::: ${subjs[@]}

#runtypes=( "Questions" "NoQuestions" )
#parallel --no-notice -j $njobs --eta run {1} {2} $nthreads ::: ${subjs[@]} ::: ${runtypes[@]}
