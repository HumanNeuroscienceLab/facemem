# Extract time-series from parcels
3dROIstats -mask region_growing/parcels_relabel.nii.gz -quiet group_tconcat.nii.gz > group_parcel.1D
