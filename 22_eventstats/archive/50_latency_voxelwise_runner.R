#!/usr/bin/env Rscript

datadir       <- "/mnt/nfs/psych/faceMemoryMRI/analysis/subjects"
timingdir     <- "/mnt/nfs/psych/faceMemoryMRI/scripts/timing"

subjects      <- as.character(read.table("../sublist_all.txt")[,])
runtypes      <- c("Questions", "NoQuestions")
conditions    <- c("bio","phys")

source("50_latency_voxelwise_worker.R")

# Now all the above is a lot of code. Can we create one function that runs all of this?
library(doMC)
registerDoMC(16)

tpts          <- -5:19
baseline.inds <- c(3,5)
overwrite     <- F

for (runtype in runtypes) {
  cat("\n===\n")
  cat(runtype, "\n")
  
  for (subject in subjects) {
    cat("subject:", subject, "\n")
    
    ## load data and timing
    cat("...load and read\n")
    dat           <- read_data(subject, runtype)
    nvoxs         <- ncol(dat$dat)
    trialtiming   <- get_trial_inds(dat$timing, tpts[1], tpts[length(tpts)])    
    
    ## save the average data and smoothed splines
    cat("...setup saving\n")
    ntpts         <- length(tpts)
    vox.avedat    <- lapply(1:length(conditions), function(i) big.matrix(ntpts, nvoxs, shared=T))
    new.tpts      <- seq(tpts[1], tpts[length(tpts)], by=0.2) # new tr of 0.2
    vox.smoothavedat <- lapply(1:length(conditions), function(i) big.matrix(length(new.tpts), nvoxs, shared=T))
    names(vox.avedat) <- conditions
    names(vox.smoothavedat) <- conditions
    
    ## process data
    cat("...process data\n")
    fiveperc      <- floor(nvoxs*0.05)
    vcparams      <- laply(1:nvoxs, function(vox) {
      if (!(vox %% fiveperc)) cat(floor(vox/nvoxs*100), "%...", sep="")
      cparams <- laply(1:length(conditions), function(ci) {
        cond          <- conditions[ci]
        trialdat      <- get_trial_data(dat$dat, trialtiming, vi=vox, 
                                        trials=which(trialtiming$condition==cond), 
                                        remove.baseline=T, baseline.inds=baseline.inds, 
                                        parallel=F)
        avedat        <- get_average(trialdat, tpts)
        smoothavedat  <- get_smoothed_average(trialdat, tpts)
        ## save average and smoothed curves
        vox.avedat[[ci]][,vox] <- avedat$ave
        vox.smoothavedat[[ci]][,vox] <- smoothavedat$ave
        
        ## get the params
        params        <- get_smoothed_params(smoothavedat, baseline.inds)
        ## tstat of peak
        peak.ind      <- smoothavedat$new.tpts==params[3]
        params        <- c(params, peak.tstat=smoothavedat$ave[peak.ind]/smoothavedat$se[peak.ind])
        ## return
        params
      })
      rownames(cparams) <- conditions
      cparams
    }, .parallel=T)
    cat("\n")
    
    cat("...selecting good voxels\n")
    # We want to get voxels with a reasonable response.
    # We do this through X constraints:
    # 1. Only allow peaks that are after the trial onset
    # 2. Only allow peaks that have a non-significant peak (p < 0.01, two-tailed)
    # 3. Maybe only allow where width can be calculated
    # Note: The above constraints must be true on both trials for that voxel to be excluded
    good.latency  <- apply(vcparams[,,3], 1, function(x) any(x>0))
    tthr          <- qt(0.01/2, 15, lower.tail=F)
    good.height   <- apply(vcparams[,,7], 1, function(x) any(abs(x)>tthr))
    good.width    <- apply(vcparams[,,4], 1, function(x) any(!is.na(x)))
    good.voxs     <-  good.latency & good.height & good.width
    ## now select those good voxels and set any NAs to 0?
    good.vcparams <- vcparams[good.voxs,,]
    good.vcparams[is.na(good.vcparams)] <- 0 # check if this is good idea
    ## get the new mask
    new.mask      <- dat$mask
    new.mask[new.mask][!good.voxs] <- F
    
    # Save for each
    cat("...saving 3d\n")
    ## setup
    outdir <- file.path(datadir, subject, runtype, "latency")
    if (!file.exists(outdir)) dir.create(outdir)
    setwd(outdir)
    ## get background?
    meanfile  <- file.path(datadir, subject, runtype, "mean_func.nii.gz")
    #file.link(meanfile, "mean_func.nii.gz")
    new.hdr   <- read.nifti.header(meanfile)
    ## now save each thing for conds
    oinds     <- c(2,7,3,4,5)
    onames    <- c("peak_height", "peak_height_ttest", "peak_latency", "width", "onset_latency")
    for (ci in 1:length(conditions)) {
      outfiles1 <- sprintf("%s_%s.nii.gz", conditions[ci], onames)
      outfiles2 <- sprintf("%s_%s_to_std.nii.gz", conditions[ci], onames)
      for (oi in 1:length(oinds)) {
        write.nifti(good.vcparams[,ci,oinds[oi]], new.hdr, new.mask, outfile=outfiles1[oi], overwrite=overwrite)
        system(sprintf("gen_applywarp.rb -i '%s' -r ../reg -w 'exfunc-to-standard' -o '%s' --interp spline", outfiles1[oi], outfiles2[oi]))
      }      
    }
    ## save those 4D files
    cat("...saving 4d\n")
    new.hdr1 <- dat$hdr
    new.hdr1$dim[4] <- ntpts
    new.hdr2 <- dat$hdr
    new.hdr2$dim[4] <- length(new.tpts)
    for (ci in 1:length(conditions)) {
      ## ave
      outfile1 <- file.path(outdir, sprintf("%s_ave_percent.nii.gz", conditions[ci]))
      outfile2 <- file.path(outdir, sprintf("%s_ave_percent_to_std.nii.gz", conditions[ci]))
      bigni <- as.big.nifti4d(vox.avedat[[ci]], new.hdr1, dat$mask)
      write.nifti(bigni, outfile=outfile1, overwrite=overwrite)
      system(sprintf("3dcalc -overwrite -a %s -expr 'a' -prefix %s", outfile1, outfile1)) # ghetto fix
      system(sprintf("gen_applywarp.rb -i '%s' -r ../reg -w 'exfunc-to-standard' -o '%s' --interp spline", outfile1, outfile2))
      ## smooth ave
      outfile1 <- file.path(outdir, sprintf("%s_smooth_ave_percent.nii.gz", conditions[ci]))
      outfile2 <- file.path(outdir, sprintf("%s_smooth_ave_percent_to_std.nii.gz", conditions[ci]))
      bigni <- as.big.nifti4d(vox.smoothavedat[[ci]], new.hdr2, dat$mask)
      write.nifti(bigni, outfile=outfile1, overwrite=overwrite)
      system(sprintf("3dcalc -overwrite -a %s -expr 'a' -prefix %s", outfile1, outfile1)) # ghetto fix
      system(sprintf("gen_applywarp.rb -i '%s' -r ../reg -w 'exfunc-to-standard' -o '%s' --interp spline", outfile1, outfile2))
    }
    
    cat("...cleaning\n")
    rm(dat); rm(vox.avedat); rm(vox.smoothavedat)
    gc(F,T)
  }
}

#names(dim(vcparams)) <- c(voxel", "condition", "parameter")
#dimnames(vcparams)[[3]] <- c("baseline", "height", "peak", "width", "onset", "offset", "peak.tstat")
#dimnames(vcparams)[[2]] <- c("bio", "phys")
