#!/usr/bin/env bash

export OMP_NUM_THREADS=2

# Hardcode these variables (TODO: add as user args)
basis="spmg1"
model="SPMG1(4)"
vthr=1.96 # voxel-level threshold in Zstats
cthr=0.05 # cluster-level threshold in pvals


###
# SUPPORT FUNCIONS
###

Usage() {
  echo "`basename $0`: Script for running task analysis"
  echo
  echo "Usage: (order matters)"
  echo "`basename $0` --subject=<subject id> \\"
  echo "  --runtype=<type of functional run (Questions, or NoQuestions)> \\"
  echo "  --region=<name of ROI> \\"
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
  # output is for awk
  lines=( $( 3dAttribute BRICK_LABS ${fname} | tr '~' '\n' | sed -n "/${label}#.*_${otype}/=" ) )
  inds=$( join "," ${lines[@]} )
  inds=$( echo ${inds} | sed s/,/,\$/g )
  inds="\$${inds}"
  
  echo $inds
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
outdir="${runtypeDir}/task/${region}.reml"

# Check inputs
if [[ ! -e "${runtypeDir}" ]]; then
  echo "ERROR: runtype directory doesn't exist '${runtypeDir}'"
  exit 4
fi
if [[ ! -e "${runtypeDir}/dr/${region}_stage1.1D" ]]; then
  echo "ERROR: input functional doesn't exist '${runtypeDir}/dr/${region}_stage1.1D'"
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
echo " START: TASK WORKER"

echo "$0 $@" 2>&1 | tee -a ${logfile}
echo "PWD = `pwd`" 2>&1 | tee -a ${logfile}
echo "date: `date`" 2>&1 | tee -a ${logfile}

echo " " 2>&1 | tee -a ${logfile}

echo " OPTIONS" 2>&1 | tee -a ${logfile}
echo " - subject: ${subject}" 2>&1 | tee -a ${logfile}
echo " - nthreads: ${ntreads}" 2>&1 | tee -a ${logfile}
echo " - runtype: ${Questions}" 2>&1 | tee -a ${logfile}
echo " - basis: ${basis}" 2>&1 | tee -a ${logfile}
echo " - model: ${model}" 2>&1 | tee -a ${logfile}
echo " - voxel thresh: ${vthr}" 2>&1 | tee -a ${logfile}
echo " - cluster thresh: ${cthr}" 2>&1 | tee -a ${logfile}


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
      -input ${runtypeDir}/dr/${region}_stage1.1D\' \
      -force_TR 1 \
      -polort 0 \
      -num_stimts 3 \
      -stim_times 1 ${timeDir}/global_allruns_FaceBody01_${subj}_${runtype}_face ${model} \
      -stim_times 2 ${timeDir}/global_allruns_FaceBody01_${subj}_${runtype}_body ${model} \
      -stim_times 3 ${timeDir}/global_allruns_FaceBody01_${subj}_${runtype}_house ${model} \
      -stim_label 1 face \
      -stim_label 2 body \
      -stim_label 3 house \
      -num_glt 4 \
      -glt_label 1 face_gt_body \
      -gltsym 'SYM: +face -body' \
      -glt_label 2 face_gt_house \
      -gltsym 'SYM: +face -house' \
      -glt_label 3 face+body_gt_house \
      -gltsym 'SYM: +0.5*face +0.5*body -house' \
      -glt_label 4 face+body+house \
      -gltsym 'SYM: +0.3333*face +0.3333*body +0.3333*house' \
      -noFDR \
      -nobucket \
      -x1D ${outdir}/xmat.1D \
      -xjpeg ${outdir}/xmat.jpg \
      -x1D_stop
else
  3dDeconvolve \
      -input ${runtypeDir}/dr/${region}_stage1.1D\' \
      -force_TR 1 \
      -polort 0 \
      -num_stimts 2 \
      -stim_times 1 ${timeDir}/global_allruns_faceMemory01_${subj}_${runtype}_bio ${model} \
      -stim_times 2 ${timeDir}/global_allruns_faceMemory01_${subj}_${runtype}_phys ${model} \
      -stim_label 1 bio \
      -stim_label 2 phys \
      -num_glt 2 \
      -glt_label 1 bio_gt_phys \
      -gltsym 'SYM: +bio -phys' \
      -glt_label 2 phys_gt_bio \
      -gltsym 'SYM: -bio +phys' \
      -noFDR \
      -nobucket \
      -x1D ${outdir}/xmat.1D \
      -xjpeg ${outdir}/xmat.jpg \
      -x1D_stop
fi

echo "remlfit"
3dREMLfit -matrix ${outdir}/xmat.1D \
    -input ${runtypeDir}/dr/${region}_stage1.1D\' \
    -tout -noFDR \
    -Rbuck ${outdir}/stats_REML.1D \
    -Rvar ${outdir}/stats_REMLvar.1D \
    -Rfitts ${outdir}/fitts_REML.1D \
    -Rerrts ${outdir}/residuals_REML.1D \
    -Rwherr ${outdir}/whitened_residuals_REML.1D \
    -verb

# labels associated with the output bucket
if [[ "$runtype" == "Localizer" ]]; then
	echo "save"
	echo "index,name,type" > ${outdir}/stats_REML_labels.csv
	echo "1,Fstat," >> ${outdir}/stats_REML_labels.csv
	echo "2,face,Coef" >> ${outdir}/stats_REML_labels.csv
	echo "3,face,Tstat" >> ${outdir}/stats_REML_labels.csv
	echo "4,body,Coef" >> ${outdir}/stats_REML_labels.csv
	echo "5,body,Tstat" >> ${outdir}/stats_REML_labels.csv
	echo "6,house,Coef" >> ${outdir}/stats_REML_labels.csv
	echo "7,house,Tstat" >> ${outdir}/stats_REML_labels.csv
	echo "8,face_gt_body,Coef" >> ${outdir}/stats_REML_labels.csv
	echo "9,face_gt_body,Tstat" >> ${outdir}/stats_REML_labels.csv
	echo "10,face_gt_house,Coef" >> ${outdir}/stats_REML_labels.csv
	echo "11,face_gt_house,Tstat" >> ${outdir}/stats_REML_labels.csv
	echo "12,face+body_gt_house,Coef" >> ${outdir}/stats_REML_labels.csv
	echo "13,face+body_gt_house,Tstat" >> ${outdir}/stats_REML_labels.csv
	echo "14,face+body+house,Coef" >> ${outdir}/stats_REML_labels.csv
	echo "15,face+body+house,Tstat" >> ${outdir}/stats_REML_labels.csv
else
	echo "save"
	echo "index,name,type" > ${outdir}/stats_REML_labels.csv
	echo "1,Fstat," >> ${outdir}/stats_REML_labels.csv
	echo "2,bio,Coef" >> ${outdir}/stats_REML_labels.csv
	echo "3,bio,Tstat" >> ${outdir}/stats_REML_labels.csv
	echo "4,phys,Coef" >> ${outdir}/stats_REML_labels.csv
	echo "5,phys,Tstat" >> ${outdir}/stats_REML_labels.csv
	echo "6,bio-gt-phys,Coef" >> ${outdir}/stats_REML_labels.csv
	echo "7,bio-gt-phys,Tstat" >> ${outdir}/stats_REML_labels.csv
	echo "8,phys-gt-bio,Coef" >> ${outdir}/stats_REML_labels.csv
	echo "9,phys-gt-bio,Tstat" >> ${outdir}/stats_REML_labels.csv
fi

###
# Clean Up / END
###

#touch ${outdir}/end_${preall}${hemi}_${region}

echo
echo " END: TASK WORKER"
echo " END: `date`" 2>&1 | tee -a ${logfile}
