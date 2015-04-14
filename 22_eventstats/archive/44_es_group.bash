#!/usr/bin/env bash

basedir="/mnt/nfs/psych/faceMemoryMRI"
subsdir="${basedir}/analysis/subjects"
grpdir="${basedir}/analysis/groups"

sdir="${subsdir}/${subject}/${runtype}"
odir="${sdir}/task/smoother_eventstats_01"

runtype="Questions"
echo
echo $runtype
mkdir ${grpdir}/${runtype}/task/smoother_eventstats_01 2> /dev/null
indirs=$( ls -d ${subsdir}/*/${runtype}/task/smoother_eventstats_01/es_bio_avg.nii.gz | sed s/es_bio_avg\.nii\.gz/es/g )
bxh_eventstats_combine ${indirs} ${grpdir}/${runtype}/task/smoother_eventstats_01/es

runtype="NoQuestions"
echo
echo $runtype
mkdir ${grpdir}/${runtype}/task/smoother_eventstats_01 2> /dev/null
indirs=$( ls -d ${subsdir}/*/${runtype}/task/smoother_eventstats_01/es_bio_avg.nii.gz | sed s/es_bio_avg\.nii\.gz/es/g )
bxh_eventstats_combine ${indirs} ${grpdir}/${runtype}/task/smoother_eventstats_01/es
