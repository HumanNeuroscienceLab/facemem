#!/usr/bin/env bash

# This will run eventstats, and then register it to standard space
# It also copies over some underlays


###
# FUNCTIONS
###

function run() {
  echo "$@"
  eval "$@"
  return $?
}

function die() {
  echo "$@"
  exit 2
}

## see http://stackoverflow.com/questions/3915040/bash-fish-command-to-print-absolute-path-to-a-file
function abspath() {
  # $1 : relative filename
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}


###
# USER ARGS
###

if [[ $# != 3 ]]; then
  echo "usage: $0 es-opts-file subject runtype"
  exit 1
fi

esoptsfile=$(abspath $1)
subject="$2"
runtype="$3"


###
# PATHS
###

basedir="/mnt/nfs/psych/faceMemoryMRI"
subsdir="${basedir}/analysis/subjects"
xmldir="${basedir}/scripts/timing/eventstats_faceMemory01"

sdir="${subsdir}/${subject}/${runtype}"
odir="${sdir}/task/smoother_eventstats_01"

[[ ! -e ${esoptsfile} ]] && die "es-opts: ${esoptsfile} - must exist"
[[ ! -e ${sdir} ]] && die "input directory: ${sdir} - must exist"
[[ -e ${odir} ]] && die "output directory: ${odir} - must not exist"
mkdir ${odir} 2> /dev/null


###
# RUN
###

# change directory
run "cd ${odir}"

# eventstats
echo "eventstats"
run "bxh_eventstats --optsfromfile ${esoptsfile} \
  ${odir}/es \
  ${sdir}/filtered_func_data.nii.gz \
  ${xmldir}/${runtype}_${subject}/timing.xml"

# underlay
run "cp ${sdir}/mean_func.nii.gz ${odir}/"
run "cp ${sdir}/reg/standard.nii.gz standard.nii.gz"

# get list of files
ipaths=( $(ls es*.nii.gz) )
opaths=( $(echo ${ipaths[@]} | sed s/es_/es_standardized_/g) )
n=${#ipaths[@]}

# to standard
echo "to standard"
for (( i = 0; i < $n; i++ )); do
  run "gen_applywarp.rb -i ${ipaths[$i]} -r ${sdir}/reg -w 'exfunc-to-standard' -o ${opaths[$i]} --interp spline"
  run "analyze2bxh ${opaths[$i]} ${opaths[$i]%%.nii.gz}.bxh"
done
## redo the brainmask
rm es_standardized_brainmask.*
run "gen_applywarp.rb -i es_brainmask.nii.gz -r ${sdir}/reg -w 'exfunc-to-standard' -o es_standardized_brainmask.nii.gz --interp nn"
run "analyze2bxh es_standardized_brainmask.nii.gz es_standardized_brainmask.bxh"

