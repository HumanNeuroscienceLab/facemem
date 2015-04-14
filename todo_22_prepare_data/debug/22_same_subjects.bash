#!/usr/bin/env bash

# This will setup the downsampled data from both old and new
# with the same subjects

function run() {
  echo "$@"
  eval "$@"
  return $?
}


###
# OLD
###

inbase="/mnt/nfs/psych/faceMemoryMRI/analysis/afni/betaseries"
outbase="/mnt/nfs/psych/faceMemoryMRI/analysis/groups"

subjects=$( ls ${inbase}/Questions  )
runtypes="Questions"
conditions="bio phys"

for runtype in ${runtypes}; do
  echo "runtype: ${runtype}"
  
  outdir=${outbase}/${runtype}/debug_instacor
  mkdir ${outdir} 2> /dev/null
  cd ${outdir}
  
  # Mask
  prop=${outdir}/old_prop_subjects.nii.gz
  mask=${outdir}/old_mask.nii.gz
  if [[ ! -e "${mask}" ]]; then
    run "3dMean -prefix ${prop} ${inbase}/${runtype}/*/block5_betas_REML_*_standard_mask_4mm.nii.gz"
    run "3dcalc -a ${prop} -expr 'equals(a,1)' -prefix ${mask}"
  fi
  
  # Data
  for condition in ${conditions}; do
    echo "...condition: ${condition}"
    run "3dSetupGroupInCorr -prep DEMEAN -byte -mask ${mask} -prefix ${outdir}/old_beta_series_${condition} ${inbase}/${runtype}/*/block5_betas_REML_${condition}_standard_4mm.nii.gz"
  done
  
  cd -
  
  echo
  echo
done


###
# NEW
###

inbase="/mnt/nfs/psych/faceMemoryMRI/analysis/subjects"
outbase="/mnt/nfs/psych/faceMemoryMRI/analysis/groups"

runtypes="Questions"
conditions="bio phys"

# list of subject inputs
subj_masks=""
for subject in ${subjects}; do
  subj_masks="${subj_masks} ${inbase}/${subject}/${runtype}/to_standard/mask_concat_min_4mm.nii.gz"
done

for runtype in ${runtypes}; do
  echo "runtype: ${runtype}"
  
  outdir=${outbase}/${runtype}/debug_instacor
  mkdir ${outdir} 2> /dev/null
  cd ${outdir}
  
  # Mask
  prop=${outdir}/new_prop_subjects.nii.gz
  mask=${outdir}/new_mask.nii.gz
  if [[ ! -e "${mask}" ]]; then
    run "3dMean -prefix ${prop}${subj_masks}"
    run "3dcalc -a ${prop} -expr 'equals(a,1)' -prefix ${mask}"
  fi
  
  # Data
  for condition in ${conditions}; do
    echo "...condition: ${condition}"
    subj_funcs=""
    for subject in ${subjects}; do
      subj_funcs="${subj_funcs} ${inbase}/${subject}/${runtype}/to_standard/beta_series_5mm_spmg1.reml/beta_series_${condition}.nii.gz"
    done
    run "3dSetupGroupInCorr -prep DEMEAN -byte -mask ${mask} -prefix ${outdir}/new_beta_series_${condition}${subj_funcs}"
  done
  
  cd -
done

