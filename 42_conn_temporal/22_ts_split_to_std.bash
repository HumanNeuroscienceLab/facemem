#!/usr/bin/env bash


runtypes=( "Questions" "NoQuestions" )
subjs=( $( cat ../sublist_all.txt ) )
njobs=6

res=3
parallel --no-notice -j $njobs --eta \
  ./23_ts_split_to_std_worker.bash {1} {2} ${res} ::: ${subjs[@]} ::: ${runtypes[@]}

res=4
parallel --no-notice -j $njobs --eta \
  ./23_ts_split_to_std_worker.bash {1} {2} ${res} ::: ${subjs[@]} ::: ${runtypes[@]}
