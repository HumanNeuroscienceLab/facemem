#' Load the data
#+ load
library(plyr)
library(dplyr)
scandat <- read.csv("data/scandat.csv")
scandat <- scandat[,-1]

#' ## Generate RT timing file
#' 
#' Create the timing files for response times.
#' These files will be in the AFNI format and will do both amplitude and 
#' duration modulation.
#' 
#' Since we only have response times for the Question runs, we only keep those
#' runs. And we'll need to exclude any no response trials.
#' 
#' We will create separate files for the bio and phys runs.
#' 
#' Note that I should also be adding 4s to the onset since we want to get the 
#' time for the question
#' 
#+ timing-rt
# Get subset of the data
sscandat <- scandat %>% 
  filter(RunType=="Questions" & Resp!='NoResp') %>%
  select(Subject, Run, Onset, Type, Resp, RT) %>%
  rename(subject=Subject, run=Run, type=Type, onset=Onset, resp=Resp, rt=RT) %>%
  mutate(onset=onset-6) %>%
  filter(onset>=0) %>% 
  mutate(onset=onset+4)  
sscandat$resp <- as.factor(as.character(sscandat$resp))

#' Now...
#' This should be done for bio and phys separately
#' Then I want to write out a file where each row is a run
#' and each element is that trials onset*amplitude:duration
#' 
#' 30*5:12
#' onset=30, amplitude=5, duration=12
#+ timing-rt2
d_ply(sscandat, .(subject), function(dat) {
  subj <- as.character(dat$subject[1])
  cat("subject:", subj, "\n")
  
  # Get everything
  afnidat <- dlply(dat, .(type), function(sdat) {
    dlply(sdat, .(run), function(x) {
      # Let's try this with one row and get the value for a trial
      laply(1:nrow(x), function(i) {
        row <- x[i,]
        trial <- sprintf("%.3f*%.3f:%.3f", row$onset, row$rt, row$rt)
        trial
      })
    })
  })
  # Save
  l_ply(1:length(afnidat), function(i) {
    cond <- names(afnidat)[i]
    cat("Condition:", cond, "\n")
    
    ofile <- sprintf("data/timing/rt_%s_Questions_%s.1D", subj, cond)
    cat("", file=ofile, sep="", append=F)
    
    conddat <- afnidat[[i]]
    l_ply(conddat, function(rundat) {
      if (is.null(rundat)) {
        cat("*", "\n")
        cat("*", "\n", file=ofile, append=T)
      } else {
        cat(rundat, "\n")
        cat(rundat, "\n", file=ofile, append=T)
      }
    })
  })
  
  cat("\n")
})
