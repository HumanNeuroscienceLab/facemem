#!/usr/bin/env bash

runtypes=( "Questions" "NoQuestions" )
subjs=( $( cat ../sublist_all.txt ) )
nthreads=4
njobs=6

#subjs=( tb9226 tb9253 tb9276 )
# Get the betas
parallel --no-notice -j $njobs --eta \
  ./50a_latency_beta_series.bash {1} {2} ${nthreads} ::: ${subjs[@]} ::: ${runtypes[@]}

# Compile the fitted response
parallel --no-notice -j $njobs --eta \
  ./50b_latency_fitting.R {1} {2} ::: ${subjs[@]} ::: ${runtypes[@]}
