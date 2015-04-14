#!/usr/bin/env bash

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
outdir="${runtypeDir}/to_${space}/task_${fwhm}mm_${basis}.reml"

mask="${runtypeDir}/to_${space}/mask.nii.gz"

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
echo " START: TASK WORKER"

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

# TODO: should we include censoring from that censor file?
echo
echo "Running 3dDeconvolve"
if [[ "$runtype" == "Localizer" ]]; then
  3dDeconvolve \
      -input ${runtypeDir}/to_${space}/func_preproc_fwhm${fwhm}_run*.nii.gz \
      -mask ${mask} \
      -force_TR 1 \
      -polort 2 \
      -num_stimts 9 \
      -stim_file 1 ${runtypeDir}/mc/func_motion_demean.1D'[0]' -stim_base 1 -stim_label 1 roll  \
      -stim_file 2 ${runtypeDir}/mc/func_motion_demean.1D'[1]' -stim_base 2 -stim_label 2 pitch \
      -stim_file 3 ${runtypeDir}/mc/func_motion_demean.1D'[2]' -stim_base 3 -stim_label 3 yaw   \
      -stim_file 4 ${runtypeDir}/mc/func_motion_demean.1D'[3]' -stim_base 4 -stim_label 4 dS    \
      -stim_file 5 ${runtypeDir}/mc/func_motion_demean.1D'[4]' -stim_base 5 -stim_label 5 dL    \
      -stim_file 6 ${runtypeDir}/mc/func_motion_demean.1D'[5]' -stim_base 6 -stim_label 6 dP    \
      -stim_times 7 ${timeDir}/allruns_FaceBody01_Face.txt ${model} \
      -stim_times 8 ${timeDir}/allruns_FaceBody01_Body.txt ${model} \
      -stim_times 9 ${timeDir}/allruns_FaceBody01_House.txt ${model} \
      -stim_label 7 face \
      -stim_label 8 body \
      -stim_label 9 house \
      -num_glt 3 \
      -glt_label 1 face_gt_body \
      -gltsym 'SYM: +face -body' \
      -glt_label 2 face_gt_house \
      -gltsym 'SYM: +face -house' \
      -glt_label 3 face+body_gt_house \
      -gltsym 'SYM: +0.5*face +0.5*body -house' \
      -noFDR \
      -nobucket \
      -x1D ${outdir}/xmat.1D \
      -xjpeg ${outdir}/xmat.jpg \
      -x1D_stop
else
  3dDeconvolve \
      -input ${runtypeDir}/to_${space}/func_preproc_fwhm${fwhm}_run*.nii.gz \
      -mask ${mask} \
      -force_TR 1 \
      -polort 2 \
      -num_stimts 8 \
      -stim_file 1 ${runtypeDir}/mc/func_motion_demean.1D'[0]' -stim_base 1 -stim_label 1 roll  \
      -stim_file 2 ${runtypeDir}/mc/func_motion_demean.1D'[1]' -stim_base 2 -stim_label 2 pitch \
      -stim_file 3 ${runtypeDir}/mc/func_motion_demean.1D'[2]' -stim_base 3 -stim_label 3 yaw   \
      -stim_file 4 ${runtypeDir}/mc/func_motion_demean.1D'[3]' -stim_base 4 -stim_label 4 dS    \
      -stim_file 5 ${runtypeDir}/mc/func_motion_demean.1D'[4]' -stim_base 5 -stim_label 5 dL    \
      -stim_file 6 ${runtypeDir}/mc/func_motion_demean.1D'[5]' -stim_base 6 -stim_label 6 dP    \
      -stim_times 7 ${timeDir}/allruns_faceMemory01_${subj}_${runtype}_bio ${model} \
      -stim_times 8 ${timeDir}/allruns_faceMemory01_${subj}_${runtype}_phys ${model} \
      -stim_label 7 bio \
      -stim_label 8 phys \
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
    #-x1D_uncensored X.nocensor.xmat.1D
# TODO: check status of the script
# TODO: might not need the fitt or residuals

echo
echo "Running 3dREMLfit"
dset=$(ls ${runtypeDir}/to_${space}/func_preproc_fwhm${fwhm}_run*.nii.gz | tr '\n' ' ')
3dREMLfit -matrix ${outdir}/xmat.1D \
    -input "$dset" \
    -mask ${mask} \
    -tout -noFDR \
    -Rbuck ${outdir}/stats_REML.nii.gz \
    -Rvar ${outdir}/stats_REMLvar.nii.gz \
    -Rfitts ${outdir}/fitts_REML.nii.gz \
    -Rerrts ${outdir}/residuals_REML.nii.gz \
    -Rwherr ${outdir}/whitened_residuals_REML.nii.gz \
    -verb

echo
echo "soft link the brains and mask"
ln -s ${runtypeDir}/to_${space}/mean_brain.nii.gz ${outdir}/mean_brain.nii.gz
ln -s ${runtypeDir}/to_${space}/mask.nii.gz ${outdir}/mask.nii.gz
ln -s ${runtypeDir}/reg/${space}.nii.gz ${outdir}/${space}.nii.gz

echo
echo "creating an underlay"
3dresample -inset ${outdir}/${space}.nii.gz -master ${outdir}/mean_brain.nii.gz -prefix ${outdir}/underlay.nii.gz

echo
echo "split bucket to output individual stat images"
mkdir ${outdir}/stats
# get degrees of freedom
stats=( $( 3dAttribute BRICK_STATAUX stats_REML.nii.gz ) )
df=${stats[4]}
echo "- degrees of freedom = ${df}"
# start converting (save as floats)
if [[ "$runtype" == "Localizer" ]]; then
  labels="face body house face_gt_body face_gt_house face+body_gt_house"
else
  labels="bio phys bio_gt_phys phys_gt_bio"
fi
for label in ${labels}; do
    echo "- saving ${label}"
    3dcalc -a stats_REML.nii.gz"[${label}#0_Coef]" -expr "a" -float -prefix stats/coef_${label}.nii.gz
    3dcalc -a stats_REML.nii.gz"[${label}#0_Tstat]" -expr "a" -float -prefix stats/tstat_${label}.nii.gz
    3dcalc -a stats_REML.nii.gz"[${label}#0_Tstat]" -expr "fitt_t2z(a,${df})" -float -prefix stats/zstat_${label}.nii.gz
done

echo
echo "concatenate inputs"
# create an all_runs dataset to match the fitts, errts, etc.
# we will only need this for the TSNR and for the blurring
# this will be deleted afterwards
3dTcat -tr 1 -prefix ${outdir}/tmp_all_runs.nii.gz ${runtypeDir}/to_${space}/func_preproc_fwhm${fwhm}_run*.nii.gz

echo
echo "compute TSNR"
# create a temporal signal to noise ratio dataset 
#    signal: if 'scale' block, mean should be 100
#    noise : compute standard deviation of errts
3dTstat -mean -prefix mean_signal.nii.gz tmp_all_runs.nii.gz
3dTstat -stdev -prefix mean_noise.nii.gz residuals_REML.nii.gz
3dcalc -a mean_signal.nii.gz            \
       -b mean_noise.nii.gz             \
       -c ${mask}                       \
       -expr 'c*a/b' -prefix tsnr.nii.gz

echo
echo "compute global correlation average"
# compute and store GCOR (global correlation average)
# - compute as sum of squares of global mean of unit errts
3dTnorm -prefix residuals_REML_unit.nii.gz residuals_REML.nii.gz
3dmaskave -quiet -mask ${mask} residuals_REML_unit.nii.gz > gmean_residuals_unit.1D
3dTstat -sos -prefix - gmean_residuals_unit.1D\' > gcor.1D
echo "-- GCOR = `cat gcor.1D`"

echo
echo "save some regressors"
# create ideal files for fixed response stim types
if [[ "$runtype" == "Localizer" ]]; then
  1dcat xmat.1D'[12]' > ideal_face.1D 
  1dcat xmat.1D'[13]' > ideal_body.1D
  1dcat xmat.1D'[14]' > ideal_house.1D
else
  1dcat xmat.1D'[12]' > ideal_bio.1D 
  1dcat xmat.1D'[13]' > ideal_phys.1D
fi

# compute sum of non-baseline regressors from the X-matrix
# (use 1d_tool.py to get list of regressor colums)
set reg_cols = `1d_tool.py -infile xmat.1D -show_indices_interest`
3dTstat -sum -prefix sum_ideal.1D xmat.1D"[$reg_cols]"

# also, create a stimulus-only X-matrix, for easy review
1dcat xmat.1D"[$reg_cols]" > xmat.1D


###
# Blur Estimation
###

echo
echo "blur estimation"

# get all the files
files=( $( ls ${runtypeDir}/to_${space}/func_preproc_fwhm${fwhm}_run*.nii.gz | tr '\n' ' ' ) )
nfiles=${#files[@]}

# get counts of the tr
tr_counts=( )
for (( i = 0; i < ${nfiles}; i++ )); do
    tr_counts[i]=$( fslnvols ${files[i]} )
done

# compute blur estimates
touch blur_est.1D   # start with empty file


# -- estimate blur for each run in epits --
echo "estimate blur for each run in input data"
touch blur_epits.1D

b0=0     # first index for current run
b1=-1    # will be last index for current run
for reps in ${tr_counts[@]}; do
    b1=$(( $b1 + $reps ))   # last index for current run
    3dFWHMx -detrend -mask ${mask} \
        ${outdir}/tmp_all_runs.nii.gz"[$b0..$b1]" >> blur_epits.1D
    b0=$(( $b0 + $reps ))   # first index for next run
done

# compute average blur and append
blurs=( `3dTstat -mean -prefix - blur_epits.1D\'` )
echo "average epits blurs: ${blurs[@]}"
echo "${blurs[@]}   # epits blur estimates" >> blur_est.1D


# -- estimate blur for each run in errts --
echo "estimate blur for each run in residuals following REML fit"
touch blur_errts.1D

b0=0     # first index for current run
b1=-1    # will be last index for current run
for reps in ${tr_counts[@]}; do
    b1=$(( $b1 + $reps ))   # last index for current run
    3dFWHMx -detrend -mask ${mask} \
        residuals_REML.nii.gz"[$b0..$b1]" >> blur_errts.1D
    b0=$(( $b0 + $reps ))   # first index for next run
done

# compute average blur and append
blurs=( `3dTstat -mean -prefix - blur_errts.1D\'` )
echo "average errts blurs: ${blurs[@]}"
echo "${blurs[@]}   # errts blur estimates" >> blur_est.1D

# add 3dClustSim results as attributes to the stats dset
echo "run cluster threshold simulations"
fxyz=( `tail -1 blur_est.1D` )
3dClustSim -both -NN 123 -mask ${mask} \
           -fwhmxyz ${fxyz[@]:0:3} -prefix ClustSim
3drefit -atrstring AFNI_CLUSTSIM_MASK file:ClustSim.mask                \
        -atrstring AFNI_CLUSTSIM_NN1  file:ClustSim.NN1.niml            \
        -atrstring AFNI_CLUSTSIM_NN2  file:ClustSim.NN2.niml            \
        -atrstring AFNI_CLUSTSIM_NN3  file:ClustSim.NN3.niml            \
        ${outdir}/stats_REML.nii.gz


###
# EasyThresh
###

echo
echo "EasyThreash"

echo "estimate image smoothness"
# get degrees of freedom
stats=( $( 3dAttribute BRICK_STATAUX stats_REML.nii.gz ) )
df=${stats[4]}
echo "- degrees of freedom = ${df}"
# estimate image smoothness
SM=`smoothest -d ${df} -m ${mask} -r residuals_REML.nii.gz`
DLH=`echo $SM | awk '{print $2}'`
VOLUME=`echo $SM | awk '{print $4}'`
RESELS=`echo $SM | awk '{print $6}'`
echo "- DLH: $DLH; VOLUME: $VOLUME; RESELS: $RESELS"
echo "DLH: $DLH" > smoothest_errts_fsl.1D
echo "VOLUME: $VOLUME" >> smoothest_errts_fsl.1D
echo "RESELS: $RESELS" >> smoothest_errts_fsl.1D

echo
echo "threshold zstat images"
#mkdir ${outdir}/corrected_stats
mkdir ${outdir}/rendered_stats
# thresholds see top of program
# start converting (save as floats)
if [[ "$runtype" == "Localizer" ]]; then
  labels="face body house face_gt_body face_gt_house face+body_gt_house"
else
  labels="bio phys bio_gt_phys phys_gt_bio"
fi
for label in ${labels}; do
    echo "- ${label} cluster correction"
    ${FSLDIR}/bin/cluster -i stats/zstat_${label}.nii.gz -t ${vthr} -p ${cthr} --volume=$VOLUME -d $DLH -o stats/cluster_mask_${label}.nii.gz --othresh=stats/thresh_zstat_${label}.nii.gz > stats/cluster_${label}.txt # --mm
    echo "- ${label} visualization"
    MAX=`${FSLDIR}/bin/fslstats stats/thresh_zstat_${label}.nii.gz -R | awk '{print $2}'`
    ${FSLDIR}/bin/overlay 1 0 underlay.nii.gz -a stats/thresh_zstat_${label}.nii.gz ${vthr} ${MAX} rendered_stats/thresh_zstat_${label}.nii.gz
    ${FSLDIR}/bin/slicer rendered_stats/thresh_zstat_${label}.nii.gz -S 2 750 rendered_stats/thresh_zstat_${label}.png
done

## get critical cluster size
#minclsize=`tail -1 clustsim.log | cut -c10-`
#
## generated a clustered dataset
#3dmerge -dxyz=1 -1clust 1 $minclsize -1thresh $zthr -1tindex 0 -prefix full_f_as_z_clusters${E} full_f_as_z${E}
#
## generate a cluster table
#3dclust -1clip 1 0 0 full_f_as_z_clusters${E} > full_f_as_z_clustertable.txt


###
# Clean Up / END
###

touch ${outdir}/end

echo
echo "Clean  Up"
rm ${outdir}/tmp_all_runs.nii.gz

echo
echo " END: TASK WORKER"
echo " END: `date`" 2>&1 | tee -a ${logfile}
