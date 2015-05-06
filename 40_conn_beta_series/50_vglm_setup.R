# Outputs the regressors and contrasts

df <- read.csv("model_bio_vs_phys.csv")
df <- df[,-1]
nscans <- 2
subs <- sort(unique(df$subjects))
conds <- levels(df$conditions)

regressors <- matrix(0, length(subs)*nscans, length(subs))
for (i in subs) regressors[df$subjects==i,i] <- 1
regressors <- cbind(regressors, rep(c(1,-1), each=length(subs)))
colnames(regressors) <- c(sprintf("sub%02i", subs), "biophys")
write.table(regressors, file="y_glm_regressors.txt", quote=F)

cons <- regressors[1:2,]
cons[,] <- 0
cons[1,17] <- 1
cons[2,17] <- -1
rownames(cons) <- c("bio_gt_phys", "phys_gt_bio")
write.table(cons, file="y_glm_contrasts.txt", quote=F)