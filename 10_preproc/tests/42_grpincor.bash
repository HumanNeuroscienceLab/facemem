#!/usr/bin/env bash

## To run:
## cd /mnt/nfs/psych/faceMemoryMRI/analysis/groups/Questions/instacor

fname="func_concat"

# AFNI
method="afni"
3dGroupInCorr -setA ${fname}_bio_${method}.grpincorr.niml -setB ${fname}_phys_${method}.grpincorr.niml -labelA bio -labelB phys -paired -seedrad 6 -np 2000
afni -niml -np 2000

# FSL
method="fsl"
3dGroupInCorr -setA ${fname}_bio_${method}.grpincorr.niml -setB ${fname}_phys_${method}.grpincorr.niml -labelA bio -labelB phys -paired -seedrad 6 -np 4000
afni -niml -np 4000



method="fsl"
fname="func_concat_mc"
3dGroupInCorr -setA ${fname}_bio_${method}.grpincorr.niml -setB ${fname}_phys_${method}.grpincorr.niml -labelA bio -labelB phys -paired -seedrad 6 -np 2000
afni -niml -np 2000

method="fsl"
fname="func_concat_mc_compcor_sim"
3dGroupInCorr -setA ${fname}_bio_${method}.grpincorr.niml -setB ${fname}_phys_${method}.grpincorr.niml -labelA bio -labelB phys -paired -seedrad 6 -np 4000
afni -niml -np 4000

# TODO: try the mc_compcor_top5
# The two appear very similar but I want some way to determin the significance of the effects.
# Maybe one approach is to take the peaks of activity from the task
# and then do a SCA analysis to get which one leads to more robust differences?
