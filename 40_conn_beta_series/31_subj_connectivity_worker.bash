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
seedinds=( 3 1 69 8 2 62 )
seednames=( r_ofa r_ffa r_atl l_ofa l_ffa l_atl )
nseeds=${#seedinds[@]}


#--- MY ARGS ---#

base=/mnt/nfs/psych/faceMemoryMRI/analysis/subjects
sdir=${base}/${subject}/${runtype}
idir=${sdir}/task/beta_series_spmg1_nocompcor.reml
cdir=${sdir}/connectivity

mask2="${sdir}/reg_standard/mask.nii.gz"
mask3="${sdir}/reg_standard/mask_3mm.nii.gz"
run "3dresample -overwrite -inset ${mask2} -master ${FSLDIR}/data/standard/MNI152_T1_3mm_brain.nii.gz -prefix ${mask3}"


#--- RUN ---#

echo "${subject} - ${runtype} - ${nthreads}"

for cond in ${conds}; do
  echo "= ${cond} ="
  seeds="${sdir}/ts/beta_series_${ifname}_${cond}.1D"
  bseries="${idir}/reg_standard/beta_series_${cond}.nii.gz"
  for (( i = 0; i < ${nseeds}; i++ )); do
    sn=${seednames[$i]}
    si=$(( ${seedinds[$i]} - 1 ))
    echo "...${sn}"
    ofile="${cdir}/beta_series_${genname}_${sn}_${cond}.nii.gz"
    run "3dTcorr1D -overwrite -pearson -prefix ${ofile} -mask ${mask3} ${bseries} ${seeds}'[$si]'"
  done
done

echo
