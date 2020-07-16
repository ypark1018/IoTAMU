#Calculate performance statistics

library(ggplot2)

#calculate precision
precision <- function(tp, fp){
  return(100 * tp/(tp+fp))
}
#calculate recall
recall <- function(tp, fn){
  return(100 * tp/(tp+fn))
}
#calculate specificity
specificity <- function(tn, fp){
  return(100 * tn/(tn+fp))
}

#######################
# EXP 1
#######################

#threshold 0.9 results
tp = 3
tn = 52
fp = 0
fn = 0
precision(tp, fp)
recall(tp, fn)
specificity(tn, fp)

#threshold 0.8 results
tp = 3
tn = 51
fp = 1
fn = 0
precision(tp, fp)
recall(tp, fn)
specificity(tn, fp)

#threshold 0.7 results
tp = 3
tn = 47
fp = 5
fn = 0
precision(tp, fp)
recall(tp, fn)
specificity(tn, fp)

#######################
# EXP 2
#######################
# 11 samples
#threshold 0.9 results
tp = 0
tn = 51
fp = 1
fn = 3
precision(tp, fp)
recall(tp, fn)
specificity(tn, fp)

#threshold 0.8 results
tp = 2
tn = 50
fp = 2
fn = 1
precision(tp, fp)
recall(tp, fn)
specificity(tn, fp)

#threshold 0.7 results
tp = 2
tn = 46
fp = 6
fn = 1
precision(tp, fp)
recall(tp, fn)
specificity(tn, fp)

# 120 samples
#threshold 0.9 results
tp = 0
tn = 52
fp = 0
fn = 3
precision(tp, fp)
recall(tp, fn)
specificity(tn, fp)

#threshold 0.8 results
tp = 1
tn = 52
fp = 0
fn = 2
precision(tp, fp)
recall(tp, fn)
specificity(tn, fp)

#threshold 0.7 results
tp = 2
tn = 52
fp = 0
fn = 1
precision(tp, fp)
recall(tp, fn)
specificity(tn, fp)

# Calculate PSD
#exp1 <- devices.dist #SS matrix from experiment 1
ss1 <- ss(exp1)
#exp2.1 <- devices.dist #SS matrix from experiment 2 with 11 samples
ss2.1 <- ss(exp2.1)
#exp2.2 <- devices.dist #SS matrix from experiment 2 with 120 samples
ss2.2 <- ss(exp2.2)

#create dataframe for analysis
dist.df <- data.frame(rbind(cbind(exp1, 0), cbind(exp2.1, 11), cbind(exp2.2, 120)))
colnames(dist.df) <- c("Distance", "Treatment")
dist.df$Treatment <- factor(dist.df$Treatment)
dist.df$Device <- "Other"
dist.df$Device[c(1, 35, 50, 56, 90, 105, 111, 145, 160)] <- c("C1 ~ CT", "LB1 ~ LBT", "S1 ~ ST", "C1 ~ CT", "LB1 ~ LBT", "S1 ~ ST", "C1 ~ CT", "LB1 ~ LBT", "S1 ~ ST")
dist.df$Device <- factor(dist.df$Device, levels = c("C1 ~ CT", "LB1 ~ LBT", "S1 ~ ST", "Other"))

#perform ANOVA on PSD for 0, 11, 120 spoofed as treatments
dist.aov <- aov(Distance~Treatment, dist.df)
dist.aov %>% TukeyHSD %>% tidy
#verify QQ plot
qqnorm(dist.aov$residuals)
qqline(dist.aov$residuals)
#verify residuals
dist.df$Residuals <- dist.aov$residuals
p <- ggplot(dist.df, aes(x = Treatment, y = Residuals)) + geom_point(color="steelblue")
p <- p + theme_bw() + theme(panel.grid.minor = element_blank())
plot(p)

#calculate mean PSD for each treatment
means <- aggregate(Distance~Treatment, dist.df, mean)

#create boxplot of PSD for each number of samples spoofed
p <- ggplot(dist.df, aes(Treatment, Distance)) + geom_boxplot(notch=TRUE, colour = "steelblue", outlier.shape = NA) + geom_jitter(width=0.2, aes(color = Device)) + coord_flip()
p <- p + theme_bw() + theme(panel.grid.minor = element_blank())
p <- p + labs(x = "Number of Samples Spoofed", y = "Pairwise Signature Distance") + scale_color_manual(values=c("#00FF00", "#E69F00", "#ff0000", "#999999"))
p <- p + theme(legend.position="bottom")
plot(p)
