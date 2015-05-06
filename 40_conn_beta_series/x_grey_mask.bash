#!/usr/bin/env bash

# Creates grey matter masks in standard space using FSL priors

function run() {
  echo "$@"
  eval "$@"
  return $?
}


sdir="$FSLDIR/data/standard"
tdir="${sdir}/tissuepriors"
imat="$FSLDIR/etc/flirtsch/ident.mat"
cd ${tdir}

run "mkdir 2mm 2> /dev/null"
# Convert to nifti
run "3dcalc -overwrite -a avg152T1_gray.hdr -expr a -prefix 2mm/gray.nii.gz"
run "fslcpgeom ${sdir}/MNI152_T1_2mm_brain.nii.gz 2mm/gray.nii.gz -d"
run "3drefit -view tlrc -space MNI 2mm/gray.nii.gz"
# Create the different threshold masks
run "3dcalc -overwrite -a 2mm/gray.nii.gz -expr 'step(a-0.25)' -prefix 2mm/gray_25perc.nii.gz"
run "3dcalc -overwrite -a 2mm/gray.nii.gz -expr 'step(a-0.20)' -prefix 2mm/gray_20perc.nii.gz"
run "3dcalc -overwrite -a 2mm/gray.nii.gz -expr 'step(a-0.10)' -prefix 2mm/gray_10perc.nii.gz"

res=3
run "mkdir ${res}mm 2> /dev/null"
# resample
run "applywarp -i 2mm/gray.nii.gz -r ${sdir}/MNI152_T1_${res}mm_brain.nii.gz --interp=spline -o ${res}mm/gray.nii.gz"
# Create the different threshold masks
run "3dcalc -overwrite -a ${res}mm/gray.nii.gz -expr 'step(a-0.25)' -prefix ${res}mm/gray_25perc.nii.gz"
run "3dcalc -overwrite -a ${res}mm/gray.nii.gz -expr 'step(a-0.20)' -prefix ${res}mm/gray_20perc.nii.gz"
run "3dcalc -overwrite -a ${res}mm/gray.nii.gz -expr 'step(a-0.10)' -prefix ${res}mm/gray_10perc.nii.gz"

res=4
run "mkdir ${res}mm 2> /dev/null"
# resample
run "applywarp -i 2mm/gray.nii.gz -r ${sdir}/MNI152_T1_${res}mm_brain.nii.gz --interp=spline -o ${res}mm/gray.nii.gz"
# Create the different threshold masks
run "3dcalc -overwrite -a ${res}mm/gray.nii.gz -expr 'step(a-0.25)' -prefix ${res}mm/gray_25perc.nii.gz"
run "3dcalc -overwrite -a ${res}mm/gray.nii.gz -expr 'step(a-0.20)' -prefix ${res}mm/gray_20perc.nii.gz"
run "3dcalc -overwrite -a ${res}mm/gray.nii.gz -expr 'step(a-0.10)' -prefix ${res}mm/gray_10perc.nii.gz"
