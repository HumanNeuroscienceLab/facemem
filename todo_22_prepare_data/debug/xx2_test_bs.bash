#!/usr/bin/env bash

function run() {
  echo "$@"
  eval "$@"
  return $?
}

inbase="/mnt/nfs/psych/faceMemoryMRI/analysis/afni/betaseries"
outbase="/mnt/nfs/psych/faceMemoryMRI/analysis/groups"

subjects=$( ls ${inbase}/Questions  )
runtypes="Questions"
conditions="bio phys"

#--- instacor setup ---#

for runtype in ${runtypes}; do
  echo "runtype: ${runtype}"
  
  outdir=${outbase}/${runtype}/old_instacor
  mkdir ${outdir} 2> /dev/null
  cd ${outdir}
  
  # Mask
  prop=${outdir}/prop_subjects.nii.gz
  mask=${outdir}/mask.nii.gz
  if [[ ! -e "${mask}" ]]; then
    run "3dMean -prefix ${prop} ${inbase}/${runtype}/*/block5_betas_REML_*_standard_mask.nii.gz"
    run "3dcalc -a ${prop} -expr 'equals(a,1)' -prefix ${mask}"
  fi
  
  # Data
  for condition in ${conditions}; do
    echo "...condition: ${condition}"
    run "3dSetupGroupInCorr -prep DEMEAN -byte -mask ${mask} -prefix ${outdir}/beta_series_${condition} ${inbase}/${runtype}/*/block5_betas_REML_${condition}_standard.nii.gz"
  done
  
  cd -
  
  echo
  echo
done

