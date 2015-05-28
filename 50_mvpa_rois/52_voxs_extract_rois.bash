#!/usr/bin/env bash


###
# PATHS
###

subjects=$(cat ../sublist_all.txt)
runtypes="Questions NoQuestions"

basedir="/mnt/nfs/psych/faceMemoryMRI"
std_roifile="${basedir}/scripts/connpaper/rois/classify_probpeaks_small.nii.gz"
#roiname="classify_probpeaks"
roiname="classify_probpeaks_small"


###
# GENERAL FUNCTIONS
###

function run() {
  echo "$@"
  eval "$@"
  return $?
}

function die() {
  echo "$@"
  exit 2
}


###
# Transform ROIs to native space
###
echo "Transform ROIs to native space"

function transform_peaks_to_native() {
  run "cd $1"
  run "gen_applywarp.rb --overwrite -i ${std_roifile} -r reg -w 'standard-to-exfunc' -o rois/${roiname}.nii.gz --interp nn"
  run "3dcalc -overwrite -a rois/${roiname}.nii.gz -b mask.nii.gz -expr 'a*step(b)' -prefix rois/${roiname}.nii.gz"
  run "cd -"
}

#subject=tb9226
#runtype=Questions
for runtype in ${runtypes}; do
  echo
  echo "runtype: $runtype"
  for subject in ${subjects}; do
    echo "subject: ${subject}"
    transform_peaks_to_native "${basedir}/analysis/subjects/${subject}/${runtype}"
    echo
  done
done


###
# Extract TS
###
echo "Extract the TS"

#function extract_peaks_ts() {
#  run "cd $1"
#  run "ts_extract.R -r rois/${roiname}.nii.gz -i filtered_func_data.nii.gz -o ts/${roiname}.1D -z" # -z all multiple rois
#  run "cd -"
#}
#
##subject=tb9226
##runtype=Questions
#for runtype in ${runtypes}; do
#  echo
#  echo "runtype: $runtype"
#  for subject in ${subjects}; do
#    echo "subject: ${subject}"
#    extract_peaks_ts "${basedir}/analysis/subjects/${subject}/${runtype}"
#    echo
#  done
#done

# try the parallel approach
njobs=4
runtypes=( "Questions" "NoQuestions" )
subjs=( $(cat ../sublist_all.txt) )
conds=( "bio" "phys" )

sdir="${basedir}/analysis/subjects"
parallel --no-notice -j $njobs --eta \
  ts_extract.R -r ${sdir}/{1}/{2}/rois/${roiname}.nii.gz -i ${sdir}/{1}/{2}/task/beta_series_spmg1.reml/beta_series_{3}.nii.gz -o ${sdir}/{1}/{2}/ts/bs_${roiname}_{3}.1D -z -v ::: ${subjs[@]} ::: ${runtypes[@]} ::: ${conds[@]}
