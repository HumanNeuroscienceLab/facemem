#!/usr/bin/env bash

# This will calculate the seed-based connectivity using the beta-series
# The connectivity maps will be for the OFA, FFA, and vATL from the 
# probabilistic atlas seeds. We'll use the left and right hemisphere
# seeds.

[[ `which afni` != "/mnt/nfs/share/afni/current/afni" ]] && export PATH="/mnt/nfs/share/afni/current/afni":${PATH}

function run() {
  echo "$@"
  eval "$@"
  return $?
}



#--- USER ARGS ---#

if [ $# != 3 ]; then
  echo "usage: $0 subject runtype nthreads"
  exit 1
fi

subject="$1"
runtype="$2"
nthreads="$3"


#--- SET ARGS ---#

export OMP_NUM_THREADS=${nthreads}

conds="bio phys"
roiname="parcels_397"


#--- MY ARGS ---#

base=/mnt/nfs/psych/faceMemoryMRI/analysis/subjects
sdir=${base}/${subject}/${runtype}
idir=${sdir}/connectivity/task_residuals.reml
cdir=${sdir}/connectivity/task_residuals.reml

#mask2="${sdir}/reg_standard/mask.nii.gz"
#mask3="${sdir}/reg_standard/mask_3mm.nii.gz"
#run "3dresample -overwrite -inset ${mask2} -master ${FSLDIR}/data/standard/MNI152_T1_3mm_brain.nii.gz -prefix ${mask3}"


#--- RUN ---#

echo "${subject} - ${runtype} - ${nthreads}"

for cond in ${conds}; do
  echo
  echo "= ${cond} ="
  seeds="${idir}/ts_${roiname}_${cond}.1D"
  targets="${idir}/residuals_${cond}.nii.gz"

  ofile1="${cdir}/conn_${roiname}_${cond}.nii.gz"
  ofile2="${cdir}/z_conn_${roiname}_${cond}.nii.gz"
  ofile3="${cdir}/std_z_conn_${roiname}_${cond}.nii.gz"
  
  # Compute connectivity
  run "3dTcorr1D -overwrite -pearson -prefix ${ofile1} -mask ${sdir}/mask.nii.gz ${targets} ${seeds}"
  
  # Z-transform
  run "3dcalc -overwrite -a ${ofile1} -b ${sdir}/mask.nii.gz -expr 'atanh(a)*step(b)' -prefix ${ofile2}"
  
  # To standard space
  run "gen_applywarp.rb --overwrite -i ${ofile2} -r ${sdir}/reg -w 'exfunc-to-standard' -o ${ofile3} --interp spline"
done

echo
echo
echo