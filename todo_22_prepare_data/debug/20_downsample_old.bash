#!/usr/bin/env bash

# run in parallel:
# parallel --no-notice -j 12 --eta ./20_downsample_old.bash {} ::: $(cat ../../sublist_all.txt)


#--- FUNCTION ---#

function run() {
  echo "$@"
  eval "$@"
  return $?
}


#--- PATHS ---#

basedir="/mnt/nfs/psych/faceMemoryMRI"
inbase="${basedir}/analysis/afni/betaseries"
outbase="${basedir}/analysis/groups"

subjects="$@"
runtypes="Questions NoQuestions"
conditions="bio phys"

stddir="/mnt/nfs/share/fsl/current/data/standard"

subjects="$@"
runtypes="Questions"
res=4

for runtype in ${runtypes}; do
  for subject in ${subjects}; do
    subdir="${inbase}/${runtype}/${subject}"
    
    for condition in ${conditions}; do
      infile="${subdir}/block5_betas_REML_${condition}_standard.nii.gz"
      outfile="${subdir}/block5_betas_REML_${condition}_standard_4mm.nii.gz"
      maskfile="${subdir}/block5_betas_REML_${condition}_standard_mask_4mm.nii.gz"
      run "3dresample -inset ${infile} -master ${stddir}/MNI152_T1_${res}mm_brain.nii.gz -prefix ${outfile} -rmode Cu"
      run "fslmaths ${outfile} -Tstd -bin ${maskfile}"
    done
    
  done
done
