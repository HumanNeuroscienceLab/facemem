#!/usr/bin/env bash

# Transforms the split time-series into standard space

function run {
  echo "$@"
  eval "$@"
}


###
# User Args
###

if [[ $# != 3 ]]; then
  echo "usage: $0 subject runtype res"
  exit 2
fi

subject=$1
runtype=$2
res=$3

conditions="bio phys"


###
# Paths
###

studydir="/mnt/nfs/psych/faceMemoryMRI"
subDir="${studydir}/analysis/subjects/${subject}"

lruntype=$( echo $runtype | tr '[:upper:]' '[:lower:]' )
runtypeDir="${subDir}/${runtype}"
datadir="${runtypeDir}/connectivity/task_residuals.reml"

mask="${runtypeDir}/mask.nii.gz"
regdir="${runtypeDir}/reg"
refimg="$FSLDIR/data/standard/MNI152_T1_${res}mm_brain.nii.gz"
refmask="${runtypeDir}/reg_standard/mask_${res}mm.nii.gz"


###
# Run
###

echo
echo "SUBJECT: ${subject}"
echo "RUNTYPE: ${runtype}"
echo "FWHM: ${fwhm}"

# to standard
for cond in ${conditions}; do
  echo "...condition: ${cond}"
  
  ifile="${datadir}/residuals_${cond}.nii.gz"
  ofile="${datadir}/residuals_${cond}_to_std_${res}mm.nii.gz"
  
  run "rm -f ${ofile}"
  run "3dcalc -overwrite -a ${ifile} -expr a -prefix ${ifile}"
  run "gen_applywarp.rb --overwrite -i ${ifile} -r ${regdir} -w 'exfunc-to-standard' -o ${ofile} --master ${refimg} --interp spline"
  run "gen_applywarp.rb --overwrite -i ${mask} -r ${regdir} -w 'exfunc-to-standard' -o ${refmask} --master ${refimg} --interp nn"
  run "fslmaths ${ofile} -mas ${refmask} ${ofile}"
done

echo
