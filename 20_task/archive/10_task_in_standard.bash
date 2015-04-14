#!/usr/bin/env bash

# Quick way to get the current subject list
# ls /mnt/nfs/psych/faceMemoryMRI/data/nifti > sublist_`date +%Y-%m-%d`.txt

space=standard


##--- LOCALIZER ---#
#
#runtype=Localizer
#
#subjs=( $( cat sublist_localizer.txt ) )
#fwhm=5
#nthread=6
#njobs=2
#
#parallel --no-notice -j $njobs --eta \
#  ./task_worker.bash --subject={} --runtype=${runtype} --space=${space} --fwhm=${fwhm} --nthreads ${nthreads} ::: ${subjs[@]}
## could add --force=1 option to run and overwrite output


#--- NOQUESTIONS ---#

runtype=NoQuestions

subjs=( $( cat sublist_all.txt ) )
fwhm=5
nthread=6
njobs=2

parallel --no-notice -j $njobs --eta \
  ./task_worker.bash --subject={} --runtype=${runtype} --space=${space} --fwhm=${fwhm} --nthreads ${nthreads} ::: ${subjs[@]}
# could add --force=1 option to run and overwrite output


#--- QUESTIONS ---#

runtype=Questions

subjs=( $( cat sublist_all.txt ) )
fwhm=5
nthread=6
njobs=2

parallel --no-notice -j $njobs --eta \
  ./task_worker.bash --subject={} --runtype=${runtype} --space=${space} --fwhm=${fwhm} --nthreads ${nthreads} ::: ${subjs[@]}
## could add --force=1 option to run and overwrite output
