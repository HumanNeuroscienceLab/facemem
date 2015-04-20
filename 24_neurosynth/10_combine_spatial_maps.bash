#!/usr/bin/env bash

# Here we combine our reverse inference maps of interest to use
# in the temporal regression

base="/mnt/nfs/psych/faceMemoryMRI/analysis/groups/mni152"
nsdir="${base}/neurosynth"
suffix="_pFgA_z_FDR_0.01.nii.gz"
outdir="${base}/dr"
mkdir ${outdir} 2> /dev/null


## First
#terms=( \
#  "faces" \
#  "scenes" \
#  "semantic_memory" \
#  "face_memory" \
#  "face_familiar" \
#  "episodic_memory" \
#)
## create the command to run
#cmd="fslmerge -t ${outdir}/ri_maps_01.nii.gz"
#for term in ${terms[@]}; do
#  cmd="${cmd} ${nsdir}/${term}${suffix}"
#done
## run the command merging everything into one
#echo $cmd
#eval $cmd
## spit out the list of terms for reference
#echo ${terms[@]} | tr ' ' '\n' > ${outdir}/ri_maps_01_terms.txt

## Second: Face and Scenes
#terms=( \
#  "faces" \
#  "scenes" \
#)
## create the command to run
#cmd="fslmerge -t ${outdir}/ri_face_scene.nii.gz"
#for term in ${terms[@]}; do
#  cmd="${cmd} ${nsdir}/${term}${suffix}"
#done
## run the command merging everything into one
#echo $cmd
#eval $cmd
## spit out the list of terms for reference
#echo ${terms[@]} | tr ' ' '\n' > ${outdir}/ri_face_scene_terms.txt

## Third: Face vs Scenes (contrast in neurosynth)
#terms=( \
#  "faces" \
#  "scenes" \
#)
## combine
#3dcalc -overwrite -a ${nsdir}/faces_vs_scenes_pFgA_z.nii.gz -expr 'step(a-1.28)*a' -prefix ${outdir}/ri_faces_gt_scenes.nii.gz
#3dcalc -overwrite -a ${nsdir}/faces_vs_scenes_pFgA_z.nii.gz -expr 'step((-1*a)-1.28)*(-1*a)' -prefix ${outdir}/ri_scenes_gt_faces.nii.gz
#fslmerge -t ${outdir}/ri_face_vs_scene.nii.gz ${outdir}/ri_faces_gt_scenes.nii.gz ${outdir}/ri_scenes_gt_faces.nii.gz
## spit out the list of terms for reference
#echo ${terms[@]} | tr ' ' '\n' > ${outdir}/ri_face_vs_scene_terms.txt

## Fourth: Face vs Scenes using the probabilistic atlas
#terms=( \
#  "faces" \
#  "scenes" \
#)
## combine
#asap="/mnt/nfs/share/rois/asap/ASAP_maps"
#fslmerge -t ${outdir}/prob_face_vs_scene.nii.gz ${asap}/facescene_pmap_N124_stat3.nii.gz ${asap}/facescene_pmap_N124_stat4.nii.gz
## spit out the list of terms for reference
#echo ${terms[@]} | tr ' ' '\n' > ${outdir}/prob_face_vs_scene_terms.txt

# Fifth: Visual, Auditory, Motor
terms=( \
  "visual" \
  "auditory" \
  "motor" \
)
# create the command to run
cmd="fslmerge -t ${outdir}/ri_sensory.nii.gz"
for term in ${terms[@]}; do
  cmd="${cmd} ${nsdir}/${term}${suffix}"
done
# run the command merging everything into one
echo $cmd
eval $cmd
# spit out the list of terms for reference
echo ${terms[@]} | tr ' ' '\n' > ${outdir}/ri_sensory_terms.txt

# Sixth: Memory Encoding, Memory Retrieval, Working Memory
terms=( \
  "memory_encoding" \
  "memory_retrieval" \
  "working_memory" \
)
# create the command to run
cmd="fslmerge -t ${outdir}/ri_memory.nii.gz"
for term in ${terms[@]}; do
  cmd="${cmd} ${nsdir}/${term}${suffix}"
done
# run the command merging everything into one
echo $cmd
eval $cmd
# spit out the list of terms for reference
echo ${terms[@]} | tr ' ' '\n' > ${outdir}/ri_memory_terms.txt

# Seventh: Faces, Semantic, Memory
terms=( \
  "faces" \
  "semantic" \
  "memory" \
)
# create the command to run
cmd="fslmerge -t ${outdir}/ri_mix.nii.gz"
for term in ${terms[@]}; do
  cmd="${cmd} ${nsdir}/${term}${suffix}"
done
# run the command merging everything into one
echo $cmd
eval $cmd
# spit out the list of terms for reference
echo ${terms[@]} | tr ' ' '\n' > ${outdir}/ri_mix_terms.txt

