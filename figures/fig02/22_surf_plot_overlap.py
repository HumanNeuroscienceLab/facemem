#!/usr/bin/env python

# Calculates the overlap in surface space for Q/NoQ
# and then plots

import nibabel as nib
import numpy as np
from glob import glob
from surfer import Brain

import os
#os.environ['SUBJECTS_DIR'] = "/mnt/nfs/share/freesurfer/current/subjects"
os.environ['SUBJECTS_DIR'] = "/Users/Shared/freesurfer/subjects"

import sys
sys.path.append("/mnt/nfs/psych/faceMemoryMRI/scripts/connpaper/lib/surfwrap2")
from zio import project_thresholded_data, load_afni_colors
from zimage import crop, montage

#--- loads and sets up the data first ---#

basedir  = "/mnt/nfs/psych/faceMemoryMRI"
outdir   = "%s/figures/fig02_task_activity" % basedir
oprefix  = "%s/overlap_conjunction_surface" % (outdir)

runtypes = ["Questions", "NoQuestions"]
hemis    = ["lh","rh"]
views    = ['lat','med','ven']

for hemi in hemis:
    print "hemi: %s" % hemi
    
    # compile zstats for each runtype
    zstats = {}
    
    for runtype in runtypes:
        #runtype = "NoQuestions"
        lruntype = runtype.lower()
        print "runtype: %s" % runtype
    
        #--- PATHS/SETUP ---#
    
        print "=== SETUP ==="
    
        indir = "%s/analysis/groups/%s/task/%s_task_smoother.mema/easythresh" % (basedir, runtype, lruntype)
        thr_file = "%s/thresh_zstat_bio_vs_phys.nii.gz" % indir

        indir2 = "%s/analysis/groups/%s/task/%s_task_smoother.mema" % (basedir, runtype, lruntype)
        raw_file = "%s/zstats_bio_gt_phys.nii.gz" % indir2
        
        #if outprefix is None:
        #    if not os.path.exists('pics'): os.mkdir('pics')
        #    outprefix = 'pics/%s' % infile.replace('.nii.gz', '_surface')
        
        #--- LOADING DATA ---#
        
        print "=== LOADING ==="
        
        zstat = project_thresholded_data(raw_file, thr_file, hemi, subject_id='mni152', 
                                            target_subject='fsaverage', verbose=2)
        zstats[lruntype] = zstat
    
    # combine the data here
    zstat = ((zstats['questions']!=0) & (zstats['noquestions']!=0))*1

    # min-val
    min_val = 0.01
    max_val = 1
    #dat     = nib.load(thr_file).get_data()
    #max_val = np.abs(dat).max().round(2)
    
    #--- PLOT/SAVE DATA ---#

    print "=== PLOTTING ==="

    # i think this needs to be done in a seprate file?
    # Start the brain process
    brain = Brain("fsaverage", hemi, "iter10_inflated", config_opts={"background":"white"})
    
    # Add the overlay
    brain.add_overlay(zstat, min=min_val, max=max_val, name=hemi)
    
    # Change the overlay colors
    tmp = brain.overlays[hemi]
    tab = np.zeros((256,4))
    tab[:,3] = 255
    if hasattr(tmp, 'pos_bar'):            
        tab[:,0] = 237
        tab[:,1] = 0
        tab[:,2] = 16
        tmp.pos_bar.lut.table = tab
    if hasattr(tmp, 'neg_bar'):
        tab[:,0] = 94
        tab[:,1] = 79
        tab[:,2] = 162
        tmp.neg_bar.lut.table = tab
    
    # Refresh
    brain.show_view("lat")
    brain.hide_colorbar()
    
    # Save the beauts
    brain.save_imageset("%s_%s" % (oprefix, hemi), views, 
                        'jpg', colorbar=None)
    
    # End
    #brain.close()
    
    
#--- CROP/COMBINE IMAGES ---#

print "=== CROPPING ==="

outpaths = glob("%s_*.jpg" % oprefix)
for fpath in outpaths:
    print "\t%s" % fpath
    crop(fpath)

print "=== CREATE MONTAGE ==="

montage(oprefix, compilation="box")
