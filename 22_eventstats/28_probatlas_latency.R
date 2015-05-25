# This script will read in the prob atlas ROIs and get the latency information

###
# Setup

setwd("/Users/czarrar/Dropbox/Research/facemem/connpaper/22_eventstats")

library(plyr)
source("eventstats_funcs.R")

subjects <- sub("_Questions_timing.txt", "", 
                list.files("~/Dropbox/Research/facemem/data/ts", 
                           pattern="_Questions_timing.txt"))
runtypes <- c("Questions", "NoQuestions")


###
# ROI Info

roi   <- "probatlas"
srois <- c(
  3,  # R OFA
  1,  # R FFA
  69, # R vATL (post)
  32, # R vATL (ant)
  8,  # L OFA
  2,  # L FFA
  62, # L vATL (post)
  26  # L vATL (ant)
)
snames <- c("R IOG", "R mFus", "R aFus", "R vATL", 
            "L IOG", "L mFus", "L aFus", "L vATL")


###
# Load the Data

all.df <- ldply(runtypes, function(runtype) {
  ldply(subjects, function(subject) {
    # Load the data
    # ret <- list(trial=matrix(trial x time x region), timing, ntpts)
    lst.dat <- load.data(subject, runtype, roi, 
                         basedir="~/Dropbox/Research/facemem/data/ts", 
                         prestim=5, poststim=19, 
                         select.nodes=srois, node.names=snames)
    
    # Remove the baseline
    lst.dat <- remove.baseline(lst.dat, baseline.tpts=-2:0)
    ## to check
    ## round(as.numeric(apply(lst.dat$trial[,3:5,4], 1, mean), 2))
    
    # Get the mean time-series per condition via a smoothed fit
    ave.df  <- smoothed.average.by.condition(lst.dat, new.tr=0.2)
    
    # Return dataframe with additional information
    cbind(data.frame(
      runtype = runtype, 
      subject = subject
    ), ave.df)
  }, .progress="text")
})


###
# Average across trials and Difference

# Average
all.ave.df <- ddply(all.df, .(runtype, region, condition, tpts), function(x) {
  res <- t.test(x$mean)
  agree <- max(table(sign(x$mean)))/nrow(x)
  c(response=mean(x$mean), pval=res$p.value, agree=agree)
})

# Difference
# Note that 13/16 agreement is significant
all.diff.df <- ddply(all.df, .(runtype, region, tpts), function(x) {
  res <- t.test(mean ~ condition, data=x, paired=T)
  res2 <- wilcox.test(mean ~ condition, data=x, paired=T)
  diff <- daply(x, .(subject), function(x) diff(x$mean))
  agree <- max(table(sign(diff)))/length(diff)
  c(diff=as.numeric(res$estimate), tval=res$statistic, pval=res$p.value, pval2=res2$p.value, agree=agree)
})
# get the significant ones (to report!)
subset(all.diff.df, runtype=="Questions" & pval<0.05 & tpts>0)
subset(all.diff.df, runtype=="Questions" & pval2<0.05 & tpts>0)

# Plot the average
library(ggplot2)
ggplot(all.ave.df, aes(x=tpts, y=response)) +
  geom_line(aes(color=condition), size=1.6) + 
  scale_x_continuous(minor_breaks=0,breaks=seq(-4,20,4),limits=c(-5,20)) + 
  geom_vline(xintercept=0,size=0.9,colour="#535353",lty=2) +
  geom_hline(yintercept=0,size=1.2,colour="#535353") +
  ylab("Percent Signal Change") +
  xlab("Time (s)") + 
  facet_grid(runtype ~ region, scales="free_y")
## plot just questions
ggplot(subset(all.ave.df, runtype=="Questions"), aes(x=tpts, y=response)) +
  geom_line(aes(color=condition), size=1.6) + 
  scale_x_continuous(minor_breaks=0,breaks=seq(-4,20,4),limits=c(-5,20)) + 
  geom_vline(xintercept=0,size=0.9,colour="#535353",lty=2) +
  geom_hline(yintercept=0,size=1.2,colour="#535353") +
  ylab("Percent Signal Change") +
  xlab("Time (s)") + 
  facet_grid(. ~ region, scales="free_y")
ggplot(subset(all.ave.df, runtype=="Questions" & region%in%c("L FFA", "L vATL")), aes(x=tpts, y=response)) +
  geom_line(aes(color=condition), size=1.6) + 
  scale_x_continuous(minor_breaks=0,breaks=seq(-4,20,4),limits=c(-5,20)) + 
  geom_vline(xintercept=0,size=0.9,colour="#535353",lty=2) +
  geom_hline(yintercept=0,size=1.2,colour="#535353") +
  ylab("Percent Signal Change") +
  xlab("Time (s)") + 
  facet_grid(. ~ region, scales="free_y")

# Better Theme
bar_theme <- function() {
  library(grid)
  # Colors
  color.background = "#F0F0F0"
  color.grid.major = "#D0D0D0"
  color.axis.text = "#535353"
  color.axis.title = "#535353"
  color.title = "#3C3C3C"
  
  # Begin construction of chart
  theme_bw() +
    
    # Set the entire chart region to a light gray color
    #theme(panel.background=element_rect(fill=color.background, color=color.background)) +
    #theme(plot.background=element_rect(fill=color.background, color=color.background)) +
    theme(panel.border=element_rect(color="grey")) +
    
    # Format the grid
    theme(panel.grid.major.y=element_line(color=color.grid.major,size=.75)) +
    theme(panel.grid.major.x=element_blank()) +
    theme(panel.grid.minor=element_blank()) +
    theme(axis.ticks.x=element_blank()) +
    
    # Format the legend, but hide by default
    #theme(legend.position="none") +
    #theme(legend.background = element_rect(fill=color.background)) +
    theme(legend.text = element_text(size=16,color=color.axis.title)) +
    
    # Set title and axis labels, and format these and tick marks
    theme(plot.title=element_text(face="bold",color=color.title,size=24,vjust=2)) + #hjust=-0.08
    theme(axis.text.x=element_text(face="bold",size=17,color=color.axis.text)) +
    theme(axis.text.y=element_text(face="bold",size=17,color=color.axis.text)) +
    theme(axis.title.x=element_text(face="bold",size=18,color=color.axis.title, vjust=-.5)) +
    theme(axis.title.y=element_text(face="bold",size=18,color=color.axis.title, vjust=1.5)) +
    
    # Plot margins
    theme(plot.margin = unit(c(1, 1, .7, .7), "cm"))
}

###
# Get the latency measures

source("param_funcs.R")

tmp <- subset(all.ave.df, runtype=="Questions" & region=="R FFA" & condition=="bio")
plot(tmp$tpts, tmp$response, type='l')
get_parameters(tmp$response, tmp$tpts, baseline.time=c(-3,-1), to.plot=T)

# get for group average
res <- ddply(all.ave.df, .(runtype, region, condition), function(x) {
  params <- get_parameters(x$response, x$tpts, baseline.time=c(-1,0), to.plot=F)
  data.frame(runtype=x$runtype[1], region=x$region[1], condition=x$condition[1], params)
})
# get for each subject
sres <- ddply(all.df, .(runtype, subject, region, condition), function(x) {
  #cat(as.character(x$subject[1]), as.character(x$runtype[1]), as.character(x$region[1]), as.character(x$condition[1]), "\n")
  params <- get_parameters(x$mean, x$tpts, baseline.time=c(-1,0), to.plot=F)
  if (length(params$onset)==0) params$onset <- NA
  if (length(params$width)==0) params$width <- NA
  data.frame(subject=x$subject[1], runtype=x$runtype[1], region=x$region[1], condition=x$condition[1], 
             height=params$height, peak=params$peak, width=params$width, onset=params$onset)
})

# significance test
# nothing but L FFA is the largest difference [maybe if use 0.1...]
sig.sres <- ddply(sres, .(runtype, region), function(x) {
  y <- t.test(peak~condition, paired=T, data=x)
  y2<- wilcox.test(peak~condition, paired=T, data=x)
  c(t=y$statistic, p=y$p.value, p2=y2$p.value)
})
ave.sres <- ddply(sres, .(runtype, region, condition), colwise(mean, .(height, peak)))
ave.sres[,4:5] <- round(ave.sres[,4:5], 2)
subset(ave.sres, runtype=="Questions")
sd.sres <- ddply(sres, .(runtype, region, condition), colwise(sd, .(height, peak)))
## for plotting
mat <- data.frame(
  region=subset(ave.sres, runtype=="Questions" & condition=="bio")$region, 
  bio=subset(ave.sres, runtype=="Questions" & condition=="bio")$peak,
  phys=subset(ave.sres, runtype=="Questions" & condition=="phys")$peak, 
  se.bio=subset(sd.sres, runtype=="Questions" & condition=="bio")$peak/sqrt(16),
  se.phys=subset(sd.sres, runtype=="Questions" & condition=="phys")$peak/sqrt(16), 
  sig=subset(sig.sres, runtype=="Questions")$p
)
write.table(mat, row.names=F, sep="\t", quote=F) # copy and paste into numbers

# Can we test if we exclude the L aFus and L vATL will we find significant 
# effects? No that isn't significant.
t.test(peak~condition, paired=T, 
       data=subset(sres, !(region %in% c("L aFus", "L vATL")) & runtype=="Questions"))

# Get significance estimates for the onset latency
## note didn't find anything that was significant
tmp <- ddply(sres, .(runtype, region), function(x) {
  bio <- subset(x, condition=="bio")$onset
  phy <- subset(x, condition=="phys")$onset
  inds <- !is.na(bio) | !is.na(phy)
  y <- t.test(bio[inds], phy[inds], paired=T)
  y2<- wilcox.test(bio[inds], phy[inds], paired=T)
  c(t=y$statistic, p=y$p.value, p2=y2$p.value)
})
subset(tmp, runtype=="Questions")

# tests between rois (nope, doesn't yield much)
x1 <- subset(sres, runtype=="Questions" & region=="R vATL")$peak
x2 <- subset(sres, runtype=="Questions" & region=="R FFA")$peak
t.test(x1, x2, paired=T)

# Peak Latency
ggplot(res, aes(x=region, y=peak, fill=condition)) +
  geom_bar(position="dodge", stat="identity") + 
  facet_grid(runtype ~ .) +
  coord_cartesian(ylim = range(res$peak) + c(-1,0.5))  + 
  ylab("Peak Latency (secs)") + 
  ggtitle("Peak Latency") +
  bar_theme() + 
  theme(
    axis.title.x = element_blank()
  )

# Width
ggplot(res, aes(x=region, y=width, fill=condition)) +
  geom_bar(position="dodge", stat="identity") + 
  facet_grid(runtype ~ .) +
  coord_cartesian(ylim = range(res$width) + c(-1,0.5))  + 
  ylab("Width at FWHM (secs)") + 
  ggtitle("Width") +
  bar_theme() + 
  theme(
    axis.title.x = element_blank()
  )

# Onset
ggplot(res, aes(x=region, y=onset, fill=condition)) +
  geom_bar(position="dodge", stat="identity") + 
  facet_grid(runtype ~ .) +
  #coord_cartesian(ylim = range(res$onset) + c(-1,0.5))  + 
  geom_hline(yintercept=0) + 
  ylab("Onset Latency (secs)") + 
  ggtitle("Onset") +
  bar_theme() + 
  theme(
    axis.title.x = element_blank()
  )

# Height
ggplot(res, aes(x=region, y=height, fill=condition)) +
  geom_bar(position="dodge", stat="identity") + 
  facet_grid(runtype ~ .) +
  #coord_cartesian(ylim = range(res$height) + c(-1,0.5))  + 
  ylab("Peak % signal change") + 
  ggtitle("Peak") +
  bar_theme() + 
  theme(
    axis.title.x = element_blank()
  )

# I want to check how good the spline fit was compared to the actual average
all.df2 <- ldply(runtypes, function(runtype) {
  ldply(subjects, function(subject) {
    # Load the data
    # ret <- list(trial=matrix(trial x time x region), timing, ntpts)
    lst.dat <- load.data(subject, runtype, roi, 
                         basedir="~/Dropbox/Research/facemem/data/ts", 
                         prestim=5, poststim=19, 
                         select.nodes=srois, node.names=snames)
    
    # Remove the baseline
    lst.dat <- remove.baseline(lst.dat, baseline.tpts=-3:-1)
    ## to check
    ## round(as.numeric(apply(lst.dat$trial[,3:5,4], 1, mean), 2))
    
    # Get the mean time-series per condition via a smoothed fit
    ave.df  <- average.by.condition(lst.dat)
    
    # Return dataframe with additional information
    cbind(data.frame(
      runtype = runtype, 
      subject = subject
    ), ave.df)
  }, .progress="text")
})

all.ave.df2 <- ddply(all.df2, .(runtype, region, condition, tpts), function(x) {
  #agree <- max(table(sign(x$mean)))/nrow(x)
  #c(response=mean(x$mean), agree=agree)
  c(response=mean(x$mean), len=length(x$mean))
})

tmp <- subset(all.ave.df, runtype=="Questions" & region=="L FFA" & condition=="bio")
plot(tmp$tpts, tmp$response, type='l')
#get_parameters(tmp$response, tmp$tpts, baseline.time=c(-3,-1), to.plot=T)
tmp2 <- subset(all.ave.df2, runtype=="Questions" & region=="L FFA" & condition=="bio")
lines(tmp2$tpts, tmp2$response, col='red')

# Plot theme together
ggplot(subset(all.ave.df, condition=="bio"), aes(x=tpts, y=response)) +
  geom_line(aes(color=condition), size=1.6) + 
  geom_line(data=subset(all.ave.df2, condition=="bio")) +
  scale_x_continuous(minor_breaks=0,breaks=seq(-4,20,4),limits=c(-5,20)) + 
  geom_vline(xintercept=0,size=0.9,colour="#535353",lty=2) +
  geom_hline(yintercept=0,size=1.2,colour="#535353") +
  ylab("Percent Signal Change") +
  xlab("Time (s)") + 
  facet_grid(runtype ~ region, scales="free_y")


# TODO: try that polynomial regression instead?
