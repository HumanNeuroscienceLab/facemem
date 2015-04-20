# missing a bunch of steps to generate the overlap clusters, etc

system("cp /mnt/nfs/psych/rparcellate/rois/ho_maxprob25.nii.gz ho_maxprob25.nii.gz")
# use R to fill in the middle section
system("3dcalc -overwrite -a bin_overlap.nii.gz -b ho_maxprob25_edit.nii.gz -expr 'step(a)*step(b)' -prefix bin_overlap_masked.nii.gz")
system("3dclust -overwrite -savemask clust_overlap_masked.nii.gz -dxyz=1 0 25 bin_overlap_masked.nii.gz")
3dcalc -a thresh_overlap.nii.gz -b bin_overlap_masked.nii.gz -expr 'a*b' -prefix thresh_overlap_masked.nii.gz

3dExtrema -maxima -volume -closure -sep_dist 16 -mask_file bin_overlap.nii.gz thresh_overlap.nii.gz > peaks.txt
tail -n+11 peaks.txt | awk '{print -1*$3,-1*$4,$5}' >> peaks_simple.txt

# fix to have regular mask
3dcalc -a ../../NoQuestions/task/noquestions_task_smoother.mema/mask.nii.gz -b ../../Questions/task/questions_task_smoother.mema/mask.nii.gz -expr 'step(a)*step(b)' -prefix mask.nii.gz

cat peaks_simple.txt | 3dUndump -overwrite -prefix peaks.nii.gz -master $FSLDIR/data/standard/MNI152_T1_2mm.nii.gz -mask mask.nii.gz -xyz -srad 6 -
cat peaks_simple.txt | 3dUndump -overwrite -prefix peaks_masked.nii.gz -master $FSLDIR/data/standard/MNI152_T1_2mm.nii.gz -mask bin_overlap.nii.gz -xyz -srad 6 -
