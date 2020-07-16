# Graph the network latency, number of packets, and throughput
# perform ANOVA on network latency times for increasing number of samples spoofed

library(ggplot2)
library(dplyr)
library(broom)
library(gtable)
library(grid) # low-level grid functions are required

setwd("C:\\Users\\Youngjun Park\\Desktop\\IoTMU\\Captures5")

#helper function to retrieve packet length information from preprocessed csv files
get_info <- function(treatment){
  setwd(paste("C:\\Users\\Youngjun Park\\Desktop\\IoTMU\\congestion2\\", treatment, sep=""))
  devices.df <- NULL
  devicelist = c("Camera1", "CameraTest", "Camera2", "Camera3", "Lightbulb1","LightbulbTest", "Lightbulb2", "Switch1", "SwitchTest", "Switch2", "Switch3")
  #combine data from three trials
  for (device in devicelist){
    devicename <- read.csv(paste(device, ".csv", sep = "_1"))
    tempdevice <- read.csv(paste(device, ".csv", sep = "_2"))
    devicename <- rbind(devicename, tempdevice)
    tempdevice <- read.csv(paste(device, ".csv", sep = "_3"))
    devicename <- rbind(devicename, tempdevice)
      
    if (is.null(devices.df)){
      devices.df <- devicename
    }
    else{
      devices.df <- rbind(devices.df, devicename)
    }
  }
  return(devices.df)
}
#calculate throughput in kbps
t_base <- get_info("Base")
t_base <- 8 * sum(t_base$Length)/90/1000
t_10 <- get_info("10")
t_10 <- 8 * sum(t_10$Length)/90/1000
t_20 <- get_info("20")
t_20 <- 8 * sum(t_20$Length)/90/1000
t_30 <- get_info("30")
t_30 <-8 * sum(t_30$Length)/90/1000
t_40 <- get_info("40")
t_40 <-8 * sum(t_40$Length)/90/1000
t_50 <- get_info("50")
t_50 <-8 * sum(t_50$Length)/90/1000
t_60 <- get_info("60")
t_60 <-8 * sum(t_60$Length)/90/1000
t_70 <- get_info("70")
t_70 <-8 * sum(t_70$Length)/90/1000
t_80 <- get_info("80")
t_80 <-8 * sum(t_80$Length)/90/1000
t_90 <- get_info("90")
t_90 <-8 * sum(t_90$Length)/90/1000
t_100 <- get_info("100")
t_100 <-8 * sum(t_100$Length)/90/1000
t_110 <- get_info("110")
t_110 <-8 * sum(t_110$Length)/90/1000
t_120 <- get_info("120")
t_120 <-8 * sum(t_120$Length)/90/1000

#read network latency files and create a dataframe with columns network latency time, treatment, throughput
setwd("C:\\Users\\Youngjun Park\\Desktop\\IoTMU\\congestion2\\latency")
s1 <- cbind(c(read.csv("congestion0_0.txt", header = FALSE)[-1,], read.csv("congestion0_1.txt", header = FALSE)[-1,], read.csv("congestion0_2.txt", header = FALSE)[-1,]), 0, t_base)
s2 <- cbind(c(read.csv("congestion10_0.txt", header = FALSE)[-1,], read.csv("congestion10_1.txt", header = FALSE)[-1,], read.csv("congestion10_2.txt", header = FALSE)[-1,]), 10, t_10)
s3 <- cbind(c(read.csv("congestion20_0.txt", header = FALSE)[-1,], read.csv("congestion20_1.txt", header = FALSE)[-1,], read.csv("congestion20_2.txt", header = FALSE)[-1,]), 20, t_20)
s4 <- cbind(c(read.csv("congestion30_0.txt", header = FALSE)[-1,], read.csv("congestion30_1.txt", header = FALSE)[-1,], read.csv("congestion30_2.txt", header = FALSE)[-1,]), 30, t_30)
s5 <- cbind(c(read.csv("congestion40_0.txt", header = FALSE)[-1,], read.csv("congestion40_1.txt", header = FALSE)[-1,], read.csv("congestion40_2.txt", header = FALSE)[-1,]), 40, t_40)
s6 <- cbind(c(read.csv("congestion50_0.txt", header = FALSE)[-1,], read.csv("congestion50_1.txt", header = FALSE)[-1,], read.csv("congestion50_2.txt", header = FALSE)[-1,]), 50, t_50)
s7 <- cbind(c(read.csv("congestion60_0.txt", header = FALSE)[-1,], read.csv("congestion60_1.txt", header = FALSE)[-1,], read.csv("congestion60_2.txt", header = FALSE)[-1,]), 60, t_60)
s8 <- cbind(c(read.csv("congestion70_0.txt", header = FALSE)[-1,], read.csv("congestion70_1.txt", header = FALSE)[-1,], read.csv("congestion70_2.txt", header = FALSE)[-1,]), 70, t_70)
s9 <- cbind(c(read.csv("congestion80_0.txt", header = FALSE)[-1,], read.csv("congestion80_1.txt", header = FALSE)[-1,], read.csv("congestion80_2.txt", header = FALSE)[-1,]), 80, t_80)
s10 <- cbind(c(read.csv("congestion90_0.txt", header = FALSE)[-1,], read.csv("congestion90_1.txt", header = FALSE)[-1,], read.csv("congestion90_2.txt", header = FALSE)[-1,]), 90, t_90)
s11 <- cbind(c(read.csv("congestion100_0.txt", header = FALSE)[-1,], read.csv("congestion100_1.txt", header = FALSE)[-1,], read.csv("congestion100_2.txt", header = FALSE)[-1,]), 100, t_100)
s12 <- cbind(c(read.csv("congestion110_0.txt", header = FALSE)[-1,], read.csv("congestion110_1.txt", header = FALSE)[-1,], read.csv("congestion110_2.txt", header = FALSE)[-1,]), 110, t_110)
s13 <- cbind(c(read.csv("congestion120_0.txt", header = FALSE)[-1,], read.csv("congestion120_1.txt", header = FALSE)[-1,], read.csv("congestion120_2.txt", header = FALSE)[-1,]), 120, t_120)

#change column names for readability
colnames(s1) <- c("Time", "Treatment", "Throughput")
colnames(s2) <- c("Time", "Treatment", "Throughput")
colnames(s3) <- c("Time", "Treatment", "Throughput")
colnames(s4) <- c("Time", "Treatment", "Throughput")
colnames(s5) <- c("Time", "Treatment", "Throughput")
colnames(s6) <- c("Time", "Treatment", "Throughput")
colnames(s7) <- c("Time", "Treatment", "Throughput")
colnames(s8) <- c("Time", "Treatment", "Throughput")
colnames(s9) <- c("Time", "Treatment", "Throughput")
colnames(s10) <- c("Time", "Treatment", "Throughput")
colnames(s11) <- c("Time", "Treatment", "Throughput")
colnames(s12) <- c("Time", "Treatment", "Throughput")
colnames(s13) <- c("Time", "Treatment", "Throughput")

#combine dataframes into one and perform ANOVA
s.all <- data.frame(rbind(s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13))
s.all$Treatment <- factor(s.all$Treatment)
s.aov <- aov(Time ~ Treatment, s.all)
summary(s.aov)
qqnorm(s.aov$residuals)

#turn data into log scale
s.all$Time <- log(s.all$Time)
s.aov <- aov(Time ~ Treatment, s.all)
summary(s.aov)

#verify Q-Q plot and residuals
qqnorm(s.aov$residuals)
qqline(s.aov$residuals)
s.all$Residuals <- s.aov$residuals
#residual plot
p <- ggplot(s.all, aes(x = Treatment, y = Residuals)) + geom_point(color="steelblue")
p <- p + theme_bw() + theme(panel.grid.minor = element_blank())
plot(p)

#create boxplot of network latency for each treatment
p1 <- ggplot(s.all, aes(x = Treatment, y = Time)) + geom_boxplot(color="steelblue")
p1 <- p1 + theme_bw() + theme(panel.grid.minor = element_blank(), axis.title.x=element_blank())
p1 <- p1 + labs(y = "Network Latency (sec)", x = "")

#create line graph of number of packets observed for each treatment
Packets = c(881, 1457, 1464, 1947, 2038, 2151, 2731, 2848, 2933, 3234, 3961, 3729, 4181)
Treatment = c(0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120)
packets.df <- data.frame(cbind(Packets, Treatment))
p2 <- ggplot(packets.df, aes(x = Treatment, y = Packets)) + geom_line(color="steelblue")
p2 <- p2 + theme_bw() + theme(panel.grid.minor = element_blank(), axis.title.x=element_blank())
p2 <- p2 + scale_x_continuous(breaks=seq(0,120,10))
p2 <- p2 + labs(y = "Number of Packets Observed")

#create line graph of throughput for each treatment
Throughput = c(t_base, t_10, t_20, t_30, t_40, t_50, t_60, t_70, t_80, t_90, t_100, t_110, t_120)
Treatment = c(0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120)
tp.df <- data.frame(cbind(Throughput, Treatment))
p3 <- ggplot(tp.df, aes(x = Treatment, y = Throughput)) + geom_line(color="steelblue")
p3 <- p3 + theme_bw() + theme(panel.grid.minor = element_blank())
p3 <- p3 + scale_x_continuous(breaks=seq(0,120,10))
p3 <- p3 + labs(y = "Throughput (kbps)", x = "Number of Samples Spoofed")

#stack the three plots together
g1 <- ggplotGrob(p1)
g2 <- ggplotGrob(p2)
g3 <- ggplotGrob(p3)
g <- rbind(g1, g2, g3, size="first") # stack the three plots
g$widths <- unit.pmax(g1$widths, g2$widths, g3$widths) # use the largest widths
# center the legend vertically
g$layout[grepl("guide", g$layout$name),c("t","b")] <- c(1,nrow(g))
grid.newpage()
grid.draw(g)