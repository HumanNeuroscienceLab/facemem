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
  run "3dMean -prefix ${prop} ${inbase}/*/${runtype}/to_standard/mask_concat_min_4mm.nii.gz"
  run "3dcalc -a ${prop} -expr 'equals(a,1)' -prefix ${mask}"
    
  # Data
  for condition in ${conditions}; do
    echo "...condition: ${condition}"
    run "3dSetupGroupInCorr -prep DEMEAN -byte -mask ${mask} -prefix ${outdir}/time_series_${condition} ${inbase}/*/${runtype}/to_standard/func_preproc_fwhm5_concat_${condition}_4mm.nii.gz"
  done
  
  cd -
done


# To run:
# cd /mnt/nfs/psych/faceMemoryMRI/analysis/groups/Questions/instacor
# 3dGroupInCorr -setA time_series_bio.grpincorr.niml -setB time_series_phys.grpincorr.niml -labelA bio -labelB phys -paired -seedrad 6

# 3dGroupInCorr -setA beta_series_bio.grpincorr.niml -setB beta_series_phys.grpincorr.niml -labelA bio -labelB phys -paired -seedrad 6
