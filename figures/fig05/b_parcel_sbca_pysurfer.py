#!/usr/bin/env python

# This script will simply test the size of different mask sizes

import nibabel as nib
import numpy as np
from glob import glob
from surfer import Brain

import os
#os.environ['SUBJECTS_DIR'] = "/mnt/nfs/share/freesurfer/current/subjects"
os.environ['SUBJECTS_DIR'] = "/Users/Shared/freesurfer/subjects"

import sys
sys.path.append("/mnt/nfs/psych/faceMemoryMRI/scripts/connpaper/lib/surfwrap2")
from zio import project_volume_data, project_thresholded_data, load_afni_colors
from zimage import crop, montage


#--- PATHS/SETUP ---#

print "=== SETUP ==="

region = "parcels_group_localizer_n0658"
basedir = "/mnt/nfs/psych/faceMemoryMRI"
#runtypes = ["Questions", "NoQuestions"]
runtypes = ["Questions"]
for runtype in runtypes:
    print '---'
    print 'runtype: %s' % runtype
    #runtype = "NoQuestions"
    lruntype = runtype.lower()

    indir = "%s/analysis/groups/%s/cmaps/ts_%s_bootstrap+perms.sca" % (basedir, runtype, region)
    raw_file = "%s/summary_bio_vs_phys.nii.gz" % indir
    thr_file = "%s/thresh_summary_bio_vs_phys.nii.gz" % indir

    outdir = "%s/figures/fig05_sbca" % basedir
    oprefix = "%s/%s_surface" % (outdir, lruntype)

    views = ['lat','med','ven']
    
    #if outprefix is None:
    #    if not os.path.exists('pics'): os.mkdir('pics')
    #    outprefix = 'pics/%s' % infile.replace('.nii.gz', '_surface')
    
    
    #--- LOADING DATA ---#

    print "=== LOADING ==="

    min_val = 1.96
    dat     = nib.load(thr_file).get_data()
    max_val = np.abs(dat).max().round(1)
    
    
    #--- PLOT/SAVE DATA ---#
    
    print "=== PLOTTING ==="

    hemis = ["lh","rh"]
    for hemi in hemis:
        # smoothing just a little and using projsum avg seems to give 
        # slightly nicer looking and more robust results (robust in the 
        # sense that it better reflects gist of what you see in vol space)
        zstat = project_thresholded_data(thr_file, thr_file, hemi, 
                                         subject_id='mni152', target_subject="fsaverage", 
                                         interp='nearest', smooth_fwhm=0, verbose=2)
        
        # i think this needs to be done in a seprate file?
        # Start the brain process
        brain = Brain("fsaverage", hemi, "iter10_inflated", config_opts={"background":"white"})

        # Add the overlay
        brain.add_overlay(zstat, min=min_val, max=max_val, name=hemi)

        # Change the overlay colors
        tmp = brain.overlays[hemi]
        if hasattr(tmp, 'pos_bar'):
            tmp.pos_bar.lut.table = load_afni_colors("yellow-cyan-gap_pos")
        if hasattr(tmp, 'neg_bar'):
            tmp.neg_bar.lut.table = load_afni_colors("yellow-cyan-gap_neg")
        
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
