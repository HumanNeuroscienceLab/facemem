#!/usr/bin/env bash

###
# Functions/Setup
###

function die() {
  echo "$@"
  exit 2
}


function run() {
  echo "$@"
  eval "$@"
  return $?
}

function scriptpath() {
  pushd `dirname $0` > /dev/null
  sp=`pwd`
  popd > /dev/null
  echo $sp
}

## see http://stackoverflow.com/questions/3915040/bash-fish-command-to-print-absolute-path-to-a-file
function abspath() { 
  # $1 : relative filename
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

# Check if mac and switch to using greadlink / greadpath
if [[ $(uname) == "Darwin" ]]; then
  rl="greadlink" # on mac: brew install coreutils
elif [[ $(uname) == "Linux" ]]; then
  rl="readlink"
else
  echo "unknown os: $(uname)"
  exit 2
fi


###
# User Args
###

if [[ $# -ne 3 ]]; then
  echo "usage: $(basename $0) infile thresh outprefix"
  exit 1
fi

[[ ! -e $1 ]] && die "input file '${1}' doesn't exist"
[[ ! -e $(dirname $3) ]] && die "output directory for prefix '${3}' doesn't exist"

origfile=$(abspath $1)
thresh=$2
outprefix=$(${rl} -m $3) # on mac: brew install coreutils


###
# Setup
###

echo
echo "Setup"

echo "create new temp directory and have all data in there"
tmpdir=$(mktemp -d --suffix=_afniplot)
echo "...copy standard"
run "cp $(scriptpath)/standard_0.5mm_head.nii.gz ${tmpdir}/underlay.nii.gz"
echo "...copy input file"
run "cp ${origfile} ${tmpdir}/orig.nii.gz"
indir=$tmpdir

echo "changing directories"
run "cd ${indir}"

echo "process inputs to have min at 0"
run "3dcalc -a orig.nii.gz -expr '(a-$thresh)*step(a-$thresh)' -prefix pos.nii.gz"
run "3dcalc -a orig.nii.gz -expr '(-1*a-$thresh)*step(-1*a-$thresh)' -prefix neg.nii.gz"
run "3dcalc -a pos.nii.gz -b neg.nii.gz -expr 'a-b' -prefix overlay.nii.gz"


###
# Load
###

echo
echo "starting afni"
run "afni -niml -yesplugouts &"
run "sleep 5"

echo "load data"
run "plugout_drive -com 'SWITCH_UNDERLAY underlay.nii.gz' \
              -com 'SWITCH_OVERLAY overlay.nii.gz' \
              -com 'SEE_OVERLAY +' \
              -quit"
run "sleep 1"

echo "set the threshold"
run "plugout_drive -com 'SET_PBAR_ALL A.-99 1.0 Spectrum:yellow_to_cyan+gap' \
              -com 'SET_THRESHOLD A.0 0.0' \
              -quit"
run "sleep 1"

echo "set the origin"
run "plugout_drive -com 'SET_DICOM_XYZ A -37 51 45' -quit"
run "sleep 1"

echo "close all the windows"
run "plugout_drive -com 'CLOSE_WINDOW A.axialimage' \
              -com 'CLOSE_WINDOW A.sagittalimage' \
              -com 'CLOSE_WINDOW A.coronalimage' \
              -quit"
run "sleep 2"


###
# Screenshots
###

# AXIAL
echo
echo "axial - set origin"
run "plugout_drive -com 'SET_DICOM_XYZ A 0 51 45' -quit"
run "sleep 1"

echo "axial - slices"
run "plugout_drive -com 'SET_XHAIRS A.OFF' \
              -com 'OPEN_WINDOW A.axialimage geom=600x600+0+0 mont=5x2:25' \
              -com 'SAVE_JPEG A.axialimage ${outprefix}_axial_slices.jpg' \
              -quit"
run "sleep 1"

echo "axial - reference sagittal"
run "plugout_drive -com 'SET_XHAIRS A.AP' \
              -com 'OPEN_WINDOW A.sagittalimage geom=600x600+600+0' \
              -com 'SAVE_JPEG A.sagittalimage ${outprefix}_axial_ref.jpg' \
              -quit"
run "sleep 1"

echo "close all the windows"
run "plugout_drive -com 'CLOSE_WINDOW A.axialimage' \
              -com 'CLOSE_WINDOW A.sagittalimage' \
              -com 'CLOSE_WINDOW A.coronalimage' \
              -quit"
run "sleep 2"

# SAGITTAL
echo
echo "sagittal - set the origin"
run "plugout_drive -com 'SET_DICOM_XYZ A -37 0 45' -quit"
run "sleep 1"

echo "sagittal slices"
run "plugout_drive -com 'SET_XHAIRS A.OFF' \
              -com 'OPEN_WINDOW A.sagittalimage geom=600x600+0+0 mont=5x2:29' \
              -com 'SAVE_JPEG A.sagittalimage ${outprefix}_sagittal_slices.jpg' \
              -quit"
run "sleep 1"

echo "sagittal - reference coronal"
run "plugout_drive -com 'SET_XHAIRS A.IS' \
              -com 'OPEN_WINDOW A.coronalimage geom=600x600+600+0' \
              -com 'SAVE_JPEG coronalimage ${outprefix}_sagittal_ref.jpg' \
              -quit"
run "sleep 1"

echo "close all the windows"
run "plugout_drive -com 'CLOSE_WINDOW A.axialimage' \
              -com 'CLOSE_WINDOW A.sagittalimage' \
              -com 'CLOSE_WINDOW A.coronalimage' \
              -quit"
run "sleep 2"

# CORONAL
echo
echo "coronal - set the origin"
run "plugout_drive -com 'SET_DICOM_XYZ A -37 51 0' -quit"
run "sleep 1"

echo "coronal slices"
run "plugout_drive -com 'SET_XHAIRS A.OFF' \
              -com 'OPEN_WINDOW A.coronalimage geom=600x600+0+0 mont=5x2:29' \
              -com 'SAVE_JPEG A.coronalimage ${outprefix}_coronal_slices.jpg' \
              -quit"
run "sleep 1"

echo "coronal - reference axial"
run "plugout_drive -com 'SET_XHAIRS A.LR' \
              -com 'OPEN_WINDOW A.axialimage geom=600x600+600+0' \
              -com 'SAVE_JPEG A.axialimage ${outprefix}_coronal_ref.jpg' \
              -quit"
run "sleep 1"

echo "close all the windows"
run "plugout_drive -com 'CLOSE_WINDOW A.axialimage' \
              -com 'CLOSE_WINDOW A.sagittalimage' \
              -com 'CLOSE_WINDOW A.coronalimage' \
              -quit"
run "sleep 2"

echo "save the threshold value"
run "echo '${thresh}' > ${outprefix}_threshold.txt"


# QUIT
echo
echo "quit"
run "plugout_drive -com 'QUIT' -quit"

echo "clean"
run "cd -"
run "rm -r ${tmpdir}"
