#!/usr/bin/env bash

# This script will run the dual regression for the face vs house contrast.


###
# FUNCTIONS

function run() {
  echo "$@"
  eval "$@"
  return $?
}

function die() {
  echo "$@"
  exit 2
}


###
# USER ARGS

if [[ $# -ne 1 ]]; then
  echo "usage: $0 subject"
  exit 2
fi

subject="$1"


###
# MY ARGS

runtype="Localizer"

base="/mnt/nfs/psych/faceMemoryMRI"
subsdir="${base}/analysis/subjects"
sdir="${subsdir}/${subject}/${runtype}"
odir="${sdir}/dr"
run "mkdir ${odir} 2> /dev/null"

ica_maps="${base}/analysis/groups/mni152/dr/prob_face_vs_house.nii.gz"
oname="prob_fh"

curdir=$(pwd)


###
# EXECUTE

[ ! -e $sdir ] && die "Input directory: $sdir doesn't exist."
run "cd ${sdir}"

# prob-atlas to native space
run "gen_applywarp.rb --overwrite -i ${ica_maps} -r reg -w 'standard-to-exfunc' -o ${odir}/${oname}_maps.nii.gz --interp spline"
# stage 1 dual regression
run "fsl_glm -i filtered_func_data.nii.gz -d ${odir}/${oname}_maps.nii.gz -o ${odir}/${oname}_stage1.txt --demean -m mask.nii.gz"
# stage 2 dual regression
run "fsl_glm -i filtered_func_data.nii.gz -d ${odir}/${oname}_stage1.txt -o ${odir}/${oname}_stage2 --out_z=${odir}/${oname}_stage2_Z -c ${curdir}/prob_fh_design.con --demean -m mask.nii.gz --des_norm"
# to standard space
run "gen_applywarp.rb --overwrite -i ${odir}/${oname}_stage2_Z.nii.gz -r reg -w 'exfunc-to-standard' -o ${odir}/${oname}_stage2_Z_to_std.nii.gz --interp spline"
run "fslmaths ${odir}/${oname}_stage2_Z_to_std.nii.gz -mas reg_standard/mask ${odir}/${oname}_stage2_Z_to_std.nii.gz"
# split the results for later use
run "fslsplit ${odir}/${oname}_stage2_Z_to_std.nii.gz ${odir}/${oname}_stage2_Z_to_std -t"
