#!/usr/bin/env bash

#roi="l_atl"
runtype=Questions

genname="parcels_n658"

base="/mnt/nfs/psych/faceMemoryMRI"
subsdir="${base}/analysis/subjects"
grpdir="${base}/analysis/groups"
outdir="${grpdir}/${runtype}/connectivity/tconn_${genname}"

rois="parcels_397"

mkdir ${grpdir}/${runtype}/connectivity 2> /dev/null
mkdir ${outdir} 2> /dev/null
echo "cd ${outdir}"
cd ${outdir}

3dMean -overwrite -mask_inter -prefix mask.nii.gz ${subsdir}/tb*/${runtype}/reg_standard/mask.nii.gz
3dcalc -overwrite -a mask.nii.gz -b $FSLDIR/data/standard/MNI152_T1_2mm_brain_mask_dil.nii.gz -expr 'a*b' -prefix mask.nii.gz

ln -sf $FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz standard_2mm.nii.gz
mkdir easythresh 2> /dev/null
mkdir easythresh_liberal 2> /dev/null

roi=$rois
echo $roi
3dttest++ \
  -overwrite \
  -prefix stats_${roi}.nii.gz \
  -mask mask.nii.gz \
  -setA ${subsdir}/tb*/${runtype}/connectivity/task_residuals.reml/std_z_conn_${roi}_bio.nii.gz \
  -labelA bio \
  -setB ${subsdir}/tb*/${runtype}/connectivity/task_residuals.reml/std_z_conn_${roi}_phys.nii.gz \
  -labelB phys \
  -paired \
  -toz
3dcalc -overwrite -a stats_${roi}.nii.gz'[1]' -expr 'a' -prefix zstats_${roi}_bio_gt_phys.nii.gz

cd easythresh
easythresh ../zstats_${roi}_bio_gt_phys.nii.gz ../mask.nii.gz 1.96 0.05 ../standard_2mm.nii.gz zstats_${roi}_bio_gt_phys
cd -

# For liberal threshold use the resids
fslmerge -t concat_subj_parcels_397_bio ${subsdir}/tb*/${runtype}/connectivity/task_residuals.reml/std_z_conn_${roi}_bio.nii.gz 
fslmerge -t concat_subj_parcels_397_phys ${subsdir}/tb*/${runtype}/connectivity/task_residuals.reml/std_z_conn_${roi}_phys.nii.gz
fslmaths concat_subj_parcels_397_bio -sub concat_subj_parcels_397_phys concat_subj_parcels_397_bio_gt_phys
fslmaths concat_subj_parcels_397_bio_gt_phys -Tmean concat_subj_parcels_397_bio_gt_phys_mean
fslmaths concat_subj_parcels_397_bio_gt_phys -sub concat_subj_parcels_397_bio_gt_phys_mean concat_subj_parcels_397_bio_gt_phys_resid

SM=`smoothest -d 14 -r concat_subj_${roi}_bio_gt_phys_resid.nii.gz -m mask.nii.gz`
DLH=`echo $SM | awk '{print $2}'`
VOLUME=`echo $SM | awk '{print $4}'`
RESELS=`echo $SM | awk '{print $6}'`
fslmaths zstats_${roi}_bio_gt_phys.nii.gz -mas mask easythresh_liberal/thresh_zstats_${roi}_bio_gt_phys
fslcpgeom standard_2mm.nii.gz easythresh_liberal/thresh_zstats_${roi}_bio_gt_phys
cluster -i easythresh_liberal/thresh_zstats_${roi}_bio_gt_phys -t 1.645 -p 0.05 --volume=$VOLUME -d $DLH --othresh=easythresh_liberal/thresh_zstats_${roi}_bio_gt_phys > easythresh_liberal/clust_${roi}_bio_gt_phys.txt

fslmaths concat_subj_${roi}_bio_gt_phys_resid.nii.gz -mul -1 concat_subj_${roi}_phys_gt_bio_resid.nii.gz
SM=`smoothest -d 14 -r concat_subj_${roi}_phys_gt_bio_resid.nii.gz -m mask.nii.gz`
DLH=`echo $SM | awk '{print $2}'`
VOLUME=`echo $SM | awk '{print $4}'`
RESELS=`echo $SM | awk '{print $6}'`
fslmaths zstats_${roi}_bio_gt_phys.nii.gz -mul -1 -mas mask easythresh_liberal/thresh_zstats_${roi}_phys_gt_bio
fslcpgeom standard_2mm.nii.gz easythresh_liberal/thresh_zstats_${roi}_phys_gt_bio
cluster -i easythresh_liberal/thresh_zstats_${roi}_phys_gt_bio -t 1.645 -p 0.05 --volume=$VOLUME -d $DLH --othresh=easythresh_liberal/thresh_zstats_${roi}_phys_gt_bio > easythresh_liberal/clust_${roi}_phys_gt_bio.txt


echo



#mkdir easythresh_test_threshold 2> /dev/null
#
#SM=`${FSLDIR}/bin/smoothest -z zstats_${roi}_bio_gt_phys.nii.gz -m mask.nii.gz`
#DLH=`echo $SM | awk '{print $2}'`
#VOLUME=`echo $SM | awk '{print $4}'`
#RESELS=`echo $SM | awk '{print $6}'`
#fslmaths zstats_${roi}_bio_gt_phys.nii.gz -mas mask easythresh_test_threshold/thresh_zstats_${roi}_bio_gt_phys
#fslcpgeom standard_2mm.nii.gz easythresh_test_threshold/thresh_zstats_${roi}_bio_gt_phys
#cluster -i easythresh_test_threshold/thresh_zstats_${roi}_bio_gt_phys -t 1.96 -p 0.5 --volume=$VOLUME -d $DLH --minclustersize
#
#cluster -i easythresh_test_threshold/thresh_zstats_${roi}_bio_gt_phys -t 1.96 -p 0.5 --volume=$VOLUME -d $DLH -o cluster_mask_$6 --othresh=thresh_$6 $7 > cluster_$6.txt
#
#
#
