#' We will be loading the behavioral data during the scan as well as the memory
#' performance before the scan (during training) and after the scan (subsequent
#' memory).
#' 
#+ packages, echo=FALSE
library(RGoogleDocs)
library(plyr)
library(dplyr)
# setwd("/Users/czarrar/Dropbox/Research/facemem/connpaper")

#+ todo
# this function will simply format the incorrect column
# below needs to be fixed up
format.memory.df <- function(odf) {
  odf     <- odf[!is.na(odf[,1]),]
  face.id <- odf[["FACE #"]]
  incorrect.answers <- odf[["INCORRECT"]]
  # We want to loop through the incorrect vector 
  # and find those elements that are non-NAs
  # and split those into individual elements (1=name, 2=occupation, 3=home-state)
  #inds <- !is.na(incorrect.answers)
  #tmp  <- strsplit(as.character(incorrect.answers[inds]), "")
  incorrect.answers <- as.integer(as.character(incorrect.answers))
  correct <- laply(incorrect.answers, function(x) {
    ret <- rep(1,3)
    if (!is.na(x)) {
      inds <- as.numeric(strsplit(as.character(x), "")[[1]])
      ret[inds] <- 0
    }
    ret
  })
  colnames(correct) <- c("name", "occupation", "homestate")
  # Add in the total correct and the proportion correct
  correct <- cbind(correct, total=rowSums(correct), 
                   prop=round(rowMeans(correct), 3))
  # Now let's combine this together with the other deets
  df <- data.frame(
    order=1:length(face.id), 
    faceid=face.id, 
    correct
  )
  # Reorder by faceid
  arrange(df, faceid)
}

add.condition.col <- function(odf, version) {
  if (version == 1) {
    conds <- rep(c("bio","phys"), each=nrow(odf)/2)
  } else if (version == 2) {
    conds <- rep(c("phys","bio"), each=nrow(odf)/2)
  } else {
    stop("unrecognized version #")
  }
  data.frame(
    condition=conds, 
    odf
  )
}
  
#' # Load Data
#' 
#' We will be getting our data off of google docs. So we first need to 
#' authenticate and establish a connection.
#' 
#+ data-setup
gpasswd <- readline(prompt="Enter google password: ")
auth = getGoogleAuth("czarrar@gmail.com", gpasswd, service="wise")
rm(gpasswd)
con = getGoogleDocsConnection(auth)

#' ## Subject Info
#' 
#' We'll get the version number and tb# associated with each subject
#' 
#+ data-subject
# read in something with the versions!
stimv <- read.table("00_behav/stim_versions_v2.txt", header=T)

#' ## Pre-Scan Memory Preformance
#' 
#' There were 3 days of pre-scan training. I've collected the performance on the
#' memory tests at the end of each of those days.
#' 
#' In this section, I'll also compile the subsequent memory performance, which
#' I label as day 4.
#' 
#+ data-memory
# loop through and collect as dataframe
behav <- ldply(1:4, function(day) {
  cat("Day", day, "\n")
  if (day == 4) {
    sheets <- getWorksheets("Subsequent_Memory_Performance", con)
  } else {
    sheets = getWorksheets(sprintf("Pre-Scan Memory - Day %i", day), con)
  }
  subjs <- names(sheets)
  ldply(subjs, function(subj) {
    tb  <- stimv %>% filter(subid==subj) %>% select(tbnum) %>% as.matrix %>% as.character
    ver <- stimv %>% filter(subid==subj) %>% select(version) %>% as.matrix %>% as.numeric
    
    sheet <- sheetAsMatrix(sheets[[subj]], header = TRUE, as.data.frame = TRUE, 
                           trim = TRUE)
    odf <- format.memory.df(sheet)
    odf <- add.condition.col(odf, ver)
    
    data.frame(
      sub=subj,
      tb=tb,
      day=day,
      version=ver, 
      odf
    )
  }, .progress="text")
})

behav %>% filter(condition == "bio") %>% group_by(day) %>% summarise(mprop=mean(prop))


#' ## From Scan
#' 
#' Get the RT, question type, etc data from the scan
#' 
#+ data-scan
sheets <- getWorksheets("All Subject Scan Info and Timing", con)
scandat <- sheetAsMatrix(sheets$sheet1, header = TRUE, as.data.frame = TRUE, trim = TRUE)
head(scandat)

#' ## Save
#+ save
write.csv(behav, file="data/behav.csv")
write.csv(scandat, file="data/scandat.csv")





library(ggplot2)
