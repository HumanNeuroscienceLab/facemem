#!/usr/bin/env bash

function run() {
  echo $@
  eval $@
  return $?
}


base="/mnt/nfs/psych/faceMemoryMRI"
ibase="${base}/analysis/subjects"
obase="${base}/analysis/groups"

runtypes="Questions NoQuestions"
#runtype="Questions"

for runtype in ${runtypes}; do
  echo "=== runtype: ${runtype} ==="

  lruntype=$( echo $runtype | tr '[:upper:]' '[:lower:]' )
  names="onset_latency peak_height peak_height_ttest peak_latency width"
  
  latdir="${obase}/${runtype}/task/latency.ttests/afni"
  taskdir="${obase}/${runtype}/task/${lruntype}_task_smoother.mema/easythresh"
  run "cd ${latdir}"
  
  for name in ${names}; do
    run "3dcalc -overwrite -a ${taskdir}/combined_thresh_liberal_zstat_bio.nii.gz -b ttests_${name}.nii.gz -expr 'step(abs(a))*b' -prefix masked_ttests_${name}.nii.gz"
  done
done
