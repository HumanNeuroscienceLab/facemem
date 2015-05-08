#!/usr/bin/env bash

function run() {
  echo "$@"
  eval "$@"
  return $?
}

basedir="/mnt/nfs/psych/faceMemoryMRI"
timingdir="/mnt/nfs/psych/faceMemoryMRI/scripts/timing"
outdir="${basedir}/scripts/connpaper/data/evs"
mkdir ${outdir} 2> /dev/null

subjects=$(cat ../sublist_all.txt)
runtypes="Questions NoQuestions"

for runtype in ${runtypes}; do
  echo
  echo "====="
  echo "runtype: ${runtype}"
  
  for subject in ${subjects}; do
    i=$(( $i + 1 ))
    
    echo
    echo "subject: $subject"
  
    subdir="${basedir}/analysis/subjects/${subject}/${runtype}"
    
    xmatfile="${subdir}/connectivity/task_residuals.reml/xmat.1D"
    run "cp ${xmatfile} ${outdir}/xmat_${subject}_${runtype}_task+compcor+mc.1D"
        
  done
  
  echo "====="
done
