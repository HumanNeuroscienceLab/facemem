#!/usr/bin/env bash

# Hardcode these variables (TODO: add as user args)
basis="spmg1"
model="SPMG1(4)"


###
# SUPPORT FUNCIONS
###

Usage() {
  echo "`basename $0`: Script for running task analysis"
  echo
  echo "Usage: (order matters)"
  echo "`basename $0` --subject=<subject id> \\"
  echo "  --runtype=<type of functional run (Localizer, Questions, or NoQuestions)> \\"
  echo "  --space=<space of the data (highres or standard)> \\"
  echo "  --fwhm=<fwhm in mm> \\"
  echo "  --nthreads=<number of OMP threads> \\"
  echo "  [--force=1 (overwrite any output if it exists)]"
  echo
  echo "Notes:"
  echo "- Everything must be in the same order as above"
  echo "- Must have the '=' between the option and argument (if any)"
  echo "- This assumes that each subject has data in /mnt/nfs/psych/faceMemoryMRI/analysis/subjects"
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

# see http://stackoverflow.com/questions/1527049/bash-join-elements-of-an-array
function join { local IFS="$1"; shift; echo "$*"; }

function get_brick_inds {
  local fname="$1"
  local label="$2"
  local otype="$3"
  
  # get the line numbers associated with the label
  # then need to subtract by 1 for afni indexing
  lines=( $( 3dAttribute BRICK_LABS ${fname} | tr '~' '\n' | sed -n "/${label}#.*_${otype}/=" ) )
  for (( i = 0; i < ${#lines[@]}; i++ )); do
    lines[i]=$(( ${lines[i]} - 1 ))
  done
  inds=$( join "," ${lines[@]} )
  
  echo $inds
}


###
# OPTION PARSING
###

# Just give usage if no arguments specified
if [ $# -eq 0 ] ; then Usage; exit 0; fi
# check for correct options
if [ $# -lt 5 ] ; then Usage; exit 1; fi

# parse arguments
subject=`getopt1 "--subject" $@`    # $1
runtype=`getopt1 "--runtype" $@`    # $2
space=`getopt1 "--space" $@`        # $3
fwhm=`getopt1 "--fwhm" $@`          # $4
nthreads=`getopt1 "--nthreads" $@`  # $5
force=`getopt1 "--force" $@`        # $6

# default parameters
force=`defaultopt $force 0`

# alias
subj="${subject}"


###
# Paths
###

studydir="/mnt/nfs/psych/faceMemoryMRI"
timeDir="${studydir}/scripts/timing"
subDir="${studydir}/analysis/subjects/${subject}"

lruntype=$( echo $runtype | tr '[:upper:]' '[:lower:]' )
runtypeDir="${subDir}/${runtype}"
outdir="${runtypeDir}/to_${space}/beta_series_${fwhm}mm_${basis}.reml"

mask="${runtypeDir}/to_${space}/mask_concat_min_4mm.nii.gz"

# Check inputs
if [[ ! -e "${runtypeDir}" ]]; then
  echo "ERROR: runtype directory doesn't exist '${runtypeDir}'"
  exit 4
fi
if [[ ! -e "${runtypeDir}/to_${space}/func_preproc_fwhm${fwhm}_run01.nii.gz" ]]; then
  echo "ERROR: input functional doesn't exist '${runtypeDir}/to_${space}/func_preproc_fwhm${fwhm}_run01.nii.gz'"
  exit 4
fi

# Check output
if [[ -e "${outdir}/end" ]]; then
  echo "ERROR: outputs already exist in '${outdir}' (remove '${outdir}/end' if you want to skip this message)"
  exit 6
fi

# Create outputs
mkdir -p ${outdir} 2> /dev/null

echo "cd ${outdir}"
cd ${outdir}


###
# LOGGING
###

# Record the input options in a log file
logfile=${outdir}/log.txt
echo "" > ${logfile}

echo
echo " START: BETA SERIES WORKER"

echo "$0 $@" 2>&1 | tee -a ${logfile}
echo "PWD = `pwd`" 2>&1 | tee -a ${logfile}
echo "date: `date`" 2>&1 | tee -a ${logfile}

echo " " 2>&1 | tee -a ${logfile}

echo " OPTIONS" 2>&1 | tee -a ${logfile}
echo " - subject: ${subject}" 2>&1 | tee -a ${logfile}
echo " - fwhm: ${fwhm}" 2>&1 | tee -a ${logfile}
echo " - nthreads: ${ntreads}" 2>&1 | tee -a ${logfile}
echo " - space: ${space}" 2>&1 | tee -a ${logfile}
echo " - runtype: ${Questions}" 2>&1 | tee -a ${logfile}
echo " - basis: ${basis}" 2>&1 | tee -a ${logfile}
echo " - model: ${model}" 2>&1 | tee -a ${logfile}


###
# DO WORK
###

echo "setting threads to ${nthreads}"
export OMP_NUM_THREADS=${nthreads}

if [ $force == 1 ]; then
    echo "setting afni to always overwrite"
    export AFNI_DECONFLICT='OVERWRITE'
fi

echo "deconvolve"
if [[ "$runtype" == "Localizer" ]]; then
  3dDeconvolve \
      -input ${runtypeDir}/to_${space}/func_preproc_fwhm5_concat_4mm.nii.gz \
      -force_TR 1 \
      -polort 0 \
      -num_stimts 2 \
      -stim_times_IM 1 ${timeDir}/global_allruns_FaceBody01_Face.txt ${model} \
      -stim_times_IM 2 ${timeDir}/global_allruns_FaceBody01_Body.txt ${model} \
      -stim_times_IM 3 ${timeDir}/global_allruns_FaceBody01_House.txt ${model} \
      -stim_label 1 face \
      -stim_label 2 body \
      -stim_label 3 house \
      -noFDR \
      -nobucket \
      -x1D ${outdir}/xmat.1D \
      -xjpeg ${outdir}/xmat.jpg \
      -x1D_stop
else
  3dDeconvolve \
      -input ${runtypeDir}/to_${space}/func_preproc_fwhm5_concat_4mm.nii.gz \
      -force_TR 1 \
      -polort 0 \
      -num_stimts 2 \
      -stim_times_IM 1 ${timeDir}/global_allruns_faceMemory01_${subj}_${runtype}_bio ${model} \
      -stim_times_IM 2 ${timeDir}/global_allruns_faceMemory01_${subj}_${runtype}_phys ${model} \
      -stim_label 1 bio \
      -stim_label 2 phys \
      -noFDR \
      -nobucket \
      -x1D ${outdir}/xmat.1D \
      -xjpeg ${outdir}/xmat.jpg \
      -x1D_stop
fi

echo "remlfit"
3dREMLfit -matrix ${outdir}/xmat.1D \
    -input ${runtypeDir}/to_${space}/func_preproc_fwhm5_concat_4mm.nii.gz \
    -mask ${mask} \
    -tout -noFDR \
    -Rbuck ${outdir}/stats_REML.nii.gz \
    -Rerrts ${outdir}/residuals_REML.nii.gz \
    -verb

echo
echo "split text bucket to output specific betas"
# start converting (save as floats)
if [[ "$runtype" == "Localizer" ]]; then
  labels="face body house"
else
  labels="bio phys"
fi

echo
echo "soft link the mask and standard"
ln -s ${mask} ${outdir}/mask.nii.gz
ln -s ${runtypeDir}/reg/${space}.nii.gz ${outdir}/${space}.nii.gz

echo
echo "creating underlays with 3dresample"
3dresample -inset ${runtypeDir}/to_${space}/mean_brain.nii.gz -master ${mask} -prefix ${outdir}/mean_brain.nii.gz
3dresample -inset ${outdir}/${space}.nii.gz -master ${mask} -prefix ${outdir}/underlay.nii.gz

echo
echo "split bucket to output specific betas"
# get degrees of freedom
stats=( $( 3dAttribute BRICK_STATAUX ${outdir}/stats_REML.nii.gz ) )
df=${stats[4]}
echo "- degrees of freedom = ${df}"
echo "$df" > ${outdir}/degrees_of_freedom.txt
# start converting (save as floats)
if [[ "$runtype" == "Localizer" ]]; then
  labels="face body house"
else
  labels="bio phys"
fi
for label in ${labels}; do
    echo "- saving ${label}"
    afni_buc2time.R -i ${outdir}/stats_REML.nii.gz -s "${label}#[0-9]+_Coef" -o ${outdir}/beta_series_${label}.nii.gz
    #afni_buc2time.R -i stats_REML.nii.gz -s "${label}#[0-9]+_Tstat" -o tstat_series_${label}.nii.gz    
    #3dcalc -a stats_REML.nii.gz"[${tinds}]" -expr "fitt_t2z(a,${df})" -float -prefix zstat_series_${label}.nii.gz
done


###
# Clean Up / END
###

touch ${outdir}/end

echo
echo " END: BETA SERIES WORKER"
echo " END: `date`" 2>&1 | tee -a ${logfile}
