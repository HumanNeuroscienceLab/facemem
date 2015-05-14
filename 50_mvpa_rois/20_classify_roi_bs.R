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


#' # Read
#' We will read in the beta-series data
#+ read
bdat <- read.csv("../data/prob_peaks_betas.csv.gz")[,-1]
## extract the relevant rois
bdat <- bdat[,c(1:3,srois+3)]
colnames(bdat)[-c(1:3)] <- scols

#' Ok we can see how well any classification might work by simplifying
#' and looking at one subject
#+ test
library(plyr)
library(dplyr)
sbdat <- bdat %>% filter(runtype=="Questions" & subject=="tb9226")
sbdat <- bdat %>% filter(runtype=="Questions") 
sbdat <- ddply(sbdat, .(subject), function(x) { x[,-c(1:3)] <- scale(x[,-c(1:3)]); x })
x     <- sbdat %>% select(l.ffa,l.vatl) %>% as.matrix
#x     <- sbdat %>% select(r.ofa,r.ffa,r.vatl,l.ofa,l.ffa,l.vatl) %>% as.matrix
ylabs <- sbdat %>% select(condition) %>% as.matrix %>% as.character %>% factor
ys    <- 2-as.integer(ylabs) # 1=bio, 0=phys 

## CLASSIFY
library(caret)
library(glmnet)

library(doMC)
registerDoMC(cores=2)
#registerDoMC(cores=16)

fitControl <- trainControl(
  method = "repeatedcv",
  number = 10, 
  repeats = 2, 
  allowParallel = TRUE
)

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
fit <- train(scale(x), ylabs, 
             method = method,
             trControl = fitControl), 
             tuneGrid = grids[[method]])
fit
getTrainPerf(fit)
fit$results[rownames(fit$bestTune),]$Accuracy
fit$finalModel$beta
varImp(fit, scale=F)



method <- "lda"
fit <- train(scale(x[,1]), ylabs, 
             method = method,
             trControl = fitControl)
getTrainPerf(fit)

method <- "lda"
fit <- train(scale(x[,2]), ylabs, 
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
