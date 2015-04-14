#!/usr/bin/env python

# This script will simply test the size of different mask sizes

import nibabel as nib
import numpy as np
from surfer import Brain

import os
#os.environ['SUBJECTS_DIR'] = "/mnt/nfs/share/freesurfer/current/subjects"
os.environ['SUBJECTS_DIR'] = "/Users/Shared/freesurfer/subjects"

from y_io import project_volume_data


#--- PATHS/SETUP ---#

basedir = "/mnt/nfs/psych/faceMemoryMRI"
runtype = "Questions"
lruntype = "questions"

indir = "%s/analysis/groups/%s/task/%s_task_smoother.mema/easythresh" % (basedir, runtype, lruntype)
infile = "%s/thresh_zstat_bio_vs_phys.nii.gz" % indir

indir2 = "%s/analysis/groups/%s/task/%s_task_smoother.mema" % (basedir, runtype, lruntype)
infile2 = "%s/zstats_bio_gt_phys.nii.gz" % indir2

outdir = "%s/figures/fig02_task_activity" % basedir
oprefix = "%s/%s_surface" % (outdir, lruntype)

min_val = 1.96
outprefix = "tmp"

#if outprefix is None:
#    if not os.path.exists('pics'): os.mkdir('pics')
#    outprefix = 'pics/%s' % infile.replace('.nii.gz', '_surface')


#--- LOADING DATA ---#

# First try to get the cluster mask (make the thresh file into a cluster)
from tempfile import mkstemp
_,clfile = mkstemp(suffix='.nii.gz', prefix='tmp_cluster_file')
os.system("3dcalc -overwrite -a %s -expr 'step(abs(a))' -prefix %s" % (infile, clfile))

cl1 = project_volume_data(clfile, "lh", subject_id='mni152', 
                                smooth_fwhm=0, target_subject='cvs_avg35_inMNI152',
                                verbose=2, interp='nearest')

cl2 = project_volume_data(clfile, "lh", subject_id='mni152', 
                                smooth_fwhm=0, target_subject='cvs_avg35_inMNI152', 
                                verbose=2, interp='trilinear')

orig1 = project_volume_data(infile2, "lh", subject_id='mni152', 
                                smooth_fwhm=0, target_subject='cvs_avg35_inMNI152', 
                                verbose=2, interp='nearest', projsum='avg')
orig2 = project_volume_data(infile2, "lh", subject_id='mni152', 
                                smooth_fwhm=0, target_subject='cvs_avg35_inMNI152', 
                                verbose=2, interp='trilinear', projsum='avg')

thr1 = project_volume_data(infile, "lh", subject_id='mni152', 
                                smooth_fwhm=0, target_subject='cvs_avg35_inMNI152', 
                                verbose=2, interp='nearest', projsum='avg')
thr2 = project_volume_data(infile, "lh", subject_id='mni152', 
                                smooth_fwhm=0, target_subject='cvs_avg35_inMNI152', 
                                verbose=2, interp='trilinear', projsum='avg')


#--- CHECKING FILE SIZES ---#

# cluster
(cl1>=0.5).sum()
(cl2>=0.5).sum()
# threshold
(np.abs(thr1)>min_val).sum()
(np.abs(thr2)>min_val).sum()
# combo
((cl1>=0.5) & (np.abs(orig1)>1.96)).sum()
((cl1>=0.5) & (np.abs(orig2)>1.96)).sum()
