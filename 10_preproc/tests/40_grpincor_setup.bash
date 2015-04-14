#!/usr/bin/env bash

function run() {
  echo "$@"
  eval "$@"
  return $?
}

std_mask=$FSLDIR/data/standard/MNI152_T1_2mm_brain_mask_dil.nii.gz

inbase="/mnt/nfs/psych/faceMemoryMRI/analysis/subjects"
outbase="/mnt/nfs/psych/faceMemoryMRI/analysis/groups"

runtypes="Questions"
conditions="bio phys"
fnames="func_concat func_concat_fsl func_concat_mc func_concat_mc_compcor_top5 func_concat_mc_compcor_sim"

subjs=$( cat sublist_14.txt )
methods="fsl"


#--- instacor setup ---#

for runtype in ${runtypes}; do
  echo
  echo "runtype: ${runtype}"
  
  outdir=${outbase}/${runtype}/instacor
  mkdir ${outdir} 2> /dev/null
  cd ${outdir}
  
  # Mask
  allsubs=${outdir}/mask_all.nii.gz
  prop=${outdir}/prop_subjects.nii.gz
  mask=${outdir}/mask.nii.gz
  mask2=${outdir}/mask_fill.nii.gz
  run "fslmerge -t ${allsubs} ${inbase}/*/${runtype}/preproc/mask_to_standard.nii.gz"
  run "fslmaths ${allsubs} -Tmean -bin ${prop}"
  run "fslcpgeom ${std_mask} ${prop} -d"
  run "fslmaths ${prop} -thr 1 -bin -mas ${std_mask} ${mask}"
  #run "fslmaths ${prop} -thr 0.9 -mas ${std_mask} -bin ${mask}"
  #run "3dmask_tool -input ${mask} -fill_holes -prefix ${mask2}"
  ##run "3dcalc -overwrite -a ${prop} -expr 'equals(a,1)' -prefix ${mask}"
  
  # Data
  for condition in ${conditions}; do
    echo
    echo "- condition: ${condition}"
    for method in ${methods}; do
      echo "-- method: ${method}"
      
      for fname in ${fnames}; do
        echo "--- fname: ${fname}"
        
        # Func List
        flist=""
        for subj in ${subjs}; do
          indir="${inbase}/${subj}/${runtype}/preproc/split_ts/tests"
          func="${indir}/${fname}_${condition}_to_standard_${method}.nii.gz"
          flist="${flist} ${func}"
        done
      
        run "3dSetupGroupInCorr -overwrite -prep DEMEAN -byte -mask ${outdir}/mask.nii.gz -prefix ${outdir}/${fname}_${condition}_${method}${flist}"
      done      
    done
  done
  
  cd -
done


# To run:
# cd /mnt/nfs/psych/faceMemoryMRI/analysis/groups/Questions/instacor
# 3dGroupInCorr -setA time_series_bio.grpincorr.niml -setB time_series_phys.grpincorr.niml -labelA bio -labelB phys -paired -seedrad 6

# 3dGroupInCorr -setA beta_series_bio.grpincorr.niml -setB beta_series_phys.grpincorr.niml -labelA bio -labelB phys -paired -seedrad 6
