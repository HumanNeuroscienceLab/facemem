#!/usr/bin/env bash

# We are going to redo the probabilistic atlas ROIs and see if we can get the vATL to better match what's found in the literature

function run {
    echo $@
    eval $@
    return $?
}

asapdir="/mnt/nfs/share/rois/asap/ASAP_maps"
aparcdir="/mnt/nfs/psych/faceMemoryMRI/analysis/groups/mni152/freesurfer/aparc_2mm"
odir="/mnt/nfs/psych/faceMemoryMRI/analysis/rois/asap"

cd $odir

# Copy over the relevant data
echo "Copying over relevant data"
## group mask
run "3dcalc -a ../../groups/Combo/overlap/mask.nii.gz -expr a -prefix mask.nii.gz"
## probabilistic atlas
run "3dcalc -a ${asapdir}/facehouse_pmap_N79_stat3.nii.gz -expr a -prefix pmap_face_gt_house.nii.gz"
run "3dcalc -a ${asapdir}/facescene_pmap_N*_stat3.nii.gz -expr a -prefix pmap_face_gt_scene.nii.gz"
## maybe the freesurfer atlases? (dilate and erode)
run "3dmask_tool -inputs ${aparcdir}/lh_fusiform.nii.gz -prefix lh_fusiform.nii.gz -dilate_inputs 1 -1 -fill_holes"
run "3dmask_tool -inputs ${aparcdir}/lh_lateraloccipital.nii.gz -prefix lh_lateraloccipital.nii.gz -dilate_inputs 1 -1 -fill_holes"
run "3dmask_tool -inputs ${aparcdir}/lh_inferiortemporal.nii.gz -prefix lh_inferiortemporal.nii.gz -dilate_inputs 1 -1 -fill_holes"
run "3dcalc -a lh_fusiform.nii.gz -b lh_lateraloccipital.nii.gz -c lh_inferiortemporal.nii.gz -expr 'step(a+b+c)' -prefix lh_anat_mask.nii.gz"

# Let's focus on the face vs house contrast
echo "Apply just a little bit of smoothing (2mm)"
run "3dcalc -overwrite -a pmap_face_gt_house.nii.gz -b mask.nii.gz -c lh_anat_mask.nii.gz -expr 'step(notzero(a)*b*c)' -prefix mask_touse.nii.gz"
run "3dBlurInMask -overwrite -input pmap_face_gt_house.nii.gz -FWHM 2 -mask mask_touse.nii.gz -prefix pmap_face_gt_house_fwhm2.nii.gz"
run "3dcalc -overwrite -a pmap_face_gt_scene.nii.gz -b mask.nii.gz -c lh_anat_mask.nii.gz -expr 'step(notzero(a)*b*c)' -prefix mask_touse.nii.gz"
run "3dBlurInMask -input pmap_face_gt_scene.nii.gz -FWHM 2 -mask mask_touse.nii.gz -prefix pmap_face_gt_scene_fwhm2.nii.gz"

echo "Calculating peaks with different distances btw peaks"
run "3dExtrema -data_thr 0.1 -sep_dist 12 -output peaks_sep12.nii.gz -volume pmap_face_gt_house_fwhm2.nii.gz > peaks_sep12.txt"
run "3dExtrema -data_thr 0.1 -sep_dist 16 -output peaks_sep16.nii.gz -volume pmap_face_gt_house_fwhm2.nii.gz > peaks_sep16.txt"
run "3dExtrema -overwrite -data_thr 0.1 -sep_dist 12 -output peaks_sep12.nii.gz -volume pmap_face_gt_scene_fwhm2.nii.gz > peaks_sep12.txt"
run "3dExtrema -overwrite -data_thr 0.1 -sep_dist 16 -output peaks_sep16.nii.gz -volume pmap_face_gt_scene_fwhm2.nii.gz > peaks_sep16.txt"

# DOing all of this above doesn't change the original ROIs that I got by much
