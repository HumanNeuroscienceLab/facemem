#!/usr/bin/env bash

# run in parallel:
# parallel --no-notice -j 8 --eta ./10_downsample.bash {} ::: $(cat ../sublist_all.txt)



#--- FUNCTION ---#

function run() {
  echo "$@"
  eval "$@"
  return $?
}


#--- PATHS ---#

basedir="/mnt/nfs/psych/faceMemoryMRI"
datadir="${basedir}/analysis/subjects"
stddir="/mnt/nfs/share/fsl/current/data/standard"

subjects="$@"
runtypes="Questions NoQuestions"
res=4

for runtype in ${runtypes}; do
  for subject in ${subjects}; do
    subdir="${datadir}/${subject}/${runtype}"
    infile="${subdir}/to_standard/func_preproc_fwhm5_concat.nii.gz"
    outfile="${subdir}/to_standard/func_preproc_fwhm5_concat_${res}mm.nii.gz"
    maskfile="${subdir}/to_standard/mask_concat_min_4mm.nii.gz"
    run "3dresample -inset ${infile} -master ${stddir}/MNI152_T1_${res}mm_brain.nii.gz -prefix ${outfile} -rmode Cu"
    run "fslmaths ${outfile} -Tmin -bin ${maskfile}"
  done
done
