#!/usr/bin/env bash

# This will combine all the betas into one big array
# Then can save this as an rda

subjects <- as.character(as.matrix(read.table("../sublist_all.txt")))
runtypes <- c("Questions", "NoQuestions")
conds    <- c("bio", "phys")

base     <- "/mnt/nfs/psych/faceMemoryMRI"
template <- file.path(base, "analysis/subjects/%s/%s/task/beta_series_prob_atlas_peaks_n146.reml/beta_series_%s.1D")

library(plyr)
# read in everthing
df <- ldply(runtypes, function(runtype) {
  cat(runtype, "\n")
  ldply(subjects, function(subject) {
    ldply(conds, function(cond) {
      infile <- sprintf(template, subject, runtype, cond)
      tab    <- read.table(infile)
      colnames(tab) <- sprintf("roi.%03i", 1:146)
      data.frame(runtype=runtype, subject=subject, condition=cond, tab)
    })
  })
})
# save everthing
z <- gzfile("../data/prob_peaks_betas.csv.gz")
write.csv(df, file=z)