#!/usr/bin/env bash

# This script will combine the trial timings across all runs, mainly for AFNI.
# - question runs
# - no-question runs
# - localizer runs.

studydir=/mnt/nfs/psych/faceMemoryMRI

indir="${studydir}/scripts/timing"
outdir="$indir"

#subjects=($(cd /mnt/nfs/psych/faceMemoryMRI/analysis/subjects; ls -d tb*))
subjects=(tb9737)
runtype=(Questions NoQuestions Localizer)
runtype_short=(withQ noQ FaceLoc)
trial_short=(bio phys)

# look at other bashscript for this
#for (( i = 1; i <= $nruns; i++ )); do
#    echo "" > $outfile
#    line=$(awk '{print $1}' ../../../command/timing/faceMemory01_tb9226_Questions_run01_bio | 1dtranspose - -)
#    echo $line >> $outfile
#done


for (( s = 0; s < ${#subjects[@]}; s++ )) do
	subj=${subjects[$s]}
    echo "=== subject ${subj} ==="

	for rt in 1 2; do
        echo "=== task ${runtype[rt-1]} ==="
        
        for ts in 1 2; do
            echo "=== trial ${trial_short[ts-1]} ==="
            
            outfile="${outdir}/allruns_faceMemory01_${subj}_${runtype[rt-1]}_${trial_short[ts-1]}"
			if [ -e $outfile ]; then
	      		echo "$outfile exists. skip..."
	      		continue
	    	fi
            
            echo "...combining timing files"
            echo -n "" > $outfile
            
	    if [ -e ${indir}/faceMemory01_${subj}_${runtype[rt-1]}_run04_${trial_short[ts-1]} ]; then

    	    	for rr in 01 02 03 04; do
                	echo "=== run ${rr} ==="

                	infile="${indir}/faceMemory01_${subj}_${runtype[rt-1]}_run${rr}_${trial_short[ts-1]}"
                
               		 if [ ! -e $infile ]; then 
                 	   echo "$infile does not exist. skip..."
                	    rm ${outfile} 2> /dev/null
                	    continue
               		 fi
                		
              	 	 line=$(awk '{print $1}' ${infile} | 1dtranspose - -)
               		 echo $line >> $outfile
    			done

	    else
		for rr in 01 02 03; do
                	echo "=== run ${rr} ==="

                	infile="${indir}/faceMemory01_${subj}_${runtype[rt-1]}_run${rr}_${trial_short[ts-1]}"
                
               		 if [ ! -e $infile ]; then 
                 	   echo "$infile does not exist. skip..."
                	    rm ${outfile} 2> /dev/null
                	    continue
               		 fi
                		
              	 	 line=$(awk '{print $1}' ${infile} | 1dtranspose - -)
               		 echo $line >> $outfile
    			done


	      fi
		
            
            echo "changing permissions"
            chmod -R 775 ${outfile}
            chgrp -R psych ${outfile}
        done
	done    
done

## each block runs for 11.5s
#indir="/mnt/nfs/share/Dropbox/ExpControl_Current/fMRI/facebodyhouse01/timing_files"
##outdir="$indir" # same outdir as above
#trial_short=(Body Face House)
#
#echo "=== task localizer ==="
#rt=3
#
#for ts in 1 2 3; do
#    echo "=== trial ${trial_short[ts-1]} ==="
#    
#    outfile="${outdir}/allruns_FaceBody01_${trial_short[ts-1]}.txt"
#	if [ -e $outfile ]; then
#  		echo "$outfile exists. skip..."
#  		continue
#	fi
#    
#    echo "...combining timing files"
#    echo -n "" > $outfile
#    
#    for rr in 01 02; do
#        echo "=== run ${rr} ==="
#
#        infile="${indir}/FaceBody01_${trial_short[ts-1]}_run${rr}.txt"
#        if [ ! -e $infile ]; then 
#            echo "$infile does not exist. skip..."
#            rm ${outfile} 2> /dev/null
#            continue
#        fi
#        
#        line=$(awk '{print $1}' ${infile} | 1dtranspose - -)
#        echo $line >> $outfile        
#    done
#    
#    echo "changing permissions"
#    chmod -R 775 ${outfile}
#    chgrp -R psych ${outfile}
#done    
