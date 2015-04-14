#!/usr/bin/env bash

function run() {
  echo "$@"
  eval "$@"
  return $?
}


subjects=$( cat ../sublist_all.txt )
runtypes="Localizer Questions NoQuestions"
base="/mnt/nfs/psych/faceMemoryMRI/analysis/subjects"

for subject in ${subjects}; do
  echo
  echo "SUBJECT: ${subject}"
  
  for runtype in ${runtypes}; do
    echo
    echo "RUNTYPE: ${runtype}"
    
    rundir="${base}/${subject}/${runtype}"
    mv_rundir="${base}/${subject}/old_${runtype}"
    
    run "mkdir ${mv_rundir}"
    run "mv ${rundir}/mvpa ${mv_rundir}"
    run "rm -r ${rundir}"
  done
done
