#' This script will ...
#' 
#' 

subjects <- as.character(as.matrix(read.table("../sublist_all.txt")))
# We want to select a subset of the extract ROIs for our analyses
srois <- c(
  3,  # R OFA
  1,  # R FFA
  69, # R vATL
  8,  # L OFA
  2,  # L FFA
  62  # L vATL
)
snames  <- c("R OFA", "R FFA", "R vATL", 
             "L OFA", "L FFA", "L vATL")
scols   <- tolower(sub(" ", ".", snames))
conds   <- c("bio", "phys")
runtypes <- c("Questions", "NoQuestions")


#' # Read
#' We will read in the beta-series data
#+ read
bdat <- read.csv("../data/prob_peaks_betas.csv.gz")[,-1]
## extract the relevant rois
bdat <- bdat[,c(1:3,srois+3)] # 1st 3 cols are runtype, subject, and condition
colnames(bdat)[-c(1:3)] <- scols

#' Also read in the run information
#+ read-run
scandat0 <- read.csv("../data/scandat.csv")
head(scandat0)

runtype <- "Questions"
scandat <- subset(scandat0, Onset>6 & RunType==runtype, select=c("Subject", "Run", "Type"))

#' Ok we can see how well any classification might work by simplifying
#' and looking at one subject
#+ test
library(plyr)
library(dplyr)
subj <- "tb9226"
sbdat <- bdat %>% filter(runtype=="Questions" & subject=="tb9226")
sbdat <- ddply(sbdat, .(subject), function(x) { x[,-c(1:3)] <- scale(x[,-c(1:3)]); x })
x     <- sbdat %>% select(l.ffa,l.vatl) %>% as.matrix
#x     <- sbdat %>% select(r.ofa,r.ffa,r.vatl,l.ofa,l.ffa,l.vatl) %>% as.matrix
ylabs <- sbdat %>% select(condition) %>% as.matrix %>% as.character %>% factor
ys    <- 2-as.integer(ylabs) # 1=bio, 0=phys

# Read in the run information and check
sub.scandat     <- ddply(subset(scandat, Subject==subj), .(Type), function(x) x)
sub.scandat$Ind <- 1:nrow(sub.scandat)
if (nrow(sub.scandat) != length(ylabs)) stop("nrow != len", nrow(sub.scandat), length(ylabs))
if (!all(ylabs==sub.scandat$Type)) stop("not all same")

# Leave one run out (so 4-folds)
runs     <- sort(unique(sub.scandat$Run))
nruns    <- length(runs)
runFolds <- createMultiFolds(runs, k=nruns, times = 1)
folds    <- lapply(runFolds, function(x) {
  which(sub.scandat$Run %in% x)
})
fitControl <- trainControl(
  method = "cv",
  number = 10, 
  repeats = 1, 
  index = folds, 
  allowParallel = TRUE
)

## CLASSIFY
library(caret)
library(glmnet)

library(doMC)
registerDoMC(cores=4)
#registerDoMC(cores=16)

# fitControl <- trainControl(
#   method = "LOOCV",
#   allowParallel = TRUE
# )

# For GLMNet
tmp <- glmnet(x, ylabs, family="binomial", nlambda=10)
lambdas <- tmp$lambda

# Tuning Grids
grids <-  list(
  # alpha=1 is the lasso penalty and alpha=0 is the ridge penalty
  # lambda the amont of regularization
  glmnet=expand.grid(alpha = seq(0,1,length=11),
                     #lambda=c(lambdas, seq(max(lambdas), max(lambdas)*2, length=4)[-1]))#, 
                     lambda=seq(max(lambdas), max(lambdas)*4, length=11)[-1])
)

method <- "lda"
fit <- train(x[,1,drop=F], ylabs, 
             method = method,
             trControl = fitControl)#, 
             #tuneGrid = grids[[method]])
#fit
getTrainPerf(fit)
fit$results[rownames(fit$bestTune),]$Accuracy
fit$finalModel$beta
varImp(fit, scale=F)



method <- "svmLinear"
fit <- train(x[,1,drop=F], ylabs, 
             method = method,
             trControl = fitControl)
getTrainPerf(fit)

method <- "svmLinear"
fit <- train(x[,2,drop=F], ylabs, 
             method = method,
             trControl = fitControl)
getTrainPerf(fit)

method <- "lda"
fit <- train(scale(cbind(x, scale(x[,1])*scale(x[,2]))), ylabs, 
             method = method,
             trControl = fitControl)
getTrainPerf(fit)
varImp(fit, scale=F)

method <- "svmLinear"
fit <- train(scale(cbind(x, scale(x[,1])*scale(x[,2]))), ylabs, 
             method = method,
             trControl = fitControl)
getTrainPerf(fit)
varImp(fit, scale=F)


method <- "glmnet"
fit <- train(scale(cbind(x, scale(x[,1])*scale(x[,2]))), ylabs, 
             method = method,
             trControl = fitControl, 
             tuneGrid = grids[[method]])
getTrainPerf(fit)
varImp(fit, scale=F)







# Right Hemi
detach("package:dplyr", unload=TRUE)
library(dplyr)
sbdat <- bdat %>% filter(runtype=="Questions") 
sbdat <- ddply(sbdat, .(subject), function(x) { x[,-c(1:3)] <- scale(x[,-c(1:3)]); x })
x     <- sbdat %>% select(r.ffa,r.vatl) %>% as.matrix
#x     <- sbdat %>% select(r.ofa,r.ffa,r.vatl,l.ofa,l.ffa,l.vatl) %>% as.matrix
ylabs <- sbdat %>% select(condition) %>% as.matrix %>% as.character %>% factor
ys    <- 2-as.integer(ylabs) # 1=bio, 0=phys 

cols <- list(1,2,1:2)
for (col in cols) {
  cat("Column:", colnames(x)[col], "\n")
  method <- "lda"
  fit <- train(scale(x[,col]), ylabs, 
               method = method,
               trControl = fitControl)
  print(getTrainPerf(fit))
  print(varImp(fit, scale=F))
  cat("\n")
}



# Left Hemi - NoQuestions
#detach("package:dplyr", unload=TRUE)
#library(dplyr)
sbdat <- bdat %>% filter(runtype=="NoQuestions") 
sbdat <- ddply(sbdat, .(subject), function(x) { x[,-c(1:3)] <- scale(x[,-c(1:3)]); x })
x     <- sbdat %>% select(l.ffa,l.vatl) %>% as.matrix
#x     <- sbdat %>% select(r.ofa,r.ffa,r.vatl,l.ofa,l.ffa,l.vatl) %>% as.matrix
ylabs <- sbdat %>% select(condition) %>% as.matrix %>% as.character %>% factor
ys    <- 2-as.integer(ylabs) # 1=bio, 0=phys 

cols <- list(1,2,1:2)
for (col in cols) {
  cat("Column:", colnames(x)[col], "\n")
  method <- "lda"
  fit <- train(scale(x[,col]), ylabs, 
               method = method,
               trControl = fitControl)
  print(getTrainPerf(fit))
  print(varImp(fit, scale=F))
  cat("\n")
}

# note: should run the lda using the glmnet as well
# oh could simply do a logistic regression (right)

#fit <- glm(ylabs ~ x, family = binomial)
#summary(fit)
predict(fit)
table(predict(fit, type="response") < 0.5)
prop.table(table(ylabs, predict(fit, type="response") < 0.5))
tab <- table(ylabs, predict(fit, type="response") > 0.5)
sum(diag(tab))/sum(tab)




library(doMC)
registerDoMC(cores=12)
df1 <- ldply(runtypes[1], function(runt) {
  cat("\n\n====\n")
  cat("Runtype:", runt, "\n")
  
  scandat <- subset(scandat0, Onset>6 & RunType==runtype, select=c("Subject", "Run", "Type"))
  
  ldply(subjects, function(subj) {
    cat("\n==", subj, "==\n")
    
    # Get the data
    sbdat <- bdat %>% filter(runtype==runt & subject==subj)
    #sbdat[,-c(1:3)] <- scale(sbdat[,-c(1:3)]); x })
    x     <- sbdat %>% select(l.ffa,l.vatl) %>% as.matrix
    #x     <- sbdat %>% select(r.ofa,r.ffa,r.vatl,l.ofa,l.ffa,l.vatl) %>% as.matrix
    
    # Get the labels
    ylabs <- sbdat %>% select(condition) %>% as.matrix %>% as.character %>% factor
    ys    <- 2-as.integer(ylabs) # 1=bio, 0=phys
    
    # Read in the run information and check
    sub.scandat     <- ddply(subset(scandat, Subject==subj), .(Type), function(x) x)
    sub.scandat$Ind <- 1:nrow(sub.scandat)
    if (nrow(sub.scandat) != length(ylabs)) stop("nrow != len", nrow(sub.scandat), length(ylabs))
    if (!all(ylabs==sub.scandat$Type)) stop("not all same")
    
    # Leave one run out (so 4-folds)
    runs     <- sort(unique(sub.scandat$Run))
    nruns    <- length(runs)
    runFolds <- createMultiFolds(runs, k=nruns, times = 1)
    folds    <- lapply(runFolds, function(x) {
      which(sub.scandat$Run %in% x)
    })
    fitControl <- trainControl(
      method = "cv",
      number = 10, 
      repeats = 1, 
      index = folds, 
      allowParallel = F
    )
    
    method <- "svmLinear"
    fit1 <- train(x[,1,drop=F], ylabs, 
                 method = method,
                 trControl = fitControl)
    fit2 <- train(x[,2,drop=F], ylabs, 
                 method = method,
                 trControl = fitControl)
    
    data.frame(runtype=runt, subject=subj, 
               ffa.acc=getTrainPerf(fit1)$TrainAccuracy, vatl.acc=getTrainPerf(fit2)$TrainAccuracy, 
               ffa.kappa=getTrainPerf(fit1)$TrainKappa, vatl.kappa=getTrainPerf(fit2)$TrainKappa)
  }, .parallel=T)
})
colMeans(df1[,3:4]) # get even more boost here for the vATL 53% vs 56%
