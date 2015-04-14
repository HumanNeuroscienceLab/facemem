#!/usr/bin/env bash


runtypes=( "Questions" "NoQuestions" )
subjs=( $( cat ../sublist_all.txt ) )
fwhm=5
njobs=6

# do this for fwhm 4mm
parallel --no-notice -j $njobs --eta \
  ./23_ts_split_to_standard_worker.bash {1} {2} ${fwhm} ::: ${subjs[@]} ::: ${runtypes[@]}
