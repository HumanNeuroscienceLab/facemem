#!/usr/bin/env bash

# Hardcode these variables (TODO: add as user args)
export OMP_NUM_THREADS=2 # this is also a user variable
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
  echo "  --region=<name of ROI> \\"
  echo "  --nthreads=<number of OMP threads> \\"
  echo "  [--force=1 (overwrite any output if it exists)]"
  echo
  echo "Notes:"
  echo "- Everything must be in the same order as above"
  echo "- Must have the '=' between the option and argument (if any)"
  echo "- This assumes that each subject has data in /mnt/nfs/psych/faceMemoryMRI/analysis/subjects"
  echo
  echo "Outputs:"
  echo "- Will output the standard REMLfit stuff at text files"
  echo "- And will also spit out two different text files with the bio and phys betas in it"
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

# From an AFNI design matrix extracks the labels for each brick output
# ex: get_brick_labs xmat.1D
function get_brick_labs {
  local fname="$1" # xmat.1D
  
  # get relevant line in xmat.1D
  line=$( grep ColumnLabels ${fname} )
  # remove extraneous stuff
  line=$( echo ${line} | sed s/'.* = '// | sed s/\"//g )
  # split up the string of labels
  brick_labs=$( echo ${line} | sed s/' ; '/';'/g | tr ';' ' ' )
  
  echo ${brick_labs}
}

# Get the indices for a brick label
# ex: get_brick_inds bio $labs
function get_brick_inds {
  local label="$1"; shift
  local brick_labs="$@"
  
  # Get the indices
  brick_inds=$( echo ${brick_labs} | tr ' ' '\n' | grep -n ${label} | tr ':' ' ' | awk '{print $1}' )
  # Make the indices 0-based for afni
  brick_inds=$( echo ${brick_inds} | 1deval -a stdin: -expr 'a-1' )
  
  echo $brick_inds
}


###
# OPTION PARSING
###

# Just give usage if no arguments specified
if [ $# -eq 0 ] ; then Usage; exit 0; fi
# check for correct options
if [ $# -lt 4 ] ; then Usage; exit 1; fi

# parse arguments
subject=`getopt1 "--subject" $@`    # $1
runtype=`getopt1 "--runtype" $@`    # $2
region=`getopt1 "--region" $@`      # $4
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
outdir="${runtypeDir}/task/beta_series_${region}.reml"

# Check inputs
if [[ ! -e "${runtypeDir}" ]]; then
  echo "ERROR: runtype directory doesn't exist '${runtypeDir}'"
  exit 4
fi
if [[ ! -e "${runtypeDir}/ts/${region}.1D" ]]; then
  echo "ERROR: input functional doesn't exist '${runtypeDir}/ts/${region}.1D'"
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
3dDeconvolve \
    -input ${runtypeDir}/ts/${region}.1D\' \
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

echo "remlfit"
3dREMLfit -matrix ${outdir}/xmat.1D \
    -input ${runtypeDir}/ts/${region}.1D\' \
    -tout -noFDR \
    -Rbeta ${outdir}/beta_series_REML.1D \
    -Rbuck ${outdir}/stats_REML.1D \
    -Rvar ${outdir}/stats_REMLvar.1D \
    -Rfitts ${outdir}/fitts_REML.1D \
    -Rerrts ${outdir}/residuals_REML.1D \
    -Rwherr ${outdir}/whitened_residuals_REML.1D \
    -verb

echo
echo "split text bucket to output specific betas"
labels="bio phys"

collabs=$( get_brick_labs xmat.1D )
for label in ${labels}; do
    inds=$( get_brick_inds ${label} $collabs ) # note these are 0-based indices
    inds=$( echo $inds | tr ' ' ',' )
    
    echo "- saving ${label} (cols: ${inds})"
    1dtranspose ${outdir}/beta_series_REML.1D"[$inds]" > ${outdir}/beta_series_${label}.1D     
done

# labels associated with the output bucket
echo "save"
echo "index,name,type" > ${outdir}/stats_REML_labels.csv
echo "1,Fstat," >> ${outdir}/stats_REML_labels.csv
echo "2,bio,Coef" >> ${outdir}/stats_REML_labels.csv
echo "3,bio,Tstat" >> ${outdir}/stats_REML_labels.csv
echo "4,phys,Coef" >> ${outdir}/stats_REML_labels.csv
echo "5,phys,Tstat" >> ${outdir}/stats_REML_labels.csv


###
# Clean Up / END
###

#touch ${outdir}/end_${preall}${hemi}_${region}

echo
echo " END: BETA SERIES WORKER"
echo " END: `date`" 2>&1 | tee -a ${logfile}

touch ${outdir}/end
