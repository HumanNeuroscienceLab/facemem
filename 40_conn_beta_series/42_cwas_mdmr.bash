#!/usr/bin/env bash

# Will run CWAS using the parcel data comparing bio vs phys connectivity patterns
# Only MDMR here.


#--- SETUP ---#

# input paths
basedir="/mnt/nfs/psych/faceMemoryMRI"
subBaseDir="${basedir}/analysis/subjects"

runtype="Questions"
echo
echo "Runtype: ${runtype}"

# output paths
outBaseDir="${basedir}/analysis/groups/${runtype}/cwas"
mkdir ${outBaseDir} 2> /dev/null

# Create the model file
# Remember that this must match with the list of subjects/scans used for the 
# subdist calculation
# We have a header of subjects,conditions
# the subjects columns will be 1:nsubjects, repeated twice
# the conditions column will be bio repeated nsubjects, and phys repeated for nsubjects
echo "creating the model file"
nsubs=$( ls -d ${subBaseDir}/*/${runtype}/task/beta_series_spmg1_nocompcor.reml/reg_standard/beta_series_bio.nii.gz | wc -l )
Rscript \
  -e "subs <- rep(1:${nsubs}, 2)" \
  -e "conds <- rep(c('bio','phys'), each=${nsubs})" \
  -e "df <- data.frame(subjects=subs, conditions=conds)" \
  -e "write.csv(df, file='model_bio_vs_phys.csv')"

# Look at the distances between scans
dists="pearson"
for dist in ${dists}; do
  echo
  echo "running mdmr with distance method: ${dist}"
  echo "see ${outBaseDir}/beta_series_3mm_nocompcor.subdist/bio_vs_phys_perms.mdmr"
  connectir_mdmr.R -i ${outBaseDir}/beta_series_3mm_nocompcor.subdist \
      --formula "subjects + conditions" \
      --model model_bio_vs_phys.csv \
      --factors2perm "conditions" \
      --strata "subjects" \
      --permutations 14999 \
      --forks 20 --threads 1 \
      --memlimit 36 \
      --save-perms \
      --ignoreprocerror \
      bio_vs_phys_perms.mdmr
done
