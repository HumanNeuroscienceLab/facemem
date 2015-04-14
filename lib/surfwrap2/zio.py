#!/usr/bin/env python

import os
from os import path
from tempfile import mktemp

from subprocess import Popen, PIPE
import gzip
import numpy as np
import nibabel as nib
from nibabel.spatialimages import ImageFileError

import logging
logger = logging.getLogger('surfer')

from surfer.io import read_scalar_data

# THIS IS A VERY SLIGHTLY MODIFIED VERSION OF PYSURFER
# IT ALLOWS ME TO USE THE INTERP OPTION

def load_afni_colors(name, basepath=None):
    if basepath is None:
        basepath = path.abspath(path.join(path.dirname(__file__), "colorbars"))
    
    colorbar = np.loadtxt("%s/%s.txt" % (basepath, name))
    
    tmp = np.zeros((colorbar.shape[0],4))
    tmp[:,0:3] = colorbar
    tmp[:,3] = 255
    colorbar = tmp
    
    return colorbar

def project_thresholded_data(filepath, thr_filepath, hemi, thr_val=None, 
                             interp='trilinear', smooth_fwhm=0, **kwrds):
    """Will read in thresholded volume data onto cortical manifold.
    
    This will require both the thresholded data and unthreshold data.
    
    Steps include:
    1. Create a cluster binary mask of the absolute thresholded data
    2. Project the cluster mask data to surface with nearest
    3. Project the unthreshold (raw) data to surface with nearest and smoothing
    4. Threshold cluster mask by 0.5
    5. Threshold raw data by whatever value
    6. Take union of voxels for #4 & #5 using node values from #5
    
    Paramaters
    ----------
    filepath : string
        File with unthresholded (raw) data        
    thr_filepath : string
        File with thresholded data
    hemi : [lh, rh]
        Hemisphere target
    thr_val : bool
        Threshold value (by default it is inferred from the data)
    interp : string
        This will only be applied to raw_surf.
    smooth_fwhm : int
        This will only be applied to raw_surf.
    **kwrds : dict
        Other kewyords passed onto `project_volume_data`
    """
    
    from tempfile import mkstemp
    _,cl_filepath = mkstemp(suffix='.nii.gz', prefix='tmp_cluster_file')
    os.system("3dcalc -overwrite -a %s -expr 'step(abs(a))' -prefix %s" % (thr_filepath, cl_filepath))
    
    if thr_val is None:
        thr_dat = nib.load(thr_filepath).get_data()
        thr_val = np.abs(thr_dat[np.nonzero(thr_dat)]).min()
    
    cl_surf  = project_volume_data(cl_filepath, hemi, 
                                   interp='nearest', smooth_fwhm=0, 
                                   **kwrds)
    raw_surf = project_volume_data(filepath, hemi, 
                                   interp=interp, smooth_fwhm=smooth_fwhm, 
                                   **kwrds)
    
    thr_surf = ((cl_surf>=0.5) & (np.abs(raw_surf)>thr_val)) * raw_surf
    
    os.remove(cl_filepath)
    
    return thr_surf

def project_volume_data(filepath, hemi, reg_file=None, subject_id=None,
                        projmeth="frac", projsum="avg", projarg=[0, 1, .1],
                        surf="white", smooth_fwhm=3, mask_label=None,
                        target_subject=None, verbose=None, 
                        interp='trilinear'):
    """Sample MRI volume onto cortical manifold.
    Note: this requires Freesurfer to be installed with correct
    SUBJECTS_DIR definition (it uses mri_vol2surf internally).
    Parameters
    ----------
    filepath : string
        Volume file to resample (equivalent to --mov)
    hemi : [lh, rh]
        Hemisphere target
    reg_file : string
        Path to TKreg style affine matrix file
    subject_id : string
        Use if file is in register with subject's orig.mgz
    projmeth : [frac, dist]
        Projection arg should be understood as fraction of cortical
        thickness or as an absolute distance (in mm)
    projsum : [avg, max, point]
        Average over projection samples, take max, or take point sample
    projarg : single float or sequence of three floats
        Single float for point sample, sequence for avg/max specifying
        start, stop, and step
    surf : string
        Target surface
    smooth_fwhm : float
        FWHM of surface-based smoothing to apply; 0 skips smoothing
    mask_label : string
        Path to label file to constrain projection; otherwise uses cortex
    target_subject : string
        Subject to warp data to in surface space after projection
    verbose : bool, str, int, or None
        If not None, override default verbose level (see surfer.verbose).
    interp : string
        Should be nearest or trilinear (ADDED BY ZS)
    """
    # Set the basic commands
    cmd_list = ["mri_vol2surf",
                "--mov", filepath,
                "--hemi", hemi,
                "--surf", surf]

    # Specify the affine registration
    if reg_file is not None:
        cmd_list.extend(["--reg", reg_file])
    elif subject_id is not None:
        cmd_list.extend(["--regheader", subject_id])
    else:
        raise ValueError("Must specify reg_file or subject_id")

    # Specify the projection
    proj_flag = "--proj" + projmeth
    if projsum != "point":
        proj_flag += "-"
        proj_flag += projsum
    if hasattr(projarg, "__iter__"):
        proj_arg = map(str, projarg)
    else:
        proj_arg = [str(projarg)]
    cmd_list.extend([proj_flag] + proj_arg)

    # Set misc args
    if smooth_fwhm:
        cmd_list.extend(["--surf-fwhm", str(smooth_fwhm)])
    if mask_label is not None:
        cmd_list.extend(["--mask", mask_label])
    if target_subject is not None:
        cmd_list.extend(["--trgsubject", target_subject])
    cmd_list.extend(["--interp", interp])
    
    # Execute the command
    out_file = mktemp(prefix="pysurfer-v2s", suffix='.mgz')
    cmd_list.extend(["--o", out_file])
    logger.info(" ".join(cmd_list))
    p = Popen(cmd_list, stdout=PIPE, stderr=PIPE)
    stdout, stderr = p.communicate()
    out = p.returncode
    if out:
        raise RuntimeError(("mri_vol2surf command failed "
                            "with command-line: ") + " ".join(cmd_list))

    # Read in the data
    surf_data = read_scalar_data(out_file)
    os.remove(out_file)
    return surf_data