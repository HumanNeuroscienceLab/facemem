import os, sys
from os import path as op
import tempfile
import numpy as np
import nibabel as nib
import Image, ImageChops
from process import Process

from rpy2 import robjects
from rpy2.robjects.packages import importr

from surfer import Brain, io

def vol_to_surf(infile, outprefix=None, interp="trilinear", hemis=["lh", "rh"]):
    """
    Transforms a volume from MNI to CVS avg35 space.
    
    Parameters
    ----------
    infile : str
    outprefix : str or None (default: None)
        When outfile is None, the path will be autogenerated using tmpfile.
        The suffix of the file will be the hemi and .nii.gz.
    interp : str (default: trilinear)
        Can be 'nearest' or 'trilinear'.
    hemis : list (default: ['lh', 'rh'])
    
    Returns
    --------
    outfiles : dict
        For instance: `{'lh': 'file1', 'rh': 'file2'}`.
    outsurfs : dict
        For instance: `{'lh': surf_lh, 'rh': surf_rh}` where surf_* is an 
        `ndarray`.
    """
    
    if not op.exists(infile):
        raise Exception("Input for vol_to_surf '%s' doesn't exist" % infile)
    if outprefix is None:
        to_clean    = True
        _,outprefix = tempfile.mkstemp()
    else:
        to_clean    = False
    outfiles = {}
    outsurfs = {}
    
    templ_vars = dict(input=infile, interp=interp)
    for hemi in hemis:
        outfile = "%s_%s.nii.gz" % (outprefix, hemi)
        outfiles[hemi] = outfile
        
        templ_vars["hemi"]   = hemi
        templ_vars["output"] = outfile
        
        cmd = "mri_vol2surf --mov %(input)s \
        --regheader mni152 --trgsubject 'cvs_avg35_inMNI152' \
        --projfrac-max 0 1 0.1 \
        --interp %(interp)s --hemi %(hemi)s \
        --out %(output)s --reshape" % templ_vars
        
        print cmd
        p = Process(cmd)
        print p.stdout
        print p.stderr
        if p.retcode != 0:
            raise Exception("mri_vol2surf failed")
        
        outsurfs[hemi] = io.read_scalar_data(outfile)
    
    if to_clean:
        os.remove(outprefix)
    
    return (outfiles, outsurfs)

def remove_surfs(surf_files):
    for k,v in surf_files.iteritems():
        os.remove(v)
    return

def fsaverage(hemi, inflation=8, cortex='classic', background="white", 
              opts={}, subjects_dir="/home2/data/PublicProgram/freesurfer"):
    """
    Brings up the fsaverage semi-inflated underlay.
    
    Parameters
    ----------
    inflation : int
        The degree to inflate the brain.
    cortex : str (default: classic)
        choices are classic, bone, high_contrast, and low_contrast
    background : str (default: white)
        any color
    opts : dict (config_opts)
        - size: size of window (positive number)
        - default_view: lateral, medial, etc
    subjects_dir : str (default: /home2/data/PublicProgram/freesurfer)
    
    Returns
    -------
    brain : pysurfer.Brain?
        Pysurfer object
    """
    
    subject_id  = "fsaverage_copy"
    surf        = "iter%i_inflated" % inflation
    config_opts = {
        "background": background, 
        "cortex": cortex
    }
    config_opts.update(opts)
    
    brain = Brain(subject_id, hemi, surf, \
                  config_opts=config_opts, \
                  subjects_dir=subjects_dir)
    
    return brain


def cvs_avg35(hemi, inflation=0, cortex='classic', background="white", 
              opts={}, subjects_dir="/home2/data/PublicProgram/freesurfer"):
    """
    Brings up the fsaverage semi-inflated underlay.
    
    Parameters
    ----------
    inflation : int
        The degree to inflate the brain (don't change for now)
    cortex : str (default: classic)
        choices are classic, bone, high_contrast, and low_contrast
    background : str (default: white)
        any color
    opts : dict (config_opts)
        - size: size of window (positive number)
        - default_view: lateral, medial, etc
    subjects_dir : str (default: /home2/data/PublicProgram/freesurfer)
    
    Returns
    -------
    brain : pysurfer.Brain?
        Pysurfer object
    """
    
    subject_id  = "cvs_avg35_inMNI152"
    if inflation == 0:
        surf        = "inflated"
    else:
        surf        = "iter%i_inflated" % inflation
    config_opts = {
        "background": background, 
        "cortex": cortex
    }
    config_opts.update(opts)
    
    brain = Brain(subject_id, hemi, surf, \
                  config_opts=config_opts, \
                  subjects_dir=subjects_dir)
    
    return brain



def load_colorbar(cbar):
    """
    Loads a ndarray that has the appropriate dims and vals for pysurfer so 
    256x4 dimensions.
    
    This function will try to warp the input color scale to fit 256 colors.
    
    Parameters
    ----------
    cbar : str or numpy.ndarray
        When `str`, assumes that it is a filename with and loads that array 1st.
        
    Returns
    -------
    lut : numpy.ndarray
        A 256 x 4 dim matrix. The first 3 columns are rgb and the 4th is alpha.
    """
    if isinstance(cbar, str):
        cbar = np.loadtxt(cbar)
        if cbar.shape[1] == 3:
            cbar = np.vstack((cbar.T, np.repeat(255,cbar.shape[0]))).T
    
    if not isinstance(cbar, np.ndarray):
        raise Exception("unrecognized type %s for cbar" % type(cbar))
    
    if cbar.shape[1] != 4:
        raise Exception("cbar array must have 4 columns for rgb and the alpha channel")
    
    # All good if right shape
    if cbar.shape[0] == 256:
        return cbar
    
    # Expand colors to fit 256 colors
    ncols     = cbar.shape[0]
    lut       = np.zeros((256,4))
    # If just 1, then everything is the same
    if cbar.shape[0] == 1:
        for i in range(256):
            lut[i,:] = cbar[:]
    # Otherwise, split 256 into equal parts
    else:
        steps     = range(0, 256, np.floor(256.0/ncols).astype('int'))
        if len(steps) == ncols:
            steps.append(256)
        steps[-1] = 256
        for i in range(ncols):
            lut[steps[i]:steps[i+1],:] = cbar[i,:]    
    
    return lut


def auto_minmax(volfile, min='auto', max='auto', sign='auto'):
    """
    Returns the min, max, and sign for the input dataset.
    
    Parameters
    ----------
    volfile : str
        Path to file with volume data
    
    Returns
    -------
    
    """
    
    if min == 'auto' or max == 'auto' or sign == 'auto':
        img = nib.load(volfile)
        data = img.get_data()
        data_max = data.max()
        if data_max == 0:
            data_min = data_max
        else:
            data_min = data[data.nonzero()].min()
        if max == 'auto': max = data_max
        if min == 'auto': min = data_min
        if sign == 'auto':
            if data_min < 0 and data_max > 0:
                sign = "abs"
            elif data_min > 0:
                sign = "pos"
            else:
                sign = "neg"
    
    return (min, max, sign)


def add_overlay(name, brain, surf_data, lut, min, max, sign):
    """
    Add surface data onto the brain.
    
    Parameters
    ----------
    name : str
    brain : pysurfer.Brain
    surf_data : numpy.ndarray
    lut : numpy.ndarray or str
        Matrix of 256x4 with color information or can be string like "Reds".
    min : float
    max : float
    sign : str
        Can be pos, neg, or abs
    
    Returns
    -------
    brain : pysurfer.Brain
    """
    if (sum(abs(surf_data)) > 0):
        # Add overlay
        brain.add_overlay(surf_data, name=name, min=min, max=max, sign=sign)
        # Update colorbar
        overlay = brain.overlays[name]
        if isinstance(lut, str):
            overlay.pos_bar.lut_mode = lut
        else:
            overlay.pos_bar.lut.table = lut # TODO: see if this pos_bar always works
        # Refresh
        brain.show_view("lat")
        brain.hide_colorbar()
    else:
        print "No data in %s" % name
    return brain

def save_imageset(brain, outprefix, hemi, views=["med", "lat"], otype='jpg', to_crop=True):
    """
    Saves set of images (maybe a bit redundant?)
    
    Parameters
    ----------
    brain : pysurfer.Brain
    outprefix : str
    hemi : str
        Can be 'lh' or 'rh'.
    views : list
        Different views to capture. TODO: add options.
    otype : str
        Output type (not sure about the options)
    cropify : bool
        Do you want to crop the output images?    
    """
    prefix = "%s_%s" % (outprefix, hemi)
    brain.save_imageset(prefix, views, otype, colorbar=None)
    if to_crop:
        for view in views: 
            ofile = "%s_%s.%s" % (prefix, view, otype)
            cropify(ofile)
    return

def cropify(inpath, outpath=None):
    """
    Crops the input image and overwrites it by default.
    Note that the background is assumed to be white.
    """
    if outpath is None:
        outpath = inpath
    # Read in image
    im = Image.open(inpath)
    im = im.convert("RGBA")
    # Create new all white image
    bg = Image.new("RGBA", im.size, (255,255,255,255))
    # What's the difference? Background or white regions should fall out.
    diff = ImageChops.difference(im,bg)
    # Ok now crop
    bbox = diff.getbbox()
    im2 = im.crop(bbox)
    # Save
    im2.save(outpath)

def montage(outprefix, compilation, otype='jpg'):
    """
    Creates a montage of the surfaces.
    
    Input and output file types are a bit messy. Fix!
    
    Parameters
    ----------
    outprefix : str
        This should be the basic path to your surface images. For instance,
        if your input is like /path/to/surf_lh_lat.jpg etc, then outprefix 
        should be /path/to/surf.
    compilation : str
        Can be stick (1x4), box (2x2), stick_lh, stick_rh, box_lh, box_rh (2x1)
    otype : jpg
        Usage here is specific 
    """
    
    # pre-reqs
    jpeg = importr('jpeg')
    read_image = jpeg.readJPEG
    r = robjects.r
    
    # R functions for creating the montage
    try:
        funcdir = op.dirname(__file__)
    except NameError:
        funcdir = "/home2/data/Projects/CWAS/share/lib/surfwrap"
    r.source(op.join(funcdir, "montage_functions.R"))
    surfer_montage_coords = robjects.globalenv["surfer_montage_coords"]
    surfer_montage_dims = robjects.globalenv["surfer_montage_dims"]
    surfer_montage_viz = robjects.globalenv["surfer_montage_viz"]
    
    # Files ordered for proper display
    if compilation == "horiz" or compilation == "vert":
        order_views = [ "lh_lat", "lh_med", "rh_med", "rh_lat" ]
    elif compilation == "box":
        order_views = [ "lh_lat", "lh_med", "rh_lat", "rh_med" ]
    elif compilation == "horiz_lh" or compilation == "vert_lh":
        order_views = [ "lh_lat", "lh_med" ]
    elif compilation == "horiz_rh" or compilation == "vert_rh":
        order_views = [ "rh_lat", "rh_med" ]
    elif compilation == "horiz_lh_inverse" or compilation == "vert_lh_inverse":
        order_views = [ "lh_med", "lh_lat" ]
    elif compilation == "horiz_rh_inverse" or compilation == "vert_rh_inverse":
        order_views = [ "rh_med", "rh_lat" ]
    else:
        raise Exception("unknown compilation %s" % compilation)
    fpaths = [ "%s_%s.%s" % (outprefix, ov, otype) for ov in order_views ]
    
    # Read in images
    images = r.lapply(fpaths, read_image)
    
    # Get coordinates on montage of multiple images
    if compilation == "horiz":
        scalings = robjects.FloatVector([1,0.95,0.95,1])
        coords = surfer_montage_coords(images, 1, 4, scalings, 12)
    elif compilation == "vert":
        scalings = robjects.FloatVector([1,0.95,0.95,1])
        coords = surfer_montage_coords(images, 4, 1, scalings, 12)
    elif compilation == "box":
        scalings = robjects.FloatVector([1,0.96,1,0.96])
        coords = surfer_montage_coords(images, 2, 2, scalings, 24, 12)
    elif compilation == "horiz_lh" or compilation == "horiz_rh":
        scalings = robjects.FloatVector([1,0.95])
        coords = surfer_montage_coords(images, 1, 2, scalings, 12)
    elif compilation == "horiz_lh_inverse" or compilation == "horiz_rh_inverse":
        scalings = robjects.FloatVector([0.95,1])
        coords = surfer_montage_coords(images, 1, 2, scalings, 12)
    elif compilation == "vert_lh" or compilation == "vert_rh":
        scalings = robjects.FloatVector([1,0.96])
        coords = surfer_montage_coords(images, 2, 1, scalings, 12)
    elif compilation == "vert_lh_inverse" or compilation == "vert_rh_inverse":
        scalings = robjects.FloatVector([0.96,1])
        coords = surfer_montage_coords(images, 2, 1, scalings, 12)
    
    # Plot and save montage
    outdir  = op.dirname(outprefix)
    outbase = op.basename(outprefix)
    ofile   = "%s/montage-%s_%s.png" % (outdir, compilation, outbase)
    r.png(ofile, width=coords[6], height=coords[7])
    surfer_montage_viz(images, coords)
    r["dev.off"]()
    
    print "...see %s" % ofile
    
    return
    
    