#!/usr/bin/env bash

if [[ $# -eq 0 ]]; then
  echo "usage: $0 roi-name (njobs)"
  exit 2
fi

name=$1
njobs=${2:-16}


function run() {
  echo
  echo "======="
  echo "$@"
  eval "$@"
  return $?
}

echo
echo "RUNNING $name"
echo
run "./12_maps_to_native_space.bash ${name} $njobs"
run "./14_spatial_regression.bash $name $njobs"
run "./20_task.bash $name $njobs"
run "./22_group_task.bash $name $njobs"
run "./24_format_group_output.R $name"
