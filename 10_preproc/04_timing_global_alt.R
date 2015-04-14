#!/usr/bin/env Rscript

# This script gives a more useful global timing file than the afni based one earlier

library(plyr)

###
# Setup
###

project_directory   <- "/mnt/nfs/psych/faceMemoryMRI"
data_directory      <- file.path(project_directory, "data/nifti")
timing_directory    <- file.path(project_directory, "scripts/timing")
output_directory    <- timing_directory

subjects            <- list.files(data_directory, pattern="tb")
nsubjects           <- length(subjects)

runtypes            <- c("Questions", "NoQuestions")
lruntypes           <- c("question", "noquestion")
sruntypes           <- c("withQ", "noQ")
ntypes              <- length(runtypes)


###
# Get input/output files
###

data_files      <- list()
timing_files    <- list(question=list(), noquestion=list())
conditions      <- c("bio", "phys")

# Question
## Data Files
data_files$question <- sapply(subjects, function(subject) {
  file.path(data_directory, subject, sprintf("%s_FaceMemory01_%s_run*.nii.gz", subject, sruntypes[1]))
})
## Timing Files
timing_files$question$bio   <- sapply(subjects, function(subject)
    file.path(timing_directory, sprintf("allruns_faceMemory01_%s_Questions_bio", subject)))
timing_files$question$phys  <- sapply(subjects, function(subject)
    file.path(timing_directory, sprintf("allruns_faceMemory01_%s_Questions_phys", subject)))
## Attach subject index labels to everything to make it easier to get later
names(data_files$question)       <- subjects
names(timing_files$question$bio) <- subjects
names(timing_files$question$phys)<- subjects

# Passive Viewing or No Question
## Data Files
data_files$noquestion <- sapply(subjects, function(subject) {
  file.path(data_directory, subject, sprintf("%s_FaceMemory01_%s_run*.nii.gz", subject, sruntypes[2]))
})
## Timing Files
timing_files$noquestion$bio   <- sapply(subjects, function(subject)
    file.path(timing_directory, sprintf("allruns_faceMemory01_%s_NoQuestions_bio", subject)))
timing_files$noquestion$phys  <- sapply(subjects, function(subject)
    file.path(timing_directory, sprintf("allruns_faceMemory01_%s_NoQuestions_phys", subject)))
## Attach subject index labels to everything to make it easier to get later
names(data_files$noquestion)       <- subjects
names(timing_files$noquestion$bio) <- subjects
names(timing_files$noquestion$phys)<- subjects


###
# Functions
###

# get the run lengths for the concatenated files
get_runlengths <- function(func_file) {
  run_files   <- sort(Sys.glob(func_file))
  runlengths  <- laply(run_files, function(run_file) {
    cmd <- sprintf("fslnvols %s", run_file)
    as.integer(system(cmd, intern=T))
  })
  return(runlengths)
}

# combines the run onsets in the timing file to get a concatenated dataset onset timing
concatenate_onsets <- function(timing, runlengths) {
    ddply(timing, .(run), function(run_timing) {
        run         <- as.numeric(run_timing$run[1])
        pretime     <- cumsum(c(0,runlengths))[run]
        run_timing$concat.onset <- as.numeric(run_timing$onset) + pretime
        run_timing
    })
}

# adds the timing duration
add_durations <- function(timing, runlengths) {
    ddply(timing, .(run), function(run_timing) {
        run <- as.numeric(run_timing$run[1])
        run_timing$duration <- diff(c(run_timing$onset, runlengths[run]))
        run_timing
    })
}

# put it together for timing
read_timing_files <- function(bio_fn, phys_fn, data_fn=NULL) {
    bio_timing  <- lapply(strsplit(readLines(bio_fn), " "), as.numeric)
    phys_timing <- lapply(strsplit(readLines(phys_fn), " "), as.numeric)
    
    timing_df <- ldply(1:length(bio_timing), function(run) {
        data.frame(
            run = run, 
            condition = rep(c("bio","phys"), c(length(bio_timing[[run]]), length(phys_timing[[run]]))), 
            onset = c(bio_timing[[run]], phys_timing[[run]])
        )
    })
    
    timing_df       <- timing_df[order(timing_df$run, timing_df$onset),]
    timing_df$trial <- 1:nrow(timing_df)
    timing_df       <- subset(timing_df, select=c("run", "trial", "condition", "onset"))
    
    if (!is.null(data_fn)) {
        runlengths<- get_runlengths(data_fn)
        timing_df <- concatenate_onsets(timing_df, runlengths)
        timing_df <- add_durations(timing_df, runlengths)
        
        colnames(timing_df)[colnames(timing_df) == "onset"] <- "per.run.onset"
        colnames(timing_df)[colnames(timing_df) == "concat.onset"] <- "onset"
        
        timing_df <- subset(timing_df, select=c("run", "trial", "condition", "onset", "duration", "per.run.onset"))
    }
    
    timing_df
}


###
# Compile the timing files
###

for (subj in subjects) {
  cat("\nSubject:", subj, "\n")
  
  for (ri in 1:ntypes) {
    rt <- lruntypes[ri]
    cat("type:", rt, "\n")
    
    timing <- read_timing_files(timing_files[[rt]]$bio[[subj]], timing_files[[rt]]$phys[[subj]], 
                                data_files[[rt]][[subj]])
    
    cat("...saving: ")
    outfile <- file.path(timing_directory, sprintf("r_faceMemory01_%s_%s.csv", subj, runtypes[ri]))
    cat(outfile, "\n")
    write.csv(timing, file=outfile, row.names=F)
  }
}
