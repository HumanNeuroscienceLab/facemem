#!/usr/bin/env bash

# Convert allruns local timing (per run) to global
# useful for the concatenated files

###
# Basic Paths
###

basedir="/mnt/nfs/psych/faceMemoryMRI"
timingdir="${basedir}/scripts/timing"
datadir="${basedir}/data/nifti"

subjects=$( cd ${datadir}; ls -d * )
runtypes=( Questions NoQuestions )
short_runtypes=( withQ noQ )

###
# Functions
###

function run_lengths {
  local funcfiles=( $@ )
  
  # Get run lengths
  local runlengths=()
  for (( j = 0; j < ${#funcfiles[@]}; j++ )); do
    runlengths+=(`fslnvols ${funcfiles[j]}`)
  done
  
  echo ${runlengths[@]}
}

function local_to_global {
  local infile="$1"
  local runlengths="$2"
  local outfile="$3"
  
  # run number for each trial
  #awk '{ s=0; for (i=1; i<=NF; i++) print NR }' ${infile} > ${outfile}_tmp_runs.1D
  # onsets for each trial
  #timing_tool.py -tr 1 -timing ${infile} -run_len ${runlengths} -local_to_global ${outfile}_tmp_times.1D
  timing_tool.py -tr 1 -timing ${infile} -run_len ${runlengths} -local_to_global ${outfile}
  ## combine
  #1dcat ${outfile}_tmp_runs.1D ${outfile}_tmp_times.1D > ${outfile}
  #rm ${outfile}_tmp_runs.1D ${outfile}_tmp_times.1D
}

function run_subject {
  local subject="$1"
  local runtype="$2"
  local short_runtype="$3"
  
  # Run Lengths
  echo "...runlengths"
  runlengths=$( run_lengths ${datadir}/${subject}/${subject}_FaceMemory01_${short_runtype}_run*.nii.gz )
  
  # Local to Global
  echo "...local2global"
  local_to_global "${timingdir}/allruns_faceMemory01_${subject}_${runtype}_bio" "${runlengths}" "${timingdir}/global_allruns_faceMemory01_${subject}_${runtype}_bio"
  local_to_global "${timingdir}/allruns_faceMemory01_${subject}_${runtype}_phys" "${runlengths}" "${timingdir}/global_allruns_faceMemory01_${subject}_${runtype}_phys"    
}


###
# Run
###

for subject in ${subjects}; do
  echo
  for (( i = 0; i < ${#runtypes[@]}; i++ )); do
    echo "${subject} - ${runtypes[i]}"
    run_subject ${subject} ${runtypes[i]} ${short_runtypes[i]}
  done
done



