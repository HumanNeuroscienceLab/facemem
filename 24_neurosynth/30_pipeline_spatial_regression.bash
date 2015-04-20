#!/usr/bin/env bash

# Runs through everything (after ri_maps is made)

function run() {
  echo
  echo "======="
  echo "$@"
  eval "$@"
  return $?
}


## First set
#run "./12_maps_to_native_space.bash ri_maps_01"
#run "./14_temporal_regression.bash ri_maps_01"
#run "./20_task.bash ri_maps_01"
#run "./22_group_task.bash ri_maps_01"
#run "./24_format_group_output.R ri_maps_01"

## Second set
#name="ri_face_scene"
#run "./12_maps_to_native_space.bash ${name}"
#run "./14_spatial_regression.bash $name"
#run "./20_task.bash $name"
#run "./22_group_task.bash $name"
#run "./24_format_group_output.R $name"

## Third set
#name="ri_face_vs_scene"
#./12_maps_to_native_space.bash ${name}
#./14_spatial_regression.bash $name
#./20_task.bash $name
#./22_group_task.bash $name
#./24_format_group_output.R $name

## Fourth set
name="prob_face_vs_scene"
./30_pipeline_spatial_regression_worker.bash $name

## Fifth set
name="ri_sensory"
./30_pipeline_spatial_regression_worker.bash $name

## Sixth set
name="ri_memory"
./30_pipeline_spatial_regression_worker.bash $name
