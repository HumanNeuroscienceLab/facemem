#!/usr/bin/env Rscript

# This script will create a 3-column FSL style timing file with runs concatenated

###
# SETUP
###

basedir   <- "/mnt/nfs/psych/faceMemoryMRI"
timingdir <- file.path(basedir, "scripts/timing")
outdir    <- file.path(timingdir, "eventstats_faceMemory01")
if (!file.exists(outdir)) dir.create(outdir)

subjects  <- as.character(read.table("../sublist_all.txt")[,1])
runtypes  <- c("Questions", "NoQuestions")


###
# READ/WRITE
###

cat("\n=== Save 3 Column FSL Files ===\n")
for (runtype in runtypes) {
  cat("\n", runtype, "\n", sep="")
  for (subject in subjects) {
    cat(subject, "\n")
    
    infile  <- file.path(timingdir, sprintf("r_faceMemory01_%s_%s.csv", subject, runtype))
    soutdir <- file.path(outdir, sprintf("%s_%s", runtype, subject))
    if (!file.exists(soutdir)) dir.create(soutdir)
    outfile1<- file.path(soutdir, "bio")
    outfile2<- file.path(soutdir, "phys")
    
    inmat   <- read.csv(infile)
    inmat$wt<- 1
    outmat1 <- subset(inmat, condition=="bio", select=c("onset", "duration", "wt"))
    outmat2 <- subset(inmat, condition=="phys", select=c("onset", "duration", "wt"))
    
    write.table(outmat1, file=outfile1, row.names=F, col.names=F, quote=F)
    write.table(outmat2, file=outfile2, row.names=F, col.names=F, quote=F)
  }
}


###
# Convert to XML
###

cat("\n=== Convert to XML ===\n")
for (runtype in runtypes) {
  cat("\n", runtype, "\n", sep="")
  for (subject in subjects) {
    cat(subject, "\n")
    
    soutdir <- file.path(outdir, sprintf("%s_%s", runtype, subject))
    setwd(soutdir)
    cmd <- "3column2xml sec bio phys > timing.xml"
    cat(cmd, "\n")
    system(cmd)
  }
}
