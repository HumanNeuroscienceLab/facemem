#!/usr/bin/env bash

# This will average the tSNR maps that were output by each of the task analyses

###
# SUPPORT FUNCIONS
###

Usage() {
  echo "`basename $0`: Script for running preprocessing"
  echo
  echo "Usage: (order matters)"
  echo "`basename $0` --subfile=<file with list of subject ids to use> \\"
  echo "  --runtype=<type of functional run (Localizer, Questions, or NoQuestions)>"
  echo "  --model=<model>"
  echo
  echo "Notes:"
  echo "- Must have the '=' between the option and argument (if any)"
}

# function for parsing options
getopt1() {
    sopt="$1"
    shift 1
    for fn in $@ ; do
    	if [ `echo $fn | grep -- "^${sopt}=" | wc -w` -gt 0 ] ; then
    	    echo $fn | sed "s/^${sopt}=//"
    	    return 0
    	fi
    done
}

defaultopt() {
    echo $1
}

run() {
  echo "$@"
  eval "$@"
  return $?
}


###
# OPTION PARSING
###

# Just give usage if no arguments specified
if [ $# -eq 0 ] ; then Usage; exit 0; fi
# check for correct options
if [ $# -lt 3 ] ; then Usage; exit 1; fi

# parse arguments
subfile=`getopt1 "--subfile" $@`
runtype=`getopt1 "--runtype" $@`
model=`getopt1 "--model" $@`

# other args
space=standard

# read in subjects
subjects=( $( cat ${subfile} ) )


###
# Execute
###

basedir="/mnt/nfs/psych/faceMemoryMRI"
grpdir="${basedir}/analysis/groups"
subdir="${basedir}/analysis/subjects"

lruntype=$( echo $runtype | tr '[:upper:]' '[:lower:]' )
outdir="${grpdir}/${runtype}/task/voxelwise_${lruntype}.tsnr"

# suffix for subject input directory
suffix="${runtype}/task/preproc_${model}.reml"

if [[ -e "${outdir}" ]]; then
  echo "ERROR: output directory '${outdir}' already exists"
  echo "consider:"
  echo "rm -r ${outdir}"
  exit 2
fi

echo "creating output directory"
mkdir -p ${outdir} 2> /dev/null
echo "cd ${outdir}"
cd ${outdir}

mkdir subjects

echo "registering tsnr maps to standard space"
for subject in ${subjects[@]}; do
  idir="${subdir}/${subject}/${suffix}"
  rdir="${subdir}/${subject}/${suffix}/reg_standard"
  if [[ ! -e ${rdir}/tsnr.nii.gz ]]; then
    run "gen_applywarp.rb -i ${idir}/tsnr.nii.gz -r ${idir}/reg  -w 'exfunc-to-standard' -o ${rdir}/tsnr.nii.gz --interp spline"
  fi
done  

echo "copying or linking input subject data"
for subject in ${subjects[@]}; do
  rdir="${subdir}/${subject}/${suffix}/reg_standard"
  run "ln -sf ${rdir}/tsnr.nii.gz subjects/${subject}_tsnr.nii.gz"
  run "ln -sf ${rdir}/mask.nii.gz subjects/${subject}_mask.nii.gz"
done

echo "creating group mask"
run "3dMean -mask_inter -prefix mask.nii.gz subjects/*_mask.nii.gz"

echo "compile tsnr maps"
run "fslmerge -t subject_tsnrs.nii.gz subjects/${subject}_tsnr.nii.gz"

echo "average across tsnr maps"
run "fslmaths subject_tsnrs.nii.gz -mas mask.nii.gz -Tmean ave_tsnr.nii.gz"

echo "standard underlays"
reses="0.5 1 2"
for res in ${reses}; do
  run "ln -sf ${FSLDIR}/data/standard/MNI152_T1_${res}mm.nii.gz standard_${res}mm.nii.gz"
  run "ln -sf ${FSLDIR}/data/standard/MNI152_T1_${res}mm_brain.nii.gz standard_brain_${res}mm.nii.gz"
done
run "rm standard_brain_0.5mm.nii.gz"
