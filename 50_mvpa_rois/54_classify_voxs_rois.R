
library(plyr)

runtypes  <- c("Questions", "NoQuestions")
conds     <- c("bio", "phys")
subjects  <- as.character(as.matrix(read.table("../sublist_all.txt")))
# We want to select a subset of the extract ROIs for our analyses
srois <- c(
  1, # L OFA
  2, # L FFA
  3,  # L vATL
  4, # R OFA
  5, # R FFA
  6 # R vATL
)
snames  <- c("L OFA", "L FFA", "L vATL", 
             "R OFA", "R FFA", "R vATL")
scols   <- tolower(sub(" ", ".", snames))
conds   <- c("bio", "phys")

base <- "/mnt/nfs/psych/faceMemoryMRI"


library(caret)
library(glmnet)
library(doMC)
registerDoMC(cores=16)

fitControl <- trainControl(
  method = "repeatedcv",
  number = 10, 
  repeats = 10, 
  allowParallel = TRUE
)

res <- ldply(runtypes, function(runtype) {
  cat("\n\n====\n")
  cat("Runtype:", runtype, "\n")
  ldply(subjects, function(subject) {
    cat("\n==", subject, "==\n")
    sdir    <- file.path(base, "analysis/subjects", subject, runtype)

    # Read in all the roi and condition data
    lst.dat <- llply(srois, function(iroi) {
      ldply(conds, function(cond) {
        tsfile  <- file.path(sdir, "ts", sprintf("bs_classify_probpeaks_%s_%03i.1D", cond, iroi))
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

      # For GLMNet, get the range of lambdas this way
      # for alphas with 0, 0.1, 0.5, and 1, I get the collection of 
      # autodetermined lambdas
      tmp <- glmnet(x, ylabs, family="binomial", nlambda=10, alpha=1)
      lambdas <- tmp$lambda
      tmp <- glmnet(x, ylabs, family="binomial", nlambda=10, alpha=0.5)
      lambdas <- c(tmp$lambda[tmp$lambda > max(lambdas)], lambdas)
      tmp <- glmnet(x, ylabs, family="binomial", nlambda=10, alpha=0.1)
      lambdas <- c(tmp$lambda[tmp$lambda > max(lambdas)], lambdas)
      tmp <- glmnet(x, ylabs, family="binomial", nlambda=4, alpha=0)
      lambdas <- c(tmp$lambda[tmp$lambda > max(lambdas)], lambdas)

      # Tuning Grids
      grids <-  list(
        # alpha=1 is the lasso penalty and alpha=0 is the ridge penalty
        # lambda the amount of regularization
        glmnet=expand.grid(alpha = c(0, 0.1, 0.3, 0.5, 0.7, 0.9, 1),
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
      pfeats<- mean(vi$importance!=0)*100
  
      df <- data.frame(roi=name, 
                       accuracy=perf$TrainAccuracy, kappa=perf$TrainKappa, 
                       alpha=tune$alpha, lambda=tune$lambda, 
                       percent.features=pfeats)

      df
    })
    
    data.frame(runtype=runtype, subject=subject, res)
  })
})

write.csv(res, file="z_roi_classify_res.csv")

## SAMPLE SUBJECT
#subject <- subjects[1]
#runtype <- runtypes[1]

#x     <- as.matrix(cbind(lst.dat[[1]][,-1], lst.dat[[2]][,-1]))
#ylabs <- lst.dat[[1]]$lab


# Can get run info but then how do I create the stratified k-fold?
# It seems that the trainControl has an index option where you can specify the indexing in each fold
scandat <- read.csv("../data/scandat.csv")
scandat <- subset(scandat, Onset > 6)
scandat <- scandat[,-1]




# ok. let's skip ahead and just try out with just the two of us...
orois2<- srois[2:3]
srois2 <- 1:2
scols2 <- scols[2:3]
snames2 <- snames[2:3]
res1 <- ldply(runtypes[1], function(runtype) {
  cat("\n\n====\n")
  cat("Runtype:", runtype, "\n")
  ldply(subjects, function(subject) {
    cat("\n==", subject, "==\n")
    sdir    <- file.path(base, "analysis/subjects", subject, runtype)

    # Read in all the roi and condition data
    lst.dat <- llply(srois2, function(iroi) {
      ldply(conds, function(cond) {
        tsfile  <- file.path(sdir, "ts", sprintf("bs_classify_probpeaks_%s_%03i.1D", cond, orois2[iroi]))
        dat     <- read.table(tsfile)
        data.frame(lab=rep(cond,nrow(dat)), dat)
      })
    })
    names(lst.dat) <- scols2

    # Now loop through the rois and do the classification
    res <- ldply(srois2, function(iroi) {
      dat   <- lst.dat[[iroi]]
      name  <- snames2[iroi]
      cat(name, "\n")
  
      x     <- as.matrix(dat[,-1])
      ylabs <- dat$lab
      ys    <- 2-as.numeric(ylabs)

      # For GLMNet, get the range of lambdas this way
      # for alphas with 0, 0.1, 0.5, and 1, I get the collection of 
      # autodetermined lambdas
      tmp <- glmnet(x, ylabs, family="binomial", nlambda=100, alpha=1)
      lambdas <- tmp$lambda
      
      # Tuning Grids
      grids <-  list(
        # alpha=1 is the lasso penalty and alpha=0 is the ridge penalty
        # lambda the amount of regularization
        glmnet=expand.grid(alpha = 1,
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
      pfeats<- mean(vi$importance!=0)*100
  
      df <- data.frame(roi=name, 
                       accuracy=perf$TrainAccuracy, kappa=perf$TrainKappa, 
                       alpha=tune$alpha, lambda=tune$lambda, 
                       percent.features=pfeats)

      df
    })
    
    data.frame(runtype=runtype, subject=subject, res)
  })
})

res.5 <- ldply(runtypes[1], function(runtype) {
  cat("\n\n====\n")
  cat("Runtype:", runtype, "\n")
  ldply(subjects, function(subject) {
    cat("\n==", subject, "==\n")
    sdir    <- file.path(base, "analysis/subjects", subject, runtype)

    # Read in all the roi and condition data
    lst.dat <- llply(srois2, function(iroi) {
      ldply(conds, function(cond) {
        tsfile  <- file.path(sdir, "ts", sprintf("bs_classify_probpeaks_%s_%03i.1D", cond, orois2[iroi]))
        dat     <- read.table(tsfile)
        data.frame(lab=rep(cond,nrow(dat)), dat)
      })
    })
    names(lst.dat) <- scols2

    # Now loop through the rois and do the classification
    res <- ldply(srois2, function(iroi) {
      dat   <- lst.dat[[iroi]]
      name  <- snames2[iroi]
      cat(name, "\n")
  
      x     <- as.matrix(dat[,-1])
      ylabs <- dat$lab
      ys    <- 2-as.numeric(ylabs)

      # For GLMNet, get the range of lambdas this way
      # for alphas with 0, 0.1, 0.5, and 1, I get the collection of 
      # autodetermined lambdas
      tmp <- glmnet(x, ylabs, family="binomial", nlambda=100, alpha=0.5)
      lambdas <- tmp$lambda
      
      # Tuning Grids
      grids <-  list(
        # alpha=1 is the lasso penalty and alpha=0 is the ridge penalty
        # lambda the amount of regularization
        glmnet=expand.grid(alpha = 0.5,
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
      pfeats<- mean(vi$importance!=0)*100
  
      df <- data.frame(roi=name, 
                       accuracy=perf$TrainAccuracy, kappa=perf$TrainKappa, 
                       alpha=tune$alpha, lambda=tune$lambda, 
                       percent.features=pfeats)

      df
    })
    
    data.frame(runtype=runtype, subject=subject, res)
  })
})


# Now we can run the combined model
res.c <- ldply(runtypes[1], function(runtype) {
  cat("\n\n====\n")
  cat("Runtype:", runtype, "\n")
  ldply(subjects, function(subject) {
    cat("\n==", subject, "==\n")
    sdir    <- file.path(base, "analysis/subjects", subject, runtype)

    # Read in all the roi and condition data
    # This time, we combine the data!
    lst.dat <- llply(srois2, function(iroi) {
      ldply(conds, function(cond) {
        tsfile  <- file.path(sdir, "ts", sprintf("bs_classify_probpeaks_%s_%03i.1D", cond, orois2[iroi]))
        dat     <- read.table(tsfile)
        data.frame(lab=rep(cond,nrow(dat)), dat)
      })
    })
    names(lst.dat) <- scols2

    # Combine the data from the two ROIs
    name  <- sprintf("%s and %s", snames2[1], snames2[2])
    x     <- cbind(as.matrix(lst.dat$l.ffa[,-1]), as.matrix(lst.dat$l.vatl[,-1]))
    ylabs <- lst.dat$l.ffa$lab
    ys    <- 2-as.numeric(ylabs)

    # For GLMNet, get the range of lambdas this way
    # for alphas with 0, 0.1, 0.5, and 1, I get the collection of 
    # autodetermined lambdas
    tmp <- glmnet(x, ylabs, family="binomial", nlambda=100, alpha=1)
    lambdas <- tmp$lambda
    
    # Tuning Grids
    grids <-  list(
      # alpha=1 is the lasso penalty and alpha=0 is the ridge penalty
      # lambda the amount of regularization
      glmnet=expand.grid(alpha = 1,
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
    pfeats<- mean(vi$importance!=0)*100

    df <- data.frame(runtype=runtype, subject=subject, roi=name, 
                     accuracy=perf$TrainAccuracy, kappa=perf$TrainKappa, 
                     alpha=tune$alpha, lambda=tune$lambda, 
                     percent.features=pfeats)

    df
  })
})

res.c <- ldply(runtypes[1], function(runtype) {
  cat("\n\n====\n")
  cat("Runtype:", runtype, "\n")
  ldply(subjects, function(subject) {
    cat("\n==", subject, "==\n")
    sdir    <- file.path(base, "analysis/subjects", subject, runtype)

    # Read in all the roi and condition data
    # This time, we combine the data!
    lst.dat <- llply(srois2, function(iroi) {
      ldply(conds, function(cond) {
        tsfile  <- file.path(sdir, "ts", sprintf("bs_classify_probpeaks_%s_%03i.1D", cond, orois2[iroi]))
        dat     <- read.table(tsfile)
        data.frame(lab=rep(cond,nrow(dat)), dat)
      })
    })
    names(lst.dat) <- scols2
    
    # Determine features to keep for each roi
    # Now loop through the rois and do the classification
    #tmp <- list()
    filt <- llply(srois2, function(iroi) {
      dat   <- lst.dat[[iroi]]
      name  <- snames2[iroi]
      cat(name, "\n")
  
      x     <- as.matrix(dat[,-1])
      ylabs <- dat$lab
      ys    <- 2-as.numeric(ylabs)

      # For GLMNet, get the range of lambdas this way
      # for alphas with 0, 0.1, 0.5, and 1, I get the collection of 
      # autodetermined lambdas
      tmp <- glmnet(x, ylabs, family="binomial", nlambda=100, alpha=1)
      lambdas <- tmp$lambda
      
      # Tuning Grids
      grids <-  list(
        # alpha=1 is the lasso penalty and alpha=0 is the ridge penalty
        # lambda the amount of regularization
        glmnet=expand.grid(alpha = 1,
                           lambda = lambdas)
      )

      # Fit model
      method <- "glmnet"
      fit <- train(scale(x), ylabs, 
                   method = method,
                   trControl = fitControl, 
                   tuneGrid = grids[[method]])
       #perf  <- getTrainPerf(fit)
       #tune  <- fit$bestTune
       #vi    <- varImp(fit, scale=F)
       #pfeats<- mean(vi$importance$Overall!=0)*100
       #nfeats<- sum(vi$importance$overall!=0)
       #df <- data.frame(roi=name, 
       #                 accuracy=perf$TrainAccuracy, 
       #                 perc.features=pfeats, 
       #                 n.features=nfeats)
       #tmp[[iroi]] <- df
      vi    <- varImp(fit, scale=F)
      vi$importance!=0
    })
    names(filt) <- scols2
    
    # Combine the data from the two ROIs
    name  <- sprintf("%s and %s", snames2[1], snames2[2])
    cat(name, "\n")
    x     <- cbind(as.matrix(lst.dat$l.ffa[,-1][,filt$l.ffa]), as.matrix(lst.dat$l.vatl[,-1][,filt$l.vatl]))
    ylabs <- lst.dat$l.ffa$lab
    ys    <- 2-as.numeric(ylabs)

    # For GLMNet, get the range of lambdas this way
    # for alphas with 0, 0.1, 0.5, and 1, I get the collection of 
    # autodetermined lambdas
    tmp <- glmnet(x, ylabs, family="binomial", nlambda=100, alpha=1)
    lambdas <- tmp$lambda
    
    # Tuning Grids
    grids <-  list(
      # alpha=1 is the lasso penalty and alpha=0 is the ridge penalty
      # lambda the amount of regularization
      glmnet=expand.grid(alpha = 1,
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
    ## get the betas for the final model
    ## previously get errors (e.g., tb9325)
    ## so here we refit the glmnet with the selected parameters
    refit <- glmnet(x, ylabs, family="binomial", lambda=tune$lambda, alpha=tune$alpha)
    betas <- as.numeric(refit$beta)
    
    #ind   <- which(fit$finalModel$lambda == fit$bestTune$lambda)
    #if (length(ind)==0) {
    #  vi    <- varImp(fit, scale=F)
    #  betas <- vi$importance$Overall
    #} else {
    #  betas <- as.numeric(fit$finalModel$beta[,ind])
    #}
    
    pfeats<- mean(betas!=0)*100
    fac  <- rep(c("ffa", "vatl"), c(sum(filt$l.ffa), sum(filt$l.vatl)))
    ck   <- prop.table(table(fac, factor(betas!=0, c(F,T))), 1)[,2]*100
    names(ck) <- c("perc.ffa", "perc.vatl")
    
    df <- data.frame(runtype=runtype, subject=subject, roi=name, 
                     accuracy=perf$TrainAccuracy, kappa=perf$TrainKappa, 
                     alpha=tune$alpha, lambda=tune$lambda, 
                     perc.features=pfeats, perc.ffa=ck[1], perc.vatl=ck[2])

    df
  })
})

tmp <- round(ffa=cbind(subset(res1, roi=="L FFA")$accuracy, vatl=subset(res1, roi=="L vATL")$accuracy, comb=res.c$accuracy), 2)*100
t.test(tmp[,3] - apply(tmp[,-3], 1, max))


# group lasso
# would want to see if either regions set of voxels gets booted off
library(gglasso)
y <- ys*2 - 1
group <- rep(1:2, c(sum(filt$l.ffa), sum(filt$l.vatl)))
cv <- cv.gglasso(x=x, y=y, group=group, loss="logit", pred.loss="misclass", nfolds=10, lambda.factor=0.05)
betas <- cv$gglasso.fit$beta[,cv$lambda==cv$lambda.min]
names(betas) <- group

# interaction terms
library(hierNet)
fit <- hierNet.logistic.path(x,ys)
fitcv <- hierNet.cv(fit, x, ys, nfolds=10, folds=NULL, trace=0)
print(fitcv)
## get the lowestish lambda with smallest non-zero values
minerr <- round(min(fitcv$cv.err), 2)
minnz  <- min(fitcv$nonzero[round(fitcv$cv.err, 2)==minerr])
ind    <- which(round(fitcv$cv.err, 2)==minerr & fitcv$nonzero==minnz)
lambda <- fitcv$lamlist[ind]
# get the interaction terms
th     <- fit$th[,,ind]
dimnames(th) <- list(vox=fac, vox=fac)
## or i could glasso the interactions too?
## the idea here is if we get lots of btw region interactions, then whenever there is co-activation
## that is important to help classify the results
