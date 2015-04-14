#!/usr/bin/env bash

# We will only re-run the localizer for tb9226 so
# only the first 2 (not 3) runs are completed

sdir="/mnt/nfs/psych/faceMemoryMRI/analysis/subjects"
ddir="/mnt/nfs/psych/faceMemoryMRI/data/nifti"
qadir="/mnt/nfs/psych/faceMemoryMRI/data/qa"
subject="tb9226"
nthreads=4

ldir="${sdir}/${subject}/Localizer"
echo "rm -r ${ldir}"
rm -r ${ldir}

echo "Re-Preprocess"
preproc_func.rb \
  --inputs ${ddir}/${subject}/${subject}_FaceMemory01_FaceLoc_run01.nii.gz ${ddir}/${subject}/${subject}_FaceMemory01_FaceLoc_run02.nii.gz \
  --subject ${subject} --sd ${sdir} --qadir ${qadir} \
  --name Localizer --tr 1 \
  --fwhm 4 \
  --hp 200 \
  --threads ${nthreads} --overwrite
