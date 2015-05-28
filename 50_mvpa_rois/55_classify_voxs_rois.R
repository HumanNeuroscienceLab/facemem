library(plyr)
setwd(file.path(scriptdir, "50_mvpa_rois"))

runtypes  <- c("Questions", "NoQuestions")
#runtypes
conds     <- c("bio", "phys")
subjects  <- as.character(as.matrix(read.table("../sublist_all.txt")))
# We want to select a subset of the extract ROIs for our analyses
srois <- c(
  1, # R OFA
  2, # R FFA
  3,  # R vATL
  4, # L OFA
  5, # L FFA
  6 # L vATL
)
snames  <- c("R OFA", "R FFA", "R vATL", 
             "L OFA", "L FFA", "L vATL")
scols   <- tolower(sub(" ", ".", snames))
conds   <- c("bio", "phys")

base <- "/mnt/nfs/psych/faceMemoryMRI"

balloon

library(caret)
library(glmnet)
library(doMC)
registerDoMC(cores=12)

scandat0 <- read.csv("../data/scandat.csv")
head(scandat0)

df1 <- ldply(runtypes, function(runtype) {
  cat("\n\n====\n")
  cat("Runtype:", runtype, "\n")
  
  scandat <- subset(scandat0, Onset>6 & RunType==runtype, select=c("Subject", "Run", "Type"))
  
  ldply(subjects, function(subject) {
    cat("\n==", subject, "==\n")
    sdir    <- file.path(base, "analysis/subjects", subject, runtype)
    
    # Read in all the roi and condition data
    lst.dat <- llply(srois, function(iroi) {
      ldply(conds, function(cond) {
        tsfile  <- file.path(sdir, "ts", sprintf("bs_classify_probpeaks_small_%s_%03i.1D", cond, iroi))
        dat     <- read.table(tsfile)
        data.frame(lab=rep(cond,nrow(dat)), dat)
      })
    })
    names(lst.dat) <- scols
    
    # Now loop through the rois and do the classification
    res <- ldply(srois, function(iroi) {
      dat   <- lst.dat[[iroi]]
      name  <- snames[iroi]
      cat(name, "\n")
      
      x     <- as.matrix(dat[,-1])
      ylabs <- dat$lab
      ys    <- 2-as.numeric(ylabs)
      
      # Read in the run information and check
      sub.scandat     <- ddply(subset(scandat, Subject==subject), .(Type), function(x) x)
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
      
      # For GLMNet, get the range of lambdas this way
      # for alphas with 0, 0.1, 0.5, and 1, I get the collection of 
      # autodetermined lambdas
      lambdas <- glmnet(x, ylabs, family="binomial", nlambda=100, alpha=1)$lambda
      for (i in rev(seq(0.1,1,by=0.1))) {
        tmp <- glmnet(x, ylabs, family="binomial", nlambda=100, alpha=i)
        lambdas <- c(tmp$lambda[tmp$lambda > max(lambdas)], lambdas)
      }
      
      # Tuning Grids
      grids <-  list(
        # alpha=1 is the lasso penalty and alpha=0 is the ridge penalty
        # lambda the amount of regularization
        glmnet=expand.grid(alpha = seq(0,1,by=0.1),
                           lambda = lambdas)
      )
      
      # Fit model
      method <- "glmnet"
      fit <- train(scale(x), ylabs, 
                   method = method,
                   trControl = fitControl, 
                   tuneGrid = grids[[method]])
      
      perf  <- getTrainPerf(fit)
      tune  <- fit$bestTune
      vi    <- varImp(fit, scale=F)
      nfeats<- sum(vi$importance$Overall!=0)
      pfeats<- mean(vi$importance$Overall!=0)*100
      
      df <- data.frame(roi=name, 
                       accuracy=perf$TrainAccuracy, kappa=perf$TrainKappa, 
                       alpha=tune$alpha, lambda=tune$lambda, 
                       n.feats=nfeats, perc.feats=pfeats)
      df
    })
    
    data.frame(runtype=runtype, subject=subject, res)
  })
})
## get simplified means
df1.summary <- ddply(df1, .(runtype, roi), colwise(function(x) round(mean(x),2), .(accuracy,kappa,alpha,lambda,percent.features)))
df1.summary # so now the FFA and the vATL are roughly the same and accuracy is lower



# Now we only focus on the left FFA and left vATL
# and we examine the effect of using the combined ROI
df2 <- ldply(runtypes, function(runtype) {
  cat("\n\n====\n")
  cat("Runtype:", runtype, "\n")
  
  scandat <- subset(scandat0, Onset>6 & RunType==runtype, select=c("Subject", "Run", "Type"))
  
  ldply(subjects, function(subject) {
    cat("\n==", subject, "==\n")
    sdir    <- file.path(base, "analysis/subjects", subject, runtype)
    
    # Read in all the roi and condition data
    lst.dat <- llply(srois[5:6], function(iroi) {
      ldply(conds, function(cond) {
        tsfile  <- file.path(sdir, "ts", sprintf("bs_classify_probpeaks_small_%s_%03i.1D", cond, iroi))
        dat     <- read.table(tsfile)
        data.frame(lab=rep(cond,nrow(dat)), dat)
      })
    })
    names(lst.dat) <- scols[5:6]
    
    # Combine the data from the combined L FFA and L vATL
    x <- cbind(
      as.matrix(lst.dat[[1]][,-1]), 
      as.matrix(lst.dat[[2]][,-1])
    )
    
    ylabs <- lst.dat[[1]]$lab
    ys    <- 2-as.numeric(ylabs)
    
    # Read in the run information and check
    sub.scandat     <- ddply(subset(scandat, Subject==subject), .(Type), function(x) x)
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
    
    # For GLMNet, get the range of lambdas this way
    # for alphas with 0, 0.1, 0.5, and 1, I get the collection of 
    # autodetermined lambdas
    lambdas <- glmnet(x, ylabs, family="binomial", nlambda=100, alpha=1)$lambda
    for (i in rev(seq(0.1,1,by=0.1))) {
      tmp <- glmnet(x, ylabs, family="binomial", nlambda=100, alpha=i)
      lambdas <- c(tmp$lambda[tmp$lambda > max(lambdas)], lambdas)
    }
    
    # Tuning Grids
    grids <-  list(
      # alpha=1 is the lasso penalty and alpha=0 is the ridge penalty
      # lambda the amount of regularization
      glmnet=expand.grid(alpha = seq(0,1,by=0.1),
                         lambda = lambdas)
    )
    
    # Fit model
    method <- "glmnet"
    fit <- train(scale(x), ylabs, 
                 method = method,
                 trControl = fitControl, 
                 tuneGrid = grids[[method]])
    
    perf  <- getTrainPerf(fit)
    tune  <- fit$bestTune
    ## get the features contributed by each ROI
    vi    <- varImp(fit, scale=F)
    nfeats.ffa  <- sum(vi$importance$Overall[1:ncol(lst.dat[[1]])]!=0)
    pfeats.ffa  <- mean(vi$importance$Overall[1:ncol(lst.dat[[1]])]!=0)*100
    nfeats.vatl <- sum(vi$importance$Overall[-c(1:ncol(lst.dat[[1]]))]!=0)
    pfeats.vatl <- mean(vi$importance$Overall[-c(1:ncol(lst.dat[[1]]))]!=0)*100
    
    #
    df <- data.frame(runtype=runtype, subject=subject, 
                     accuracy=perf$TrainAccuracy, kappa=perf$TrainKappa, 
                     alpha=tune$alpha, lambda=tune$lambda, 
                     pfeats.ffa=pfeats.ffa, pfeats.vatl=pfeats.vatl, 
                     nfeats.ffa=nfeats.ffa, nfeats.vatl=nfeats.vatl)
    df
  })
})
df2.summary <- ddply(df2, .(runtype), colwise(function(x) round(mean(x),2), .(accuracy,kappa,alpha,lambda,nfeats.ffa,nfeats.vatl,pfeats.ffa,pfeats.vatl)))
df2.summary

tmp <- cbind(t(matrix(subset(df1, runtype=="Questions" & roi %in% c("L FFA", "L vATL"))$acc, 2, 16)), subset(df2, runtype=="Questions")$acc)
colnames(tmp) <- c("FFA", "vATL", "Combined")
t.test(tmp[,1], tmp[,2], paired=T) # no diff btw individual ROIs
t.test(tmp[,1], tmp[,3], paired=T)
t.test(tmp[,2], tmp[,3], paired=T) # combined is more than the vATL alone
t.test(apply(tmp[,1:2], 1, max), tmp[,3], paired=T)



# Only take the mean of the beta-series for the two regions of interest
df3 <- ldply(runtypes, function(runtype) {
  cat("\n\n====\n")
  cat("Runtype:", runtype, "\n")
  
  scandat <- subset(scandat0, Onset>6 & RunType==runtype, select=c("Subject", "Run", "Type"))
  
  ldply(subjects, function(subject) {
    cat("\n==", subject, "==\n")
    sdir    <- file.path(base, "analysis/subjects", subject, runtype)
    
    # Read in all the roi and condition data
    lst.dat <- llply(srois, function(iroi) {
      ldply(conds, function(cond) {
        tsfile  <- file.path(sdir, "ts", sprintf("bs_classify_probpeaks_small_%s_%03i.1D", cond, iroi))
        dat     <- read.table(tsfile)
        data.frame(lab=rep(cond,nrow(dat)), dat)
      })
    })
    names(lst.dat) <- scols
    
    # Now loop through the rois and do the classification
    res <- ldply(srois[5:6], function(iroi) {
      dat   <- lst.dat[[iroi]]
      name  <- snames[iroi]
      cat(name, "\n")
      
      x     <- as.matrix(rowMeans(as.matrix(dat[,-1])))
      ylabs <- dat$lab
      ys    <- 2-as.numeric(ylabs)
      
      # Read in the run information and check
      sub.scandat     <- ddply(subset(scandat, Subject==subject), .(Type), function(x) x)
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
      
#       # For GLMNet, get the range of lambdas this way
#       # for alphas with 0, 0.1, 0.5, and 1, I get the collection of 
#       # autodetermined lambdas
#       lambdas <- glmnet(x, ylabs, family="binomial", nlambda=100, alpha=1)$lambda
#       for (i in rev(seq(0.1,1,by=0.1))) {
#         tmp <- glmnet(x, ylabs, family="binomial", nlambda=100, alpha=i)
#         lambdas <- c(tmp$lambda[tmp$lambda > max(lambdas)], lambdas)
#       }
#       
#       # Tuning Grids
#       grids <-  list(
#         # alpha=1 is the lasso penalty and alpha=0 is the ridge penalty
#         # lambda the amount of regularization
#         glmnet=expand.grid(alpha = seq(0,1,by=0.1),
#                            lambda = lambdas)
#       )
#       
#       # Fit model
#       method <- "glmnet"
      method <- "svmLinear"
      fit <- train(x, ylabs, 
                   method = method,
                   trControl = fitControl)#, 
                   #tuneGrid = grids[[method]])
      
      perf  <- getTrainPerf(fit)
      tune  <- fit$bestTune
      #vi    <- varImp(fit, scale=F)
      #nfeats<- sum(vi$importance$Overall!=0)
      #pfeats<- mean(vi$importance$Overall!=0)*100
      
      df <- data.frame(roi=name, 
                       accuracy=perf$TrainAccuracy, kappa=perf$TrainKappa)#, 
                       #alpha=tune$alpha, lambda=tune$lambda, 
                       #n.feats=nfeats, perc.feats=pfeats)
      df
    })
    
    data.frame(runtype=runtype, subject=subject, res)
  })
})
## get simplified means
#df3.summary <- ddply(df3, .(runtype, roi), colwise(function(x) round(mean(x),2), .(accuracy,kappa,alpha,lambda,percent.features)))
df3.summary <- ddply(df3, .(runtype, roi), colwise(function(x) round(mean(x),2), .(accuracy,kappa)))
df3.summary # so now the FFA and the vATL are roughly the same and accuracy is lower
t.test(accuracy ~ roi, data=subset(df3, runtype=="Questions"), paired=T)
t.test(accuracy ~ roi, data=subset(df3, runtype=="NoQuestions"), paired=T)
