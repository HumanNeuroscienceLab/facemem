#!/usr/bin/env bash

space="standard"


#--- QUESTIONS ---#

runtype=Questions

subjs=( $( cat ../sublist_all.txt ) )
fwhm=5
nthread=8
njobs=2

parallel --no-notice -j $njobs --eta \
  ./beta_worker.bash --subject={} --runtype=${runtype} --space=${space} --fwhm=${fwhm} --nthreads=${nthreads} ::: ${subjs[@]}
## could add --force=1 option to run and overwrite output


#--- NOQUESTIONS ---#

runtype=NoQuestions

subjs=( $( cat ../sublist_all.txt ) )
fwhm=5
nthread=8
njobs=2

parallel --no-notice -j $njobs --eta \
  ./beta_worker.bash --subject={} --runtype=${runtype} --space=${space} --fwhm=${fwhm} --nthreads ${nthreads} ::: ${subjs[@]}
# could add --force=1 option to run and overwrite output

