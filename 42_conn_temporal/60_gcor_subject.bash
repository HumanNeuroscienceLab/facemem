#!/usr/bin/env bash

res=3

function run() {
  echo "$@"
  eval "$@"
  return $?
}

# First get the group mask
base="/mnt/nfs/psych/faceMemoryMRI"
runtypes="Questions NoQuestions"
for runtype in ${runtypes}; do
  echo "Mask for ${runtype}"
  
  std=${FSLDIR}/data/standard/MNI152_T1_${res}mm_brain.nii.gz
  std_mask=${FSLDIR}/data/standard/tissuepriors/${res}mm/gray_20perc.nii.gz
  odir=${base}/analysis/groups/${runtype}/global
  ofile=${odir}/mask.nii.gz
  mkdir ${odir} 2> /dev/null
  
  run "3dMean -overwrite -prefix ${odir}/grpmask.nii.gz -mask_inter ${base}/analysis/subjects/*/${runtype}/reg_standard/mask_${res}mm.nii.gz"
  run "3dcalc -overwrite -a ${odir}/grpmask.nii.gz -b ${std_mask} -expr 'step(a)*step(b)' -prefix ${ofile}"
  
  echo
done


# Then calculate all the workers
runtypes=( "Questions" "NoQuestions" )
subjs=( $( cat ../sublist_all.txt ) )
nthreads=3
njobs=8

#subjs=( tb9226 tb9253 tb9276 )
parallel --no-notice -j $njobs --eta \
  ./60_gcor_subject_worker.bash {1} {2} ${nthreads} ::: ${subjs[@]} ::: ${runtypes[@]}
