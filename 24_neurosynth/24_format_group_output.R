#!/usr/bin/env Rscript

# This script will take the output of the group analysis and spit out better formatted data frames

args      <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) {
  cat("usage: $0 name\n")
  q()
}

#name      <- "ri_maps_01"
#runtype   <- "Questions"
name    <- args[1]

base      <- "/mnt/nfs/psych/faceMemoryMRI/analysis/groups"
termfile  <- sprintf("%s/mni152/dr/%s_terms.txt", base, name)
runtypes  <- c("Questions", "NoQuestions")

for (runtype in runtypes) {
  grpdir    <- sprintf("%s/%s/dr/%s.mema", base, runtype, name)
  
  cat("Runtype:", runtype, "\n")
  cat(grpdir, "\n")
  setwd(grpdir)

  # Get the terms used (each term is associated with a map)
  terms       <- as.character(as.matrix(read.table(termfile)))

  # Read in the relevant z-stat contrasts
  bio         <- as.numeric(as.matrix(read.table("bio_zstat.1D")))
  phys        <- as.numeric(as.matrix(read.table("phys_zstat.1D")))
  bio_vs_phys <- as.numeric(as.matrix(read.table("bio-gt-phys_zstat.1D")))

  # Compile into dataframe and save
  zdf         <- data.frame(bio=bio, phys=phys, bio_vs_phys=bio_vs_phys)
  rownames(zdf) <- terms
  write.table(zdf, file=file.path(grpdir, "bio_phys_df.txt"))
  write.table(round(zdf,2), file=file.path(grpdir, "bio_phys_df_round.txt"))
  
  # Spit it out
  print(round(zdf,2))
  cat("\n")
}

