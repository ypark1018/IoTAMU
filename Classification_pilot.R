#script used during pilot study to create network distribution graphs,
#identify active passive states, PCA, and calculate SS
#
#The script takes as input the csv files created after the preprocessing step

library(plyr)
library(dplyr)
library(purrr)
library(ggplot2)
library(ggthemes)
library(broom)
library(stats)
library(RColorBrewer)
library(scatterplot3d)
library(DMwR)

setwd("C:\\Users\\Youngjun Park\\Desktop\\IoTMU\\Captures2")

#flag to enable plots (1 to enable)
plots = 0

devices.df <- NULL
devices.stats <- NULL
devicelist = c("Camera1", "CameraTest", "Camera3", "LightBulb1", "LightBulbTest", "LightBulb2", "Switch1", "SwitchTest", "Switch3")
for (device in devicelist){
  devicename <- read.csv(paste(device, ".csv", sep = ""))
  devicename$Name <- device
  devicename$Time <- devicename$Time - min(devicename$Time)
  if (plots == 1){
    #create scatter plot of lengths of packets sent vs time
    p <- ggplot(devicename, aes(x = Time, y = Length)) + geom_point(colour = "steelblue")
    p <- p + theme_bw() + theme(panel.grid.minor = element_blank())
    p <- p + ggtitle(paste("Lengths of Packets Sent Over Time", device, sep=" - "))
    plot(p)
    ggsave(file=paste(device, "_time_length.png", sep = trial), height = 4, width = 6)
    
    #create histogram of number of packets sent vs time
    p <- ggplot(devicename, aes(Time)) + geom_histogram(binwidth = 0.5, fill = 'steelblue')
    p <- p + theme_bw() + theme(panel.grid.minor = element_blank())
    p <- p + ggtitle(paste("Number of Packets Sent Over Time", device, sep=" - "))
    plot(p)
    ggsave(file=paste(device, "_time_hist.png", sep = trial), height = 4, width = 6)
  }
  
  #determine breaks for histogram
  break.time <- seq(0, round_any(max(devicename$Time), 0.5, ceiling), 0.5) ###
  break.length <- seq(0, 1600, 200)
  
  # determine active and passive states
  devicename.hist = hist(devicename$Time, breaks = break.time, plot = FALSE)
  #The outliers in the number of packets sent will represent the active state
  #For a given continuous variable, outliers are those observations that lie outside 1.5*IQR, 
  #   where IQR, the 'Inter Quartile Range' is the difference between 75th and 25th quartiles.
  #extract outliers
  devicename.times <- devicename.hist$breaks[-1][(devicename.hist$counts >= min(boxplot.stats(devicename.hist$counts)$out))]#remove [-1]
  if (length(devicename.times) == 0){ devicename.times <- devicename.hist$breaks[-1] }
  
  #########################
  # activation window graph
  #########################
  if (plots == 1){
    state <- rep('#4682b4', length(break.time)-1)
    state[break.time[-1] %in% devicename.times] <- '#ff3232'
    
    p <- ggplot(devicename, aes(Time)) + stat_bin(boundary = 0.5, binwidth = 0.5, fill = state) ###
    p <- p + theme_bw() + theme(panel.grid.minor = element_blank())
    p <- p + ggtitle("Number of Packets Sent Over Time")
    plot(p)
    ggsave(file=paste(device, "_active_passive.png", sep = trial), height = 4, width = 6) 
  }
  ##################################
  # Divide active and passive states
  ##################################
  # remove edge cases
  devicename <- devicename[-1, ]
  devicename <- devicename[!devicename$IAT > max(devicename$Time),]
  
  devicename$State <- "Passive"
  devicename[round_any(devicename$Time, 0.5, ceiling) %in% devicename.times,]$State <- "Active" ### floor
  
  #remove edge case
  devicename.active <- devicename[devicename$State == "Active",]
  devicename.passive <- devicename[devicename$State == "Passive",]
  ########################
  # create distribution plots
  # 1: density of packets of size x for each state
  # 2: mean incoming IAT
  # 3: mean outgoing IAT
  devicename.dist <- data.frame(c(hist(devicename.active[devicename.active$Direction == "OUTGOING",]$Length, breaks = break.length, plot = FALSE)$counts/(nrow(devicename.active[devicename.active$Direction == "OUTGOING",])),
                                  hist(devicename.active[devicename.active$Direction == "INCOMING",]$Length, breaks = break.length, plot = FALSE)$counts/(nrow(devicename.active[devicename.active$Direction == "INCOMING",])),
                                  mean(devicename.active$IAT[devicename.active$Direction == "OUTGOING"]),
                                  mean(devicename.active$IAT[devicename.active$Direction == "INCOMING"]),
                                  hist(devicename.passive[devicename.passive$Direction == "OUTGOING",]$Length, breaks = break.length, plot = FALSE)$counts/(nrow(devicename.passive[devicename.passive$Direction == "OUTGOING",])),
                                  hist(devicename.passive[devicename.passive$Direction == "INCOMING",]$Length, breaks = break.length, plot = FALSE)$counts/(nrow(devicename.passive[devicename.passive$Direction == "INCOMING",])),
                                  mean(devicename.passive$IAT[devicename.passive$Direction == "OUTGOING"]),
                                  mean(devicename.passive$IAT[devicename.passive$Direction == "INCOMING"])
                                  ))

  rownames(devicename.dist) <- c(map(hist(devicename.active$Length, breaks = break.length, plot = FALSE)$breaks[-1], paste, "ActiveOut", sep = ""),
                                 map(hist(devicename.active$Length, breaks = break.length, plot = FALSE)$breaks[-1], paste, "ActiveIn", sep = ""),
                                 "ActiveOutIAT",
                                 "ActiveInIAT",
                                 map(hist(devicename.passive$Length, breaks = break.length, plot = FALSE)$breaks[-1], paste, "PassiveOut", sep = ""),
                                 map(hist(devicename.passive$Length, breaks = break.length, plot = FALSE)$breaks[-1], paste, "PassiveIn", sep = ""),
                                 "PassiveOutIAT",
                                 "PassiveInIAT"
                                 ) %>% unlist
  
  colnames(devicename.dist) <- device
  devicename.dist[apply(devicename.dist, 1, is.nan),] <- 0
  if (is.null(devices.df)){
    devices.df <- devicename.dist
    devices.stats <- cbind(devicename$Time, devicename$Length, device)
    devices.hist <- cbind(devicename.hist$counts, device)
  }
  else{
    devices.df <- cbind(devices.df, devicename.dist)
    devices.stats <- rbind(devices.stats, cbind(devicename$Time, devicename$Length, device))
    devices.hist <- rbind(devices.hist, cbind(devicename.hist$counts, device))
  }
}

table.out <- signif(devices.df, 4)
write.csv(table.out, paste("tableout", ".csv", sep = trial), quote = FALSE)

#remove features with only 0 for PCA
devices.filtered.df <- devices.df[apply(devices.df, 1, sum) != 0,]
write.csv(t(devices.df), "device_distributions.csv", quote = FALSE)

#perform PCA
pca <- prcomp(t(devices.filtered.df), scale = TRUE) 

## make a scree plot
pca.var <- pca$sdev^2
pca.var.per <- round(pca.var/sum(pca.var)*100, 1)

pca.var.per.df <- as.data.frame(pca.var.per)
if (plots == 0)
{
  p <- ggplot(pca.var.per.df, aes(x=as.integer(rownames(pca.var.per.df)),y=pca.var.per)) +
  geom_bar(stat="identity", fill = "steelblue")+
  geom_text(aes(label=pca.var.per),position="stack",vjust=-0.5)+
  ggtitle("Percent Variation from Each Principal Component")+
  theme_bw() + theme(panel.grid.minor = element_blank())+
  labs(y="Percent Variation (%)", x = "Principal Component")+
  scale_x_continuous(breaks=seq(1,9,1))
  plot(p)
  ggsave(file=paste("pca_scree", ".png", sep = ""), height = 5, width = 7) 
}

pca.data <- data.frame(Sample=rownames(pca$x),
                       Type=devicelist,
                       X=pca$x[,1],
                       Y=pca$x[,2],
                       Z=pca$x[,3])

#################
#GRAPH 1ST 3 PC #
#################
if (plots == 0){
  shapes = c(17, 17, 16, 17, 17, 16, 17, 17, 16)
  colors <- c("#E69F00", "#E69F00", "#E69F00", "#56B4E9", "#56B4E9", "#56B4E9", "#999999", "#999999", "#999999")
  graphics.off()
  png(filename = paste("PCA", ".png", sep = ""), width = 8, height = 5.9, units = "in", res = 300)
  
  p <- scatterplot3d(pca.data[3:5],
                     pch = shapes,
                     type = "h",
                     color = colors,
                     main="First Three Principal Components",
                     xlab = paste("PC1 - ", pca.var.per[1], "%", sep=""),
                     ylab = paste("PC2 - ", pca.var.per[2], "%", sep=""),
                     zlab = paste("PC3 - ", pca.var.per[3], "%", sep=""),
                     box = FALSE)
  legend("bottom", legend = c("Camera", "Light Bulb", "Switch", "Same Model", "Different Model"),
         col =  c("#E69F00", "#56B4E9", "#999999", "#000000", "#000000"), pch = c(16, 16, 16, 17 ,16),
         inset = -0.25, xpd = TRUE, horiz = TRUE)
  dev.off()
}

#find the number of principal components needed to meet minimum % variation
#pca.per <- list with % variation for each principal component
#value <- minimum threshold to meet (e.g., 0.8 for 80%)
find.threshold <- function(pca.per, value){
  i <- 1
  while(i <= length(pca.per)){
    score <- sum(pca.per[1:i])
    if (score > value){break}
    i <- i + 1
  }
  return(i)
}
threshold <- find.threshold(pca.var.per, 80)
devices.dist <- dist(pca$x[,1:threshold])

#measure the distance between points -> determine SS
#calculate SS
dist.out <- 1 - devices.dist/max(devices.dist)
dist.out <- signif(dist.out, 4)
write.csv(as.matrix(dist.out), paste("simscore", ".csv", sep = trial), quote = FALSE)

#write PCA result
pca.out <- signif(pca$x, 4)
write.csv(pca.out, paste("pcascore", ".csv", sep = trial), quote = FALSE)
