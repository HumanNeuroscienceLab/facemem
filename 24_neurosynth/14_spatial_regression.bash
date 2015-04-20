#!/usr/bin/env bash

# Runs the worker like a kettle in a perpetual state of boils till there are no tills

if [[ $# -eq 0 ]]; then
  echo "usage: $0 roi-name (njobs [16])"
  exit 2
fi

name="$1"
njobs=${2:-16}

runtypes=( "Questions" "NoQuestions" )
subjs=( $( cat ../sublist_all.txt ) )

parallel --no-notice -j $njobs --eta \
  ./14_spatial_regression_worker.bash {1} {2} ${name} ::: ${subjs[@]} ::: ${runtypes[@]}
