#!/usr/bin/env bash

# alas this and a_* are the same...messy

# Copy the image into the oblique_slice folder that already exists

base=/mnt/nfs/psych/faceMemoryMRI
grp="${base}/analysis/groups"
region="parcels_group_localizer_n0658"
region2="parcels_n658"
indir="${grp}/Questions/cmaps/ts_${region}_bootstrap+perms.sca"
indir2="${grp}/Questions/connectivity/tconn_${region2}"
echo "cd ${grp}/Combo/oblique_slice"
cd ${grp}/Combo/oblique_slice


#--- COPY ---#

#ln -sf ${indir}/parcels.nii.gz .
#
## summary map
#3dcopy -overwrite ${indir}/thresh_summary_bio_vs_phys.nii.gz sbca_summary_bio_vs_phys.nii.gz
#
## parcel sca with vatl
#3dcopy -overwrite ${indir}/smaps/zstats_bio_gt_phys_0397.nii.gz sca_parcel_vatl_bio_gt_phys.nii.gz
#3dcopy -overwrite ${indir}/smaps/zstats_bio+phys_0397.nii.gz sca_parcel_vatl_bio_n_phys.nii.gz
#
## parcel
#3dcalc -overwrite -a ${indir}/parcels.nii.gz -expr 'step(equals(a,397))' -prefix parcel_vatl.nii.gz

# voxelwise sbca with vatl
3dcopy -overwrite ${indir2}/easythresh_liberal/thresh_zstats_parcels_397_bio_gt_phys.nii.gz $(pwd)/zstats_parcels_397_bio_gt_phys.nii.gz

#--- ROTATE AND STUFF ---#

#3drotate -overwrite -verbose -NN -prefix parcels_rot.nii.gz -zpad 10 -rotate -20R 0 0 parcels.nii.gz
#
#3drotate -overwrite -verbose -NN -prefix parcel_vatl_rot.nii.gz -zpad 10 -rotate -20R 0 0 parcel_vatl.nii.gz
#
#3drotate -overwrite -verbose -NN -prefix sbca_summary_bio_vs_phys_rot.nii.gz -zpad 10 -rotate -20R 0 0 sbca_summary_bio_vs_phys.nii.gz
#
#3drotate -overwrite -verbose -NN -prefix sbca_summary_bio_vs_phys_rot.nii.gz -zpad 10 -rotate -20R 0 0 sbca_summary_bio_vs_phys.nii.gz
#
#3drotate -overwrite -verbose -NN -prefix sca_parcel_vatl_bio_gt_phys_rot.nii.gz -zpad 10 -rotate -20R 0 0 sca_parcel_vatl_bio_gt_phys.nii.gz
### threshold
#3dcalc -a sca_parcel_vatl_bio_gt_phys_rot.nii.gz -expr 'step(abs(a)-1.95)*a' -prefix thresh_sca_parcel_vatl_bio_gt_phys_rot.nii.gz
### scale
#3dcalc -a thresh_sca_parcel_vatl_bio_gt_phys_rot.nii.gz -expr 'step(a-1.95)*(a-1.95) - (step(-1*a-1.95)*(-1*a-1.95))' -prefix thresh_sca_parcel_vatl_bio_gt_phys_rot_scale.nii.gz
#
#3drotate -overwrite -verbose -NN -prefix sca_parcel_vatl_bio_n_phys_rot.nii.gz -zpad 10 -rotate -20R 0 0 sca_parcel_vatl_bio_n_phys.nii.gz

pre="zstats_parcels_397_bio_gt_phys"
echo "3drotate -overwrite -verbose -NN -prefix ${pre}_rot.nii.gz -zpad 10 -rotate -20R 0 0 ${pre}.nii.gz"
3drotate -overwrite -verbose -NN -prefix ${pre}_rot.nii.gz -zpad 10 -rotate -20R 0 0 ${pre}.nii.gz
## threshold
3dcalc -overwrite -a ${pre}_rot.nii.gz -expr 'step(abs(a)-1.645)*a' -prefix thresh_${pre}_rot.nii.gz
## scale
3dcalc -overwrite -a thresh_${pre}_rot.nii.gz -expr 'step(a-1.645)*(a-1.645) - (step(-1*a-1.645)*(-1*a-1.645))' -prefix thresh_${pre}_rot_scale.nii.gz

