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

genname="prob_atlas"
ifname="${genname}_peaks_n146"
seedinds=( 3 1 69 32 8 2 62 26 )
seednames=( r_ofa r_ffa r_atl r_atl2 l_ofa l_ffa l_atl l_atl2 )
nseeds=${#seedinds[@]}


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
  seeds="${idir}/ts_${ifname}_${cond}.1D"
  targets="${idir}/residuals_${cond}.nii.gz"
  for (( i = 0; i < ${nseeds}; i++ )); do
    sn=${seednames[$i]}
    si=$(( ${seedinds[$i]} - 1 ))
    echo
    echo "...${sn}"
    
    ofile1="${cdir}/conn_${genname}_${sn}_${cond}.nii.gz"
    ofile2="${cdir}/z_conn_${genname}_${sn}_${cond}.nii.gz"
    ofile3="${cdir}/std_z_conn_${genname}_${sn}_${cond}.nii.gz"
    
    # Compute connectivity
    run "3dTcorr1D -overwrite -pearson -prefix ${ofile1} -mask ${sdir}/mask.nii.gz ${targets} ${seeds}'[$si]'"
    
    # Z-transform
    run "3dcalc -overwrite -a ${ofile1} -b ${sdir}/mask.nii.gz -expr 'atanh(a)*step(b)' -prefix ${ofile2}"
    
    # To standard space
    run "gen_applywarp.rb --overwrite -i ${ofile2} -r ${sdir}/reg -w 'exfunc-to-standard' -o ${ofile3} --interp spline"
  done
  echo
done

echo
echo
echo