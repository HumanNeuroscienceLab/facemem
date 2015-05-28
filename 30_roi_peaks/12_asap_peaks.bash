#!/usr/bin/env bash

# Download the ASAP maps
# Create a joint (weighted) face>scene + face>house map
# Extract ROIs from this map

function run {
    echo $@
    eval $@
}


echo "Downloading ASAP maps"
run "wget http://www.andrewengell.com/wp/wp-content/ASAP/ASAP_maps.zip"
run "unzip ASAP_maps.zip"
run "rm -r __MACOSX ASAP_maps.zip"

echo "Combining face>scene with face>house"
run "3dcalc -a ASAP_maps/facescene_pmap_N124_stat3.nii.gz -b ASAP_maps/facehouse_pmap_N79_stat3.nii.gz -expr '(124*a + 79*b)/(124+79)' -prefix ASAP_maps/facescene+facehouse_stat3.nii.gz"

echo "Apply just a little bit of smoothing (2mm)"
run "3dcalc -a ASAP_maps/facescene+facehouse_stat3.nii.gz -expr 'notzero(a)' -prefix ASAP_maps/facescene+facehouse_stat3_mask.nii.gz"
run "3dBlurInMask -input ASAP_maps/facescene+facehouse_stat3.nii.gz -FWHM 2 -mask ASAP_maps/facescene+facehouse_stat3_mask.nii.gz -prefix ASAP_maps/facescene+facehouse_stat3_fwhm2.nii.gz"

echo "Calculating peaks with different distances btw peaks"
run "3dExtrema -data_thr 0.1 -sep_dist 4 -output ASAP_maps/facescene+facehouse_stat3_peaks_sep04.nii.gz -volume ASAP_maps/facescene+facehouse_stat3_fwhm2.nii.gz > ASAP_maps/facescene+facehouse_stat3_peaks_sep04.txt"
run "3dExtrema -data_thr 0.1 -sep_dist 8 -output ASAP_maps/facescene+facehouse_stat3_peaks_sep08.nii.gz -volume ASAP_maps/facescene+facehouse_stat3_fwhm2.nii.gz > ASAP_maps/facescene+facehouse_stat3_peaks_sep08.txt"
run "3dExtrema -data_thr 0.1 -sep_dist 12 -output ASAP_maps/facescene+facehouse_stat3_peaks_sep12.nii.gz -volume ASAP_maps/facescene+facehouse_stat3_fwhm2.nii.gz > ASAP_maps/facescene+facehouse_stat3_peaks_sep12.txt"
run "3dExtrema -data_thr 0.1 -sep_dist 16 -output ASAP_maps/facescene+facehouse_stat3_peaks_sep16.nii.gz -volume ASAP_maps/facescene+facehouse_stat3_fwhm2.nii.gz > ASAP_maps/facescene+facehouse_stat3_peaks_sep16.txt"

echo "Generate ROIs with 4mm radius spheres for the peaks with 12mm distances"
run "tail -n+9 ASAP_maps/facescene+facehouse_stat3_peaks_sep12.txt | head -n-2 | awk '{print -\$3,-\$4,\$5,\$1}' > ../face_gt_house+scene.txt" 
    # want to output file with 4 columns: x y z val
    # note that output is in RAI so we convert to LPI
run "3dUndump -srad 4 -master ASAP_maps/facescene+facehouse_stat3_peaks_sep12.nii.gz -xyz -orient LPI -prefix ../face_gt_house+scene.nii.gz ../face_gt_house+scene.txt"
