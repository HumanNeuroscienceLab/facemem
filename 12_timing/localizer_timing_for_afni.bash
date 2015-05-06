#!/usr/bin/env bash

# This script will generate the AFNI timing file for the localizer scans
# Note that even though for the first subject we have 3 scans, we will only
# use the first 2 scans.
# Also note that only 13 subjects have the localizer scan

indir="/mnt/nfs/share/Dropbox/ExpControl_Current/fMRI/facebodyhouse01/timing_files"
outdir="/mnt/nfs/psych/faceMemoryMRI/scripts/timing"

tmpfile1=$( mktemp --suffix '.txt' )
tmpfile2=$( mktemp --suffix '.txt' )
awk '{print $1}' ${indir}/FaceBody01_Face_run01.txt > ${tmpfile1}
awk '{print $1}' ${indir}/FaceBody01_Face_run02.txt > ${tmpfile2}
1dcat $tmpfile1 $tmpfile2 | 1dtranspose - ${outdir}/allruns_FaceBody01_Localizer_face
rm ${tmpfile1} ${tmpfile2}

