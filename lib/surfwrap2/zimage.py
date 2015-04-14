#!/usr/bin/env python

import os
from os import path
import Image, ImageChops
from glob import glob

from rpy2 import robjects
from rpy2.robjects.packages import importr

def crop(fpath):
    """will crop the image and overwrite with cropped version"""
    im = Image.open(fpath)
    im = im.convert("RGBA")
    bg = Image.new("RGBA", im.size, (255,255,255,255))
    diff = ImageChops.difference(im,bg)
    bbox = diff.getbbox()
    im2 = im.crop(bbox)
    im2.save(fpath)
    return

def montage(oprefix, compilation="stick"):
    """
    this will put together the lh/rh med/lat images
    (for now we'll leave the ven surface all alone...)
    
    compilation: can be stick (1x4) or box (2x2)
    """
    print "montage"
    
    # pre-reqs
    jpeg = importr('jpeg')
    r = robjects.r
    
    # R functions for creating the montage
    r.source(path.join(path.dirname(__file__), "montage_functions.R"))
    surfer_montage_coords = robjects.globalenv["surfer_montage_coords"]
    surfer_montage_dims = robjects.globalenv["surfer_montage_dims"]
    surfer_montage_viz = robjects.globalenv["surfer_montage_viz"]
    
    # Files ordered for proper display
    if compilation == "stick":
        order_views = [ "lh_lat", "lh_med", "rh_med", "rh_lat" ]
    elif compilation == "box":
        order_views = [ "lh_lat", "lh_med", "rh_lat", "rh_med" ]
    elif compilation == "uni_lh":
        order_views = [ "lh_lat", "lh_med" ]
    fpaths = [ "%s_%s.jpg" % (oprefix,ov) for ov in order_views ]
    
    # Read in images
    images = r.lapply(fpaths, jpeg.readJPEG)
    
    # Get coordinates on montage of multiple images
    if compilation == "stick":
        scalings = robjects.FloatVector([1,0.95,0.95,1])
        coords = surfer_montage_coords(images, 1, 4, scalings, 12)
    elif compilation == "box":
        scalings = robjects.FloatVector([1,0.96,1,0.96])
        coords = surfer_montage_coords(images, 2, 2, scalings, 24, 12)
    elif compilation == "uni_lh":
        scalings = robjects.FloatVector([1,0.95])
        coords = surfer_montage_coords(images, 1, 2, scalings, 12)
    
    # Plot and save montage
    outdir  = path.dirname(oprefix)
    outbase = path.basename(oprefix)
    ofile   = "%s/montage-%s_%s.png" % (outdir, compilation, outbase)
    r.png(ofile, width=coords[6], height=coords[7])
    surfer_montage_viz(images, coords)
    r["dev.off"]()
    
    print "...see %s" % ofile