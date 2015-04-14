#!/usr/bin/env bash

###
# SUPPORT FUNCIONS
###

Usage() {
  echo "`basename $0`: Script for running preprocessing"
  echo
  echo "Usage: (order matters)"
  echo "`basename $0` --subject=<subject to run> \\"
  echo "  --nthreads=<number of OMP threads>"
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


###
# OPTION PARSING
###

# Just give usage if no arguments specified
if [ $# -eq 0 ] ; then Usage; exit 0; fi
# check for correct options
if [ $# -lt 2 ] ; then Usage; exit 1; fi

# parse arguments
subject=`getopt1 "--subject" $@`    # $1
nthreads=`getopt1 "--nthreads" $@`  # $2


###
# LOGGING
###

# Record the input options in a log file
mkdir logs 2> /dev/null
logfile=logs/gunther_${subject}_`date +%Y-%m-%d_%H-%M`.txt
echo "" > $logfile

echo
echo " START: PREPROCESSING"

echo "$0 $@" 2>&1 | tee -a ${logfile}
echo "PWD = `pwd`" 2>&1 | tee -a ${logfile}
echo "date: `date`" 2>&1 | tee -a ${logfile}

echo " " 2>&1 | tee -a ${logfile}

echo " OPTIONS" 2>&1 | tee -a ${logfile}
echo " - subject: ${subject}" 2>&1 | tee -a ${logfile}
echo " - njobs: ${njobs}" 2>&1 | tee -a ${logfile}
echo " - nthreads: ${nthreads}" 2>&1 | tee -a ${logfile}


###
# Execute
###

export OMP_NUM_THREADS=${nthreads}

basedir="/mnt/nfs/psych/faceMemoryMRI"
datadir="${basedir}/data/nifti"
subdir="${basedir}/analysis/subjects"
freedir="${basedir}/analysis/freesurfer"
qadir="${basedir}/data/qa"

## Anatomical
#echo
#echo "anatomical"
#preproc_anat.rb --input ${datadir}/${subject}/${subject}_highres.nii.gz \
#  --subject ${subject} --sd ${subdir} --freedir ${freedir} \
#  --dxyz 2.5 --threads ${nthreads}

## Functionals
echo
echo "localizer"
preproc_func.rb -i ${datadir}/${subject}/${subject}_FaceMemory01_FaceLoc_run*.nii.gz \
  --subject ${subject} --sd ${subdir} --qadir ${qadir} \
  --name Localizer --tr 1 \
  --fwhm 5 \
  --hp 200 \
  --threads ${nthreads} --overwrite

echo
echo "questions"
preproc_func.rb -i ${datadir}/${subject}/${subject}_FaceMemory01_withQ_run*.nii.gz \
  --subject ${subject} --sd ${subdir} --qadir ${qadir} \
  --name Questions --tr 1 \
  --fwhm 5 \
  --hp 200 \
  --threads ${nthreads} --overwrite

echo
echo "no-questions"
preproc_func.rb -i ${datadir}/${subject}/${subject}_FaceMemory01_noQ_run*.nii.gz \
  --subject ${subject} --sd ${subdir} --qadir ${qadir} \
  --name NoQuestions --tr 1 \
  --fwhm 5 \
  --hp 200 \
  --threads ${nthreads} --overwrite

## FIX FUNCS TO HAVE 5mm smoothing
#echo
#echo "localizer"
#preproc_func.rb -i ${datadir}/${subject}/${subject}_FaceMemory01_FaceLoc_run*.nii.gz \
#  --subject ${subject} --sd ${subdir} --qadir ${qadir} \
#  --name Localizer --tr 1 \
#  --fwhm 5 \
#  --hp 200 \
#  --threads ${nthreads} --overwrite \
#  --do filter compcor concat
#
#echo
#echo "questions"
#preproc_func.rb -i ${datadir}/${subject}/${subject}_FaceMemory01_withQ_run*.nii.gz \
#  --subject ${subject} --sd ${subdir} --qadir ${qadir} \
#  --name Questions --tr 1 \
#  --fwhm 5 \
#  --hp 200 \
#  --threads ${nthreads} --overwrite \
#  --do filter compcor concat
#
#echo
#echo "no-questions"
#preproc_func.rb -i ${datadir}/${subject}/${subject}_FaceMemory01_noQ_run*.nii.gz \
#  --subject ${subject} --sd ${subdir} --qadir ${qadir} \
#  --name NoQuestions --tr 1 \
#  --fwhm 5 \
#  --hp 200 \
#  --threads ${nthreads} --overwrite \
#  --do filter compcor concat


###
# END
###

echo
echo " END: PREPROCESSING"
echo " END: `date`" 2>&1 | tee -a ${logfile}
