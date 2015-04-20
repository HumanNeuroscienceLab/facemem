# TODO
$FSLDIR/bin/fsl_glm -i $i -d $OUTPUT/dr_stage1_${s}.txt -o $OUTPUT/dr_stage2_$s --out_z=$OUTPUT/dr_stage2_${s}_Z --demean -m $OUTPUT/mask $DES_NORM ; \
$FSLDIR/bin/fslsplit $OUTPUT/dr_stage2_$s $OUTPUT/dr_stage2_${s}_ic" >> ${LOGDIR}/drC
