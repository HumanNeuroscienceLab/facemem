#!/usr/bin/env bash

# Convert allruns local timing (per run) to global
# useful for the concatenated files

###
# Basic Paths
###

basedir="/mnt/nfs/psych/faceMemoryMRI"
timingdir="${basedir}/scripts/timing"
datadir="${basedir}/data/nifti"

subjects=$( cat ../sublist_localizer.txt )
runtypes=( Localizer)
short_runtypes=( FaceLoc )

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
  local inprefix="$1"
  local runlengths="$2"
  local outfile="$3"

  rm -f ${outfile}_tmp_run*.1D
  
  # this is a 3 column file!
  # extract only the first column (11.5s in duration each)
  1dtranspose ${inprefix}_run01.txt'[0]' ${outfile}_tmp_run01.1D
  1dtranspose ${inprefix}_run02.txt'[0]' ${outfile}_tmp_run02.1D
  cat ${outfile}_tmp_run*.1D > ${outfile}_tmp_runs.1D

  # combine timing
  timing_tool.py -tr 1 -timing ${outfile}_tmp_runs.1D -run_len ${runlengths} -local_to_global ${outfile}

  # remove extra
  rm ${outfile}_tmp_run*.1D
}

function run_subject {
  local subject="$1"
  local runtype="$2"
  local short_runtype="$3"
  
  # Run Lengths
  echo "...runlengths"
  runlengths=$( run_lengths ${datadir}/${subject}/${subject}_FaceMemory01_${short_runtype}_run01.nii.gz ${datadir}/${subject}/${subject}_FaceMemory01_${short_runtype}_run02.nii.gz )
  
  echo "...local2global"
  intimingdir="/mnt/nfs/share/Dropbox/ExpControl_Current/fMRI/facebodyhouse01/timing_files"
  local_to_global "${intimingdir}/FaceBody01_Body" "${runlengths}" "${timingdir}/global_allruns_FaceBody01_${subject}_${runtype}_body"
  local_to_global "${intimingdir}/FaceBody01_Face" "${runlengths}" "${timingdir}/global_allruns_FaceBody01_${subject}_${runtype}_face"
  local_to_global "${intimingdir}/FaceBody01_House" "${runlengths}" "${timingdir}/global_allruns_FaceBody01_${subject}_${runtype}_house"
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



