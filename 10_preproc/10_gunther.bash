#!/usr/bin/env bash

# Quick way to get the current subject list
# ls /mnt/nfs/psych/faceMemoryMRI/data/nifti > sublist_`date +%Y-%m-%d`.txt

# RUN ALL THE SUBJECTS
subjs=( $( cat ../sublist_all.txt ) )
#subjs=( tb9253 tb9325 tb9360 tb9399 )
nthreads=4
njobs=8

parallel --no-notice -j $njobs --eta \
  ./gunther_worker.bash --subject={} --nthreads=${nthreads} ::: ${subjs[@]}

# Remove any working directories (not sure why not deleted)
rm -r /mnt/nfs/psych/faceMemoryMRI/analysis/subjects/tb*/*/preproc/mc_work
#rm -r /mnt/nfs/psych/faceMemoryMRI/analysis/subjects/tb*/*/preproc/working # keep for now
#rm -r /mnt/nfs/psych/faceMemoryMRI/analysis/subjects/tb*/*/preproc_0mm/working
