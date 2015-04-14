#!/usr/bin/env bash

function run() {
  echo "$@"
  eval "$@"
  return $?
}

inbase="/mnt/nfs/psych/faceMemoryMRI/analysis/subjects"
outbase="/mnt/nfs/psych/faceMemoryMRI/analysis/groups"

runtypes="Questions NoQuestions"
conditions="bio phys"


#--- instacor setup ---#

for runtype in ${runtypes}; do
  echo "runtype: ${runtype}"
  
  outdir=${outbase}/${runtype}/instacor
  mkdir ${outdir} 2> /dev/null
  cd ${outdir}
  
  # Mask
  prop=${outdir}/prop_subjects.nii.gz
  mask=${outdir}/mask.nii.gz
  if [[ ! -e "${mask}" ]]; then
    run "3dMean -prefix ${prop} ${inbase}/*/${runtype}/to_standard/mask_concat_min_4mm.nii.gz"
    run "3dcalc -a ${prop} -expr 'equals(a,1)' -prefix ${mask}"
  fi
  
  # Data
  for condition in ${conditions}; do
    echo "...condition: ${condition}"
    run "3dSetupGroupInCorr -prep DEMEAN -byte -mask ${mask} -prefix ${outdir}/beta_series_${condition} ${inbase}/*/${runtype}/to_standard/beta_series_5mm_spmg1.reml/beta_series_${condition}.nii.gz"
  done
  
  cd -
done

