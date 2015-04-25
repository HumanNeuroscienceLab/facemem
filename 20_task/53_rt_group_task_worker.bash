#!/usr/bin/env bash

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
model=`getopt1 "--model" $@`
njobs=`getopt1 "--njobs" $@`

# other args
space=standard

# read in subjects
subjects=( $( cat ${subfile} ) )

# scriptdir
scriptdir=$(pwd)


###
# LOGGING
###

# Record the input options in a log file
mkdir logs 2> /dev/null
logfile=$(pwd)/logs/group_familiar_${runtype}_${space}_${model}_`date +%Y-%m-%d_%H-%M`.txt
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
echo " - space: ${space}" 2>&1 | tee -a ${logfile}
echo " - model: ${model}" 2>&1 | tee -a ${logfile}
echo " - njobs: ${njobs}" 2>&1 | tee -a ${logfile}

export OMP_NUM_THREADS=${njobs}


###
# Execute
###

basedir="/mnt/nfs/psych/faceMemoryMRI"
grpdir="${basedir}/analysis/groups"
subdir="${basedir}/analysis/subjects"

lruntype=$( echo $runtype | tr '[:upper:]' '[:lower:]' )
outdir="${grpdir}/${runtype}/task/rt_${model}.mema"

# suffix for subject input directory
suffix="${runtype}/task/rt_${model}.reml"

if [[ -e "${outdir}" ]]; then
  echo "ERROR: output directory '${outdir}' already exists"
  echo "consider:"
  echo "rm -r ${outdir}"
  exit 2
fi

echo
echo "creating output directory"
mkdir -p ${outdir} 2> /dev/null
echo "cd ${outdir}"
cd ${outdir}

mkdir subjects 2> /dev/null

echo
echo "copying or linking input subject data"
for subject in ${subjects[@]}; do
  rdir="${subdir}/${subject}/${suffix}/reg_standard"
  run "ln -sf ${rdir}/stats subjects/${subject}_stats"
  run "ln -sf ${rdir}/mask.nii.gz subjects/${subject}_mask.nii.gz"
  run "tail -1 ${subdir}/${subject}/${suffix}/blur_est.1D > subjects/${subject}_blur_errts.1D"
done

echo
echo "creating group mask"
run "3dMean -mask_inter -prefix mask.nii.gz subjects/*_mask.nii.gz"

echo
echo "gathering contrasts to run"
contrasts=( $( cd subjects/${subjects[0]}_stats; ls coef_*.nii.gz | sed s/coef_//g | sed s/.nii.gz//g ) )
echo "=> ${contrasts[@]}"

echo
echo "looping through contrasts to run 3dMEMA"
# note: use cio option so I can use nifti files
for cname in ${contrasts[@]}; do
  echo
  echo "========"
  echo "${cname}"
  
  cmd="3dMEMA \
          -mask mask.nii.gz
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
    cmd+=" ${subject} subjects/${subject}_stats/coef_${cname}.nii.gz subjects/${subject}_stats/tstat_${cname}.nii.gz"
  done
  run $cmd
  
  echo "refit"
  run "3drefit -view tlrc -space MNI ${cname}_ICC+orig"
  run "3drefit -view tlrc -space MNI ${cname}_resZ+orig"
  run "3drefit -view tlrc -space MNI ${cname}+orig"
  
  echo "to nifti"
  run "3dAFNItoNIFTI -overwrite -prefix ${cname}_ICC.nii.gz ${cname}_ICC+tlrc"
  run "3dAFNItoNIFTI -overwrite -prefix ${cname}_resZ.nii.gz ${cname}_resZ+tlrc"
  run "3dAFNItoNIFTI -overwrite -prefix ${cname}.nii.gz ${cname}+tlrc"
  
  echo "extract tstats"
  run "3dcalc -a ${cname}.nii.gz'[1]' -expr a -prefix tstats_${cname}.nii.gz"
  
  echo "tstat => zstat"
  run "3dcalc -a tstats_${cname}.nii.gz -expr 'fitt_t2z(a,${#subjects[@]})' -prefix zstats_${cname}.nii.gz"
  
  echo "mask"
  run "3dcalc -a tstats_${cname}.nii.gz -expr 'step(abs(a))' -prefix ${cname}_mask.nii.gz"
  
  echo "========"
  echo
done

echo
echo "standard underlays"
reses="0.5 1 2"
for res in ${reses}; do
  run "ln -sf ${FSLDIR}/data/standard/MNI152_T1_${res}mm.nii.gz standard_${res}mm.nii.gz"
  run "ln -sf ${FSLDIR}/data/standard/MNI152_T1_${res}mm_brain.nii.gz standard_brain_${res}mm.nii.gz"
done
run "rm standard_brain_0.5mm.nii.gz"

echo
echo "run cluster threshold simulations"
# gather all the blurs
run "cat subjects/*_blur_errts.1D > tmp_blur_errts.1D"
# compute average blur and append
blurs=( `3dTstat -mean -prefix - tmp_blur_errts.1D\'` )
echo "average errts blurs: ${blurs[@]}"
echo "${blurs[@]}" > blur_est.1D
# clustsim
fxyz=( `tail -1 blur_est.1D` )
run "3dClustSim -both -NN 123 -mask mask.nii.gz \
           -fwhmxyz ${fxyz[@]:0:3} -prefix ClustSim"
echo "apply cluster results to each output file"
for cname in ${contrasts[@]}; do
  run "3drefit -atrstring AFNI_CLUSTSIM_MASK file:ClustSim.mask                \
          -atrstring AFNI_CLUSTSIM_NN1  file:ClustSim.NN1.niml            \
          -atrstring AFNI_CLUSTSIM_NN2  file:ClustSim.NN2.niml            \
          -atrstring AFNI_CLUSTSIM_NN3  file:ClustSim.NN3.niml            \
          ${outdir}/${cname}+tlrc"
done

echo
echo "do the same but on nifti (+ have a liberal threshold)"
for cname in ${contrasts[@]}; do
  echo "contrast: ${cname}"
  run "rm -f thresh_zstats_${cname}.nii.gz thresh_liberal_zstats_${cname}.nii.gz"
  run "${scriptdir}/./apply_clustsim.R ClustSim.NN3 0.05 0.05 zstats_${cname}.nii.gz thresh_zstats_${cname}.nii.gz"
  run "${scriptdir}/./apply_clustsim.R ClustSim.NN3 0.1 0.1 zstats_${cname}.nii.gz thresh_liberal_zstats_${cname}.nii.gz"
  echo
done

run "mkdir easythresh 2> /dev/null"
run "cd easythresh"
for cname in ${contrasts[@]}; do
  echo "contrast: ${cname}"
  ## positive
  run "easythresh ../zstats_${cname}.nii.gz ../mask.nii.gz 1.96 0.05 ../standard_2mm.nii.gz zstat_${cname}"
  run "easythresh ../zstats_${cname}.nii.gz ../mask.nii.gz 1.645 0.1 ../standard_2mm.nii.gz liberal_zstat_${cname}"
  ## negative
  run "fslmaths ../zstats_${cname}.nii.gz -mul -1 ztmp_flip_zstats_${cname}.nii.gz"
  run "easythresh ztmp_flip_zstats_${cname}.nii.gz ../mask.nii.gz 1.96 0.05 ../standard_2mm.nii.gz flipped_zstat_${cname}"
  run "easythresh ztmp_flip_zstats_${cname}.nii.gz ../mask.nii.gz 1.645 0.1 ../standard_2mm.nii.gz flipped_liberal_zstat_${cname}"
  ## combine
  run "3dcalc -overwrite -a thresh_zstat_${cname}.nii.gz -b thresh_flipped_zstat_${cname}.nii.gz -expr 'a-b' -prefix combined_thresh_zstat_${cname}.nii.gz"  
  run "3dcalc -overwrite -a thresh_liberal_zstat_${cname}.nii.gz -b thresh_flipped_zstat_${cname}.nii.gz -expr 'a-b' -prefix combined_thresh_liberal_zstat_${cname}.nii.gz"
  ## clean
  run "rm -f *flipped*"
  run "rm -f ztmp_flip_zstats_${cname}.nii.gz"
  echo
done
run "cd -"

echo
echo "now do FDR"
for cname in ${contrasts[@]}; do
  run "fslmaths zstats_${cname}.nii.gz -abs -ztop pvals_${cname}.nii.gz"
  run "fdr -i pvals_${cname}.nii.gz -m ${cname}_mask.nii.gz -q 0.05 --othresh=fdr_mask_${cname}.nii.gz"
  run "3dcalc -overwrite -a zstats_${cname}.nii.gz -b fdr_mask_${cname}.nii.gz -expr 'a*step(1-b)' -prefix fdr_zstats_${cname}.nii.gz"
  run "rm fdr_mask_${cname}.nii.gz pvals_${cname}.nii.gz"
done

echo "SUMA"
ln -s /mnt/nfs/share/freesurfer/current/mni152/SUMA 


###
# END
###

echo
echo " END: PREPROCESSING"
echo " END: `date`" 2>&1 | tee -a ${logfile}
