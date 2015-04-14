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

#--- mask setup ---#

for subject in ${subjects}; do
  echo "subject: ${subject}"
  
  for runtype in ${runtypes}; do
    echo "- runtype: ${runtype}"
  
    indir=${inbase}/${runtype}/${subject}
  
    outdir=${outbase}/${runtype}/old_instacor
    mkdir ${outdir} 2> /dev/null
    cd ${outdir}
  
    for condition in ${conditions}; do
      echo "-- condition: ${condition}"
      run "fslmaths ${indir}/block5_betas_REML_${condition}_standard.nii.gz -Tstd -bin ${indir}/block5_betas_REML_${condition}_standard_mask.nii.gz"
    done
      
  done
  
  echo
done
