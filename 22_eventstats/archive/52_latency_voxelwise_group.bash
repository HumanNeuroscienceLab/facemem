#!/usr/bin/env bash

function run() {
  echo $@
  eval $@
  return $?
}


base="/mnt/nfs/psych/faceMemoryMRI"
ibase="${base}/analysis/subjects"
obase="${base}/analysis/groups"

runtypes="Questions NoQuestions"
#runtype="Questions"

for runtype in ${runtypes}; do
  echo "=== runtype: ${runtype} ==="

  lruntype=$( echo $runtype | tr '[:upper:]' '[:lower:]' )
  names="onset_latency peak_height peak_height_ttest peak_latency width"

  outdir="${obase}/${runtype}/task/latency.ttests"
  run "mkdir -p ${outdir} 2> /dev/null"
  run "cd ${outdir}"

  run "cp ${obase}/${runtype}/task/${lruntype}_task.mema/mask.nii.gz mask.nii.gz"
  run "ln -s $FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz standard_2mm.nii.gz"
  
  echo "average eventstats"
  ## bio
  run "3dMean -non_zero -prefix bio_ave_percent.nii.gz ${ibase}/*/${runtype}/latency/bio_ave_percent_to_std.nii.gz"
  run "3dcalc -overwrite -a bio_ave_percent.nii.gz -b mask.nii.gz -expr 'a*step(b)' -prefix bio_ave_percent.nii.gz"
  ## phys
  run "3dMean -non_zero -prefix phys_ave_percent.nii.gz ${ibase}/*/${runtype}/latency/phys_ave_percent_to_std.nii.gz"
  run "3dcalc -overwrite -a phys_ave_percent.nii.gz -b mask.nii.gz -expr 'a*step(b)' -prefix phys_ave_percent.nii.gz"
  
  echo "average smoothed eventstats"
  ## bio
  run "3dMean -non_zero -prefix bio_smooth_ave_percent.nii.gz ${ibase}/*/${runtype}/latency/bio_smooth_ave_percent_to_std.nii.gz"
  run "3dcalc -overwrite -a bio_smooth_ave_percent.nii.gz -b mask.nii.gz -expr 'a*step(b)' -prefix bio_smooth_ave_percent.nii.gz"
  ## phys
  run "3dMean -non_zero -prefix phys_smooth_ave_percent.nii.gz ${ibase}/*/${runtype}/latency/phys_smooth_ave_percent_to_std.nii.gz"
  run "3dcalc -overwrite -a phys_smooth_ave_percent.nii.gz -b mask.nii.gz -expr 'a*step(b)' -prefix phys_smooth_ave_percent.nii.gz"
  
  for name in ${names}; do  
    echo "name: ${name}"
  
    run "mkdir afni 2> /dev/null"
    run "mkdir stats 2> /dev/null"
  
    echo "...wicoxon"
    cmd="3dWilcoxon"
    for fname in $(ls -d ${ibase}/*/${runtype}/latency/bio_${name}_to_std.nii.gz); do
      cmd="${cmd} -dset 1 ${fname}"
    done
    for fname in $(ls -d ${ibase}/*/${runtype}/latency/phys_${name}_to_std.nii.gz); do
      cmd="${cmd} -dset 2 ${fname}"
    done
    cmd="${cmd} -out afni/wilcoxon_${name}.nii.gz"
    run $cmd
    run "3dcalc -overwrite -a afni/wilcoxon_${name}.nii.gz -b mask.nii.gz -expr 'a*b' -prefix afni/wilcoxon_${name}.nii.gz"
  
    # outputs
    # #0  SetA-SetB_mean      = difference of means
    # #1  SetA-SetB_Tstat
    # #2  SetA_mean           = mean of SetA
    # #3  SetA_Tstat
    # #4  SetB_mean           = mean of SetB
    # #5  SetB_Tstat
  
    echo "...ttest"
    run "3dttest++ \
      -setA ${ibase}/*/${runtype}/latency/bio_${name}_to_std.nii.gz \
      -setB ${ibase}/*/${runtype}/latency/phys_${name}_to_std.nii.gz \
      -paired -toz \
      -mask mask.nii.gz \
      -prefix afni/ttests_${name}.nii.gz"
    
    echo "...split ttest output"
    run "3dcalc -a afni/ttests_${name}.nii.gz'[SetA-SetB_mean]' -expr a -prefix stats/mean_${name}_bio_vs_phys.nii.gz"
    run "3dcalc -a afni/ttests_${name}.nii.gz'[SetA-SetB_Zscr]' -expr a -prefix stats/zstat_${name}_bio_vs_phys.nii.gz"
    ##
    run "3dcalc -a afni/ttests_${name}.nii.gz'[SetA_mean]' -expr a -prefix stats/mean_${name}_bio.nii.gz"
    run "3dcalc -a afni/ttests_${name}.nii.gz'[SetA_Zscr]' -expr a -prefix stats/zstat_${name}_bio.nii.gz"
    ##
    run "3dcalc -a afni/ttests_${name}.nii.gz'[SetB_mean]' -expr a -prefix stats/mean_${name}_phys.nii.gz"
    run "3dcalc -a afni/ttests_${name}.nii.gz'[SetB_Zscr]' -expr a -prefix stats/zstat_${name}_phys.nii.gz"
  
    echo "...cluster correct ttest output"
    run "easythresh stats/zstat_${name}_bio_vs_phys.nii.gz mask.nii.gz 1.96 0.05 standard_2mm.nii.gz zstat_${name}_bio_vs_phys"
    run "easythresh stats/zstat_${name}_bio_vs_phys.nii.gz mask.nii.gz 1.65 0.1 standard_2mm.nii.gz liberal_zstat_${name}_bio_vs_phys"
  
    echo
  done
  
  echo
  echo
done
