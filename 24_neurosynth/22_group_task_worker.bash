#!/usr/bin/env bash

###
# SUPPORT FUNCIONS
###

Usage() {
  echo "`basename $0`: Script for running preprocessing"
  echo
  echo "Usage: (order matters)"
  echo "`basename $0` --subfile=<file with list of subject ids to use> \\"
  echo "  --runtype=<type of functional run (Questions, or NoQuestions)>"
  echo "  --region=<name of ROI> \\"
  echo "  --njobs=<number of jobs to run in parallel>"
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
if [ $# -lt 4 ] ; then Usage; exit 1; fi

# parse arguments
subfile=`getopt1 "--subfile" $@`
runtype=`getopt1 "--runtype" $@`
region=`getopt1 "--region" $@`      # $4
njobs=`getopt1 "--njobs" $@`

# read in subjects
subjects=( $( cat ${subfile} ) )

# hard-wired
vthr=1.96
cthr=0.05


###
# LOGGING
###

# Record the input options in a log file
mkdir logs 2> /dev/null
logfile=$(pwd)/logs/group_${runtype}_${region}_`date +%Y-%m-%d_%H-%M`.txt
echo "" > $logfile

echo
echo " START: ANALYSIS"

echo "$0 $@" 2>&1 | tee -a ${logfile}
echo "PWD = `pwd`" 2>&1 | tee -a ${logfile}
echo "date: `date`" 2>&1 | tee -a ${logfile}

echo " " 2>&1 | tee -a ${logfile}

echo " OPTIONS" 2>&1 | tee -a ${logfile}
echo " - subjects: ${subjects[@]}" 2>&1 | tee -a ${logfile}
echo " - runtype: ${runtype}" 2>&1 | tee -a ${logfile}
echo " - region: ${region}" 2>&1 | tee -a ${logfile}
echo " - njobs: ${njobs}" 2>&1 | tee -a ${logfile}
echo " - vox thresh: ${vthr}" 2>&1 | tee -a ${logfile}
echo " - clust thresh: ${cthr}" 2>&1 | tee -a ${logfile}

export OMP_NUM_THREADS=${njobs}


###
# Execute
###

basedir="/mnt/nfs/psych/faceMemoryMRI"
grpdir="${basedir}/analysis/groups"
subdir="${basedir}/analysis/subjects"
#roidir="${grpdir}/Localizer/parcels_migp"

lruntype=$( echo $runtype | tr '[:upper:]' '[:lower:]' )
outdir="${grpdir}/${runtype}/dr/${region}.mema"

# suffix for subject input directories
suffix="${runtype}/task/${region}.reml"

if [[ -e "${outdir}" ]]; then
  echo "ERROR: output directory '${outdir}' already exists"
  echo "consider:"
  echo "rm -r ${outdir}"
  exit 2
fi

curdir=$(pwd)

echo
echo "creating output directory"
mkdir -p ${outdir} 2> /dev/null
echo "cd ${outdir}"
cd ${outdir}

mkdir subjects
mkdir voxs

echo
echo "copying or linking input subject data"
for subject in ${subjects[@]}; do
  run "ln -sf ${subdir}/${subject}/${suffix}/stats_REML.1D subjects/${subject}_bucket.1D"
  run "Rscript ${curdir}/text_to_nifti.R subjects/${subject}_bucket.1D subjects/${subject}_bucket.nii.gz"
done

echo
echo "gathering contrasts to run"
run "ln -sf ${subdir}/${subject}/${suffix}/stats_REML_labels.csv labels.csv"

contrasts=( $( cat labels.csv | tr ',' ' ' | grep Tstat | awk '{print $2}' ) )
inds=( $( cat labels.csv | tr ',' ' ' | grep Tstat | awk '{print $1}' ) )
echo "=> ${contrasts[@]}"

#echo
#echo "copying mask for voxelwise data"
#run "cp ${roidir}/group_mask.nii.gz mask.nii.gz"

#echo
#echo "standard underlays for voxelwise data"
#reses="0.5 1 2"
#for res in ${reses}; do
#  run "ln -sf ${FSLDIR}/data/standard/MNI152_T1_${res}mm.nii.gz standard_${res}mm.nii.gz"
#  run "ln -sf ${FSLDIR}/data/standard/MNI152_T1_${res}mm_brain.nii.gz standard_brain_${res}mm.nii.gz"
#done
#run "rm standard_brain_0.5mm.nii.gz"

echo
echo "looping through contrasts to run 3dMEMA"
# note: use cio option so I can use nifti files
for (( i = 0; i < ${#contrasts[@]}; i++ )); do
  cname=${contrasts[$i]}
  ind=$(( ${inds[$i]} - 1 ))
  
  echo
  echo "========"
  echo "${cname}"
  
  cmd="3dMEMA \
          -prefix ${cname} \
          -jobs ${njobs} \
          -missing_data 0 \
          -HKtest         \
          -model_outliers \
          -cio \
          -residual_Z \
          -verb 1 \
          -set  ${cname}"
  for subject in ${subjects[@]}; do
    cmd+=" ${subject} subjects/${subject}_bucket.nii.gz'[${ind}]' subjects/${subject}_bucket.nii.gz'[${ind}]'"
  done
  run $cmd

  echo "extracting tstats"
  dof=$(( $( ls -l subjects/*.1D | wc -l ) - 1 ))
  run "1deval -a '${cname}.1D[1]' -expr 'fitt_t2z(a,${dof})' > ${cname}_zstat.1D"
  
  #echo
  #echo "ROI to voxelwise"
  #run "Rscript ${curdir}/roi_to_voxelwise.R ${cname}_zstat.1D ${roidir}/rois/parcels.nii.gz voxs/zstat_${cname}.nii.gz"
  
  #echo
  #echo "easythresh"
  #run "cd voxs; easythresh zstat_${cname}.nii.gz ../mask.nii.gz ${vthr} ${cthr} ../standard_brain_2mm.nii.gz zstat_${cname}; cd -"

  echo "========"
  echo
done

echo
echo "output labels"
echo "beta tstat tau^2 QE:Chisq" > outlabels.txt

#echo
#echo "SUMA"
#ln -sf /mnt/nfs/share/freesurfer/current/mni152/SUMA .


###
# END
###

echo
echo " END: PREPROCESSING"
echo " END: `date`" 2>&1 | tee -a ${logfile}
