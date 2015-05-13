import os
from surfer import Brain

subject_id = "fsaverage"
subjects_dir = os.environ["SUBJECTS_DIR"]

brain = Brain(subject_id, "both", "iter10_inflated")

coords_lh = [
  [-44.00,     -82.00,    -10.00],    # L OFA
  [-40.00,     -50.00,    -18.00],    # L FFA
  [-42.00,     -28.00,    -20.00],    # L ATL-post
#  [-34.00,      -6.00,    -34.00]     # L ATL-ant
  ]
brain.add_foci(coords_lh, map_surface="white", color="gold", hemi='lh', name="es_seeds")

coords_rh = [
  [42.00,     -78.00,    -10.00],     # R OFA
  [42.00,     -50.00,    -20.00],     # R FFA
  [44.00,     -28.00,    -22.00],     # R ATL-post
#  [32.00,      -2.00,    -36.00]      # R ATL-ant
  ]
brain.add_foci(coords_rh, map_surface="white", color="gold", hemi='rh', name="es_seeds")

brain.show_view("ven")
brain.save_image("/Users/czarrar/Dropbox/Research/facemem/paper/figures/fig_03/fsaverage_show_rois.png")
