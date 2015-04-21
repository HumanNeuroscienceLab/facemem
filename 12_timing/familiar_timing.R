#' Load the data
#+ load
library(plyr)
library(dplyr)
behav <- read.csv("data/behav.csv")
scandat <- read.csv("data/scandat.csv")

#' ## Generate familiarity timing file
#' 
#' Create the timing files for items remembered versus not remembered at the end
#' of the first day of training.
#' 
#' For a given subject, we first get a table with the remembered vs not 
#' remembered on day 1. Remembered is classified as being able to remember
#' 2 or 3 facts about the person.
#' 
#+ timing-fam
# subset
l_ply(levels(behav$tb), function(tbnum) {
  cat("tb", tbnum, "\n")
  #tbnum <- "tb9276"
  sbehav <- behav %>% 
    filter(tb==tbnum, day==1 & condition=="bio") %>% 
    select(tb, faceid, total) %>%
    rename(subject=tb) %>%
    mutate(remember=factor(total>=2, levels=c(F,T), labels=c("no","yes")))
  # now link to subjects scan times
  ## subset
  sscandat <- scandat %>% 
    filter(Subject==tbnum, RunType=="Questions" & Type=="bio") %>%
    select(Subject, Run, Trial, StimID, Onset) %>%
    rename(subject=Subject, run=Run, trial=Trial, faceid=StimID, onset=Onset) %>%
    mutate(onset=onset-6)
  # now link the subjects
  ## merge the two dataframes
  merged <- sscandat %>% merge(sbehav) %>% arrange(subject, run, onset)
  ## now we can split into remembered versus not remembered
  ## we want this to be in afni format so should be 4 rows x Y cols
  afnidat <- dlply(merged, .(remember), function(x) {
    # should actually have a for loop -> if nothing with that run, then '***'
    llply(1:4, function(ri) {
      xx <- filter(x, run==ri & onset>=0)
      if (nrow(xx) == 0) {
        return(NULL)
      } else {
        return(sort(xx$onset))
      }
    })
  })
  ## ok now actually save
  #ofile <- "data/tmp_timing.txt"
  #cat("", file=ofile, sep="", append=F)
  l_ply(1:length(afnidat), function(i) {
    cat("Remember?", names(afnidat)[i], "\n")

    ofile <- sprintf("data/timing/familiarity_%s_rem-%s.1D", tbnum, names(afnidat)[i])
    cat("", file=ofile, sep="", append=F)
    
    remdat <- afnidat[[i]]
    l_ply(remdat, function(rundat) {
      if (is.null(rundat)) {
        cat("***", "\n")
        cat("***", "\n", file=ofile, append=T)
      } else {
        cat(rundat, "\n")
        cat(rundat, "\n", file=ofile, append=T)
      }
    })
  })
  
  cat("\n")
})
