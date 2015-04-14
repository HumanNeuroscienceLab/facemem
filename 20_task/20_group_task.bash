#!/usr/bin/env bash

echo "./21_group_task_worker.bash --subfile=../sublist_all.txt --runtype=Questions --model=spmg1 --njobs=20"
./21_group_task_worker.bash --subfile=../sublist_all.txt --runtype=Questions --model=spmg1 --njobs=20

echo "./21_group_task_worker.bash --subfile=../sublist_all.txt --runtype=NoQuestions --model=spmg1 --njobs=20"
./21_group_task_worker.bash --subfile=../sublist_all.txt --runtype=NoQuestions --model=spmg1 --njobs=20






#base="/mnt/nfs/psych/faceMemoryMRI/analysis/subjects"
#subject="tb9226"
#runtype="Questions"
#
#adir="${base}/${subject}/anat"
#fdir="${base}/${subject}/${runtype}"
#mkdir ${fdir}/frois 2> /dev/null
#mkdir ${fdir}/connectivity 2> /dev/null
#
#gen_applywarp.rb -i ${adir}/segment/highres_pve_1.nii.gz -r ${fdir}/reg -w 'highres-to-exfunc' -o ${fdir}/frois/grey_matter_pve.nii.gz --interp spline
#3dcalc -overwrite -a ${fdir}/frois/grey_matter_pve.nii.gz -b ${fdir}/mask.nii.gz -expr 'step(a-0.25)*step(b)' -prefix ${fdir}/frois/grey_matter.nii.gz
#3dmask_tool -overwrite -input ${fdir}/frois/grey_matter.nii.gz -dilate_inputs 1 -1 -prefix ${fdir}/frois/grey_matter_dil.nii.gz
#
#export OMP_NUM_THREADS=12
#time 3dTcorrMap -input ${fdir}/filtered_func_data.nii.gz -mask ${fdir}/frois/grey_matter_dil.nii.gz -Mseed -1 -Zmean ${fdir}/connectivity/gcor_gmdil.nii.gz
#
#mkdir tmp
#subjects=$( cd ${base}; ls )
#
#parallel --no-notice -j 12 --eta \
#  gen_applywarp.rb -i ${base}/{}/anat/segment/highres_pve_1.nii.gz -r ${base}/{}/anat/reg -w 'highres-to-standard' -o tmp/grey_matter_pve_{}.nii.gz --interp spline ::: ${subjects}
#
#fslmerge -t tmp/grey_pve_all tmp/grey_matter_pve_*.nii.gz
#fslmaths tmp/grey_pve_all -thr 0.5 -Tmean tmp/grey_prob
