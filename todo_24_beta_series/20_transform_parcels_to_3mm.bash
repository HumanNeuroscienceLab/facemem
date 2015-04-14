#!/usr/bin/env bash

roi_dir="/mnt/nfs/psych/faceMemoryMRI/analysis/groups/Localizer/parcels_migp"
std_dir="/mnt/nfs/share/fsl/current/data/standard"

# Infiles
in_mask_file="${roi_dir}/group_mask.nii.gz"
in_roi_file="${roi_dir}/group_region_growing/parcels_relabel.nii.gz"
in_std_file="${std_dir}/MNI152_T1_3mm_brain.nii.gz"

# Outfiles
out_mask_file="${roi_dir}/group_mask_3mm.nii.gz"
out_roi_file="${roi_dir}/group_region_growing/parcels_relabel_3mm.nii.gz"

# Run
3dresample -inset ${in_mask_file} -master ${in_std_file} -prefix ${out_mask_file} -rmode NN
3dresample -inset ${in_roi_file} -master ${in_std_file} -prefix ${out_roi_file} -rmode NN
3dcalc -overwrite -a ${out_roi_file} -b ${out_mask_file} -expr 'a*step(b)' -prefix ${out_roi_file}
