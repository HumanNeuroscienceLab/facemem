#' We end up generating the probatlas peaks for XXX.

#' # Functions
#+ functions
setwd("/Users/czarrar/Dropbox/Research/facemem/connpaper/22_eventstats")
source("eventstats_funcs.R")
sle <- function(x){
  if(!is.numeric(x)) x <- as.numeric(x)
  n <- length(x)
  y <- x[-1L] != x[-n] + 1L
  i <- c(which(y|is.na(y)),n)
  list(
    lengths = diff(c(0L,i)),
    values = x[head(c(0L,i)+1L,-1L)]
  ) 
}

#' # Setup
#+ setup
library(plyr)
subjects <- sub("_Questions_timing.txt", "", 
                list.files("~/Dropbox/Research/facemem/data/ts", 
                           pattern="_Questions_timing.txt"))
runtypes <- c("Questions", "NoQuestions")
rois     <- c("postask", "probatlas", "overlap")

#' # Selecting the relevant nodes for each ROI set
#' 
#' First we set the `postask` ones and then the `probatlas`.
#' And I've just added the `overlap` peaks.
#+ select
srois <- c(
  2,   # L vATL
  5,   # L PHC
  4,   # L RSC
  40,   # R PCC
  16,  # L dACC
  7,   # R dACC
  17,  # B midCC
  31,  # L fOp/Ins
  25,  # R fOp/Ins
  8,   # L fOrb
  30  # R fOrb
)
snames <- c("R vATL", "L PHC", "L RSC", "R RSC", 
             "L dACC", "R dACC", "B midCC", "L fOp/Ins", "R fOp/Ins", 
             "L fOrb", "R fOrb")


#' # Load the Data
#' 
#' This will load the data for each subject and then calculate the average 
#' response for each subject and each condition using smoothed splines. The 
#' smoothed response and standard error is what is saved into a data frame.
#' 
#' Note that the timing files are saved as 'txt' files but are actually csvs.
#' 
#+ load
orig_rois <- rois
rois      <- "overlap"
all.df <- ldply(rois, function(roi) {
  ldply(runtypes, function(runtype) {
    tmp <- ldply(subjects, function(subject) {
      # Load the data
      # ret <- list(trial=matrix(trial x time x region), timing, ntpts)
      lst.dat <- load.data(subject, runtype, roi, 
                           basedir="~/Dropbox/Research/facemem/data/ts", 
                           prestim=5, poststim=19)
      
      # Remove the baseline
      lst.dat <- remove.baseline(lst.dat, baseline.tpts=-3:-1)
      ## to check
      ## round(as.numeric(apply(lst.dat$trial[,3:5,4], 1, mean), 2))
      
      # Get the mean time-series per condition via a smoothed fit
      ave.df  <- smoothed.average.by.condition(lst.dat, new.tr=0.5)
      
      # Yeah you actually want to do sometype of regression...
      # or I guess you can get the AUC for each condition (given onset & offset)
      
      # Now get the area under the curve of the smoothed fit
      auc.df <- ddply(ave.df, .(condition, region), function(x) {
        c(auc=auc.hdr(x$mean, x$tpts))
      })
      
      # Return dataframe with additional information
      cbind(data.frame(
        roi.set = roi, 
        runtype = runtype, 
        subject = subject
      ), ave.df)
    }, .progress="text")
  })
})

#' ## Average (across subjects) within each condition
#'
#' For actual plotting, we'll want to calculate the average response across 
#' participants.
#' 
#' Note that agreement of 13/16 is significant (p=0.02) with binomial test
#' 
#+ load-average
all.ave.df <- ddply(all.df, .(roi.set, runtype, region, condition, tpts), function(x) {
  res <- t.test(x$mean)
  agree <- max(table(sign(x$mean)))/nrow(x)
  c(response=mean(x$mean), pval=res$p.value, agree=agree)
})

#' ## Difference between conditions
#' 
#' Here we calculate the significance of the difference between conditions.
#' 
#' Note that agreement of 13/16 is significant (p=0.02) with binomial test.
#+ 
all.diff.df <- ddply(all.df, .(roi.set, runtype, region, tpts), function(x) {
  res <- t.test(mean ~ condition, data=x, paired=T)
  diff <- daply(x, .(subject), function(x) diff(x$mean))
  agree <- max(table(sign(diff)))/length(diff)
  c(diff=as.numeric(res$estimate), tval=res$statistic, pval=res$p.value, agree=agree)
})

#' # Load and Visualize
#' 
#+ viz_setup
library(ggplot2)
library(grid)
library(RColorBrewer)
cols <- brewer.pal(length(snames[[1]]), "Set1")
cols <- add.alpha(rep(cols, each=2), alpha=0.3)
cols2 <- brewer.pal(8, "Dark2")[c(1,4,3)] # Questions, NoQuestions, and Overlap

#+ viz_test
#sdf <- subset(all.ave.df, roi.set=="postask" & runtype=="NoQuestions" & region=="vATL")
#sdf <- subset(all.ave.df, roi.set=="probatlas" & runtype=="Questions" & region=="FFA")
#sdf <- subset(all.ave.df, roi.set=="postask")
#ggplot(sdf, aes(x=tpts, y=response, color=condition)) + 
#  geom_line() #+ 
#  #facet_grid(runtype ~ region, scales="free")

#+ viz_theme
fte_theme <- function() {
  # Colors
  color.background = "#F0F0F0"
  color.grid.major = "#D0D0D0"
  color.axis.text = "#535353"
  color.axis.title = "#535353"
  color.title = "#3C3C3C"
  
  # Begin construction of chart
  theme_bw() +
    
    # Set the entire chart region to a light gray color
    theme(panel.background=element_rect(fill=color.background, color=color.background)) +
    theme(plot.background=element_rect(fill=color.background, color=color.background)) +
    theme(panel.border=element_rect(color=color.background)) +
    
    # Format the grid
    theme(panel.grid.major=element_line(color=color.grid.major,size=.75)) +
    theme(panel.grid.minor=element_blank()) +
    theme(axis.ticks=element_blank()) +
    
    # Format the legend, but hide by default
    theme(legend.position="none") +
    theme(legend.background = element_rect(fill=color.background)) +
    theme(legend.text = element_text(size=11,color=color.axis.title)) +
    
    # Set title and axis labels, and format these and tick marks
    theme(plot.title=element_text(face="bold",color=color.title,size=24,vjust=2)) + #hjust=-0.08
    theme(axis.text.x=element_text(face="bold",size=17,color=color.axis.text)) +
    theme(axis.text.y=element_text(face="bold",size=17,color=color.axis.text)) +
    theme(axis.title.x=element_text(face="bold",size=18,color=color.axis.title, vjust=-.5)) +
    theme(axis.title.y=element_text(face="bold",size=18,color=color.axis.title, vjust=1.5)) +
    
    # Plot margins
    theme(plot.margin = unit(c(1, 1, .7, .7), "cm"))
}

#' We want to create a data frame with all the significant time-points that are
#' not in the baseline period.
#+ viz_plot_setup
sdf  <- subset(all.ave.df, roi.set=="overlap")
sdf2 <- subset(all.diff.df, roi.set=="overlap" & pval<0.05 & tpts>-1)
# Split the two lines up in order to show the shading between them
split.sdf <- data.frame(
  runtype = subset(sdf, condition=="bio")$runtype, 
  region = subset(sdf, condition=="bio")$region, 
  tpts = subset(sdf, condition=="bio")$tpts, 
  bio  = subset(sdf, condition=="bio")$response, 
  phys = subset(sdf, condition=="phys")$response, 
  response = 0.05 # not sure why i need to do this...
)

#+ viz_plot_all, fig.width=12, fig.height=6
p <- ggplot(sdf, aes(x=tpts, y=response)) +
  #geom_ribbon(data=split.sdf, aes(ymin=phys, ymax=bio), fill="grey", alpha=0.5) + 
  geom_line(aes(color=condition), size=1.6) + 
  scale_x_continuous(minor_breaks=0,breaks=seq(-4,20,4),limits=c(-5,20)) + 
  geom_vline(xintercept=0,size=0.9,colour="#535353",lty=2) +
  geom_hline(yintercept=0,size=1.2,colour="#535353") +
  ylab("Percent Signal Change") +
  xlab("Time (s)") + 
  #ggtitle("Some Random Data I Made") +
  facet_grid(runtype ~ region, scales="free_y") + 
  fte_theme()
print(p)

#' Plot each one individually
#+ viz_plot_indiv, fig.width=6, fig.height=4
outpath <- "~/Dropbox/Research/facemem/paper/figures/fig_04/es_plots"
d_ply(sdf, .(runtype, region), function(x) {
  #x <- dlply(sdf, .(runtype, region), function(x) x)[[7]]  
  cruntype <- as.character(x$runtype[1])
  cregion <- as.character(x$region[1])
  
  # Get subset of data for shading time-points with differences between conditions
  split.sdf2 <- subset(split.sdf, runtype==cruntype & region==cregion)
  sig.sdf2   <- subset(sdf2, runtype==cruntype & region==cregion)
  
  # Initial plot
  p <- ggplot(x, aes(x=tpts, y=response))
  
  if (nrow(sig.sdf2) != 0) {
    # Plot the difference for each continuous section
    sig.pts <- which(split.sdf2$tpts %in% sig.sdf2$tpts)
    runs <- sle(sig.pts)
    for (i in 1:length(runs$values)) {
      start.i <- sig.pts[sig.pts==runs$values[i]]
      end.i   <- start.i + runs$lengths[i] - 1
      p <- p + 
        geom_ribbon(data=split.sdf2[start.i:end.i,], aes(ymin=phys, ymax=bio), 
                    fill="grey", alpha=0.7)
    }
  }
  
  p <- p +
    geom_line(aes(color=condition), size=1.6) + 
    scale_x_continuous(minor_breaks=0,breaks=seq(-4,20,4),limits=c(-5,20)) + 
    geom_vline(xintercept=0,size=0.9,colour="#535353",lty=2) +
    geom_hline(yintercept=0,size=1.2,colour="#535353") +
    ylab("% Signal Change") +
    xlab("Time (s)") + 
    #ggtitle("Some Random Data I Made") +
    fte_theme() + 
    theme(axis.title.x=element_blank()) + 
    theme(axis.title.y=element_blank())
  
  print(p)
  
  fname <- sprintf("%s/%s_%s.png", outpath, cruntype, cregion)
  fname <- sub("fOp/Ins", "fOp-Ins", fname)
  ggsave(fname, p, width=5, height=2.5)
})

region.name <- "R vATL-post"
runtype <- "Question"
sdf  <- subset(all.ave.df, roi.set=="probatlas" & runtype==runtype & region==region.name)

# Start up the basic plot
p <- ggplot(sdf, aes(x=tpts, y=response))
# Split the two lines up in order to show the shading between them
split.sdf <- data.frame(
  tpts = subset(sdf, condition=="bio")$tpts, 
  bio  = subset(sdf, condition=="bio")$response, 
  phys = subset(sdf, condition=="phys")$response, 
  response = 0.05 # not sure why i need to do this...
)
# Only have shading for time-points with significant differences
sdf2     <- subset(all.diff.df, roi.set=="probatlas" & runtype==runtype & region==region.name)
sig.pts  <- which(sdf2$pval<0.05 & sdf2$tpts>(-1))
# And only add the shading if there are any significant differences
if (length(sig.pts) > 0) {
  runs <- sle(sig.pts)
  for (i in 1:length(runs$values)) {
    start.i <- sig.pts[sig.pts==runs$values[i]]
    end.i   <- start.i + runs$lengths[i] - 1
    p <- p + 
      geom_ribbon(data=split.sdf[start.i:end.i,], aes(ymin=phys, ymax=bio), 
                  fill="grey", alpha=0.5)
  }
}
# Plot everything else now
p <- p +
  geom_line(aes(color=condition), size=1.6) + 
  scale_x_continuous(minor_breaks=0,breaks=seq(-4,20,4),limits=c(-5,20)) +
  geom_vline(xintercept=0,size=0.9,colour="#535353",lty=2) +
  geom_hline(yintercept=0,size=1.2,colour="#535353") +
  ylab("Percent Signal Change") +
  xlab("Time (s)") + 
  #ggtitle("Some Random Data I Made") +
  fte_theme()
print(p)
print(sig.pts)

#+ viz-sig

#' We also make individual plots for each for pages.
