#!/usr/bin/env python

# This script will visualize the task effects onto the fsaverage brain
# It will transform the MNI152 brain to fsaverage space

import os
import argparse

# parse user arguments
parser = argparse.ArgumentParser()
parser.add_argument('-i', '--infile', required=True)
parser.add_argument('-t', '--thresh', default=1.96)
parser.add_argument('-o', '--outprefix')

import nibabel as nib
import numpy as np
from surfer import Brain, project_volume_data

# wrapper function
def plot_surface_data(infile, min_val, outprefix=None):
    if outprefix is None:
        if not os.path.exists('pics'): os.mkdir('pics')
        outprefix = 'pics/%s' % infile.replace('.nii.gz', '_surface')
    
    # read in data
    zstat_lh = project_volume_data(infile, "lh", subject_id='mni152', 
                                    smooth_fwhm=0, target_subject='cvs_avg35_inMNI152', verbose=2)
    zstat_rh = project_volume_data(infile, "rh", subject_id='mni152', 
                                    smooth_fwhm=0, target_subject='cvs_avg35_inMNI152', verbose=2)

    # max threshold
    voldat = nib.load(infile).get_data()
    voldat = voldat[np.nonzero(voldat)]
    max_val= round(np.abs(voldat).max(), 1)

    # plot
    brain = Brain("cvs_avg35_inMNI152", "lh", "inflated")
    brain.add_overlay(zstat_lh, min=min_val, max=max_val, name="one")
    brain.save_montage("%s_lh.png" % outprefix)
    brain.close()

    brain = Brain("cvs_avg35_inMNI152", "rh", "inflated")
    brain.add_overlay(zstat_rh, min=min_val, max=max_val, name="one")
    brain.save_montage("%s_rh.png" % outprefix)
    brain.close()
    
    return

# So now I want to make this be scriptable from the command-line
# I'm struggling a little bit here with improving on this code.
if __name__ == "__main__":
    args = parser.parse_args()
    plot_surface_data(args.infile, args.thresh, args.outprefix)