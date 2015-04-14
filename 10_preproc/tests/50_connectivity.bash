#!/usr/bin/env bash

# Here we calculate the subject connectivity using the left FFA seed
# We want to see if we can get ATL - FAA connectivity for bio > phys


#--- SETUP ---#

function run() {
  echo "$@"
  eval "$@"
  return $?
}

subjects=$( cat ../sublist_all.txt )
runtypes="Questions"

roi="/data/psych/faceMemoryMRI/scripts/archive/rois/fhs_ffa_right.nii.gz"
base="/mnt/nfs/psych/faceMemoryMRI/analysis/subjects"
grpbase="/mnt/nfs/psych/faceMemoryMRI/analysis/groups"
conditions="bio phys"
covars="mc mc_compcor_top5 mc_compcor_sim"

njobs=12


#--- PREPARE ---#

## Make the sbca output folder
#for subj in ${subjects}; do
#  run "mkdir ${base}/${subj}/Questions/sbca 2> /dev/null"
#done


#--- RUN SUBJECTS ---#


#rm -r /mnt/nfs/psych/faceMemoryMRI/analysis/subjects/*/Questions/sbca/fhs_ffa_left*
#parallel --no-notice -j $njobs --eta \
#  sbca.rb -r ${roi} --func ${base}/{1}/Questions/preproc/split_ts/func_concat_{3}_{2}.nii.gz --mask ${base}/{1}/Questions/preproc/mask.nii.gz --regdir ${base}/{1}/Questions/reg --space standard exfunc standard --outdir ${base}/{1}/Questions/sbca/fhs_ffa_left_{3}_{2} --fwhm 2 --threads 2 ::: ${subjects} ::: ${conditions} ::: ${covars}

#rm -r /mnt/nfs/psych/faceMemoryMRI/analysis/subjects/*/Questions/sbca/fhs_ffa_right*
#parallel --no-notice -j $njobs --eta \
#  sbca.rb -r ${roi} --func ${base}/{1}/Questions/preproc/split_ts/func_concat_{3}_{2}.nii.gz --mask ${base}/{1}/Questions/preproc/mask.nii.gz --regdir ${base}/{1}/Questions/reg --space standard exfunc standard --outdir ${base}/{1}/Questions/sbca/fhs_ffa_right_{3}_{2} --fwhm 2 --threads 2 ::: ${subjects} ::: ${conditions} ::: ${covars}

# trying to do 3ddeconvolve
#rm -r /mnt/nfs/psych/faceMemoryMRI/analysis/subjects/*/Questions/sbca/glm_fhs_ffa_left*
#parallel --no-notice -j $njobs --eta \
#  sbca_glm.rb -r ${roi} --func ${base}/{1}/Questions/preproc/split_ts/func_concat_{3}_{2}.nii.gz --mask ${base}/{1}/Questions/preproc/mask.nii.gz --regdir ${base}/{1}/Questions/reg --space standard exfunc standard --outdir ${base}/{1}/Questions/sbca/glm_fhs_ffa_left_{3}_{2} --fwhm 2 --threads 2 --njobs 2 --tr 1 --polort 0 ::: ${subjects} ::: ${conditions} ::: ${covars}


#--- RUN GROUP ---#

#covar="mc"
for covar in ${covars}; do

  echo
  echo "covar: ${covar}"
  outname="glm_fhs_ffa_left"
  grpdir="${grpbase}/Questions/sbca/${outname}_${covar}"
  rm -r ${grpdir}
  mkdir -p ${grpdir} 2> /dev/null
  
  # get the combined mask
  run "3dMean -overwrite -prefix ${grpdir}/mask.nii.gz -mask_inter ${base}/*/Questions/sbca/${outname}_${covar}_*/mask_to_standard.nii.gz"
  run "fslmaths ${grpdir}/mask.nii.gz -mas ${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask.nii.gz ${grpdir}/mask.nii.gz"
  
  ## compute t-test
  #run "3dttest++ -overwrite -setA ${base}/*/Questions/sbca/fhs_ffa_left_${covar}_bio/corr_map_to_standard.nii.gz -setB ${base}/*/Questions/sbca/fhs_ffa_left_${covar}_phys/corr_map_to_standard.nii.gz -paired -toz -mask ${grpdir}/mask.nii.gz -prefix ${grpdir}/zstat.nii.gz"
  
  # underlay
  run "ln -sf $FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz ${grpdir}/standard_2mm.nii.gz"
  
  # manual (THIS WORKED)
  iname="zstat"
  run "fslmerge -t ${grpdir}/all_corr_map_bio.nii.gz ${base}/*/Questions/sbca/${outname}_${covar}_bio/${iname}_map_to_standard_smooth.nii.gz"
  run "fslmerge -t ${grpdir}/all_corr_map_phys.nii.gz ${base}/*/Questions/sbca/${outname}_${covar}_phys/${iname}_map_to_standard_smooth.nii.gz"
  run "fslmaths ${grpdir}/all_corr_map_bio -sub ${grpdir}/all_corr_map_phys -mas ${grpdir}/mask.nii.gz ${grpdir}/all_corr_map_diff"
  run "fslmaths ${grpdir}/all_corr_map_diff -Tmean -mas ${grpdir}/mask.nii.gz ${grpdir}/mean_corr_map_diff"
  run "fslmaths ${grpdir}/all_corr_map_diff -Tstd -mas ${grpdir}/mask.nii.gz ${grpdir}/std_corr_map_diff"
  run "3dcalc -overwrite -a ${grpdir}/mean_corr_map_diff.nii.gz -b ${grpdir}/std_corr_map_diff.nii.gz -c ${grpdir}/mask.nii.gz -expr 'step(c)*(a/(b/sqrt(16)))' -prefix ${grpdir}/tval_corr_map_diff.nii.gz"
  run "3dcalc -overwrite -a ${grpdir}/tval_corr_map_diff.nii.gz -b ${grpdir}/mask.nii.gz -expr 'step(b)*fitt_t2z(a,15)' -prefix ${grpdir}/zval_corr_map_diff.nii.gz"

done