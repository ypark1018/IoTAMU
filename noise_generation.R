#Generate AGPS from network distribution of devices
#source: https://stats.stackexchange.com/questions/164471/generating-a-simulated-dataset-from-a-correlation-matrix-with-means-and-standard

library(MASS)

#read network signature distribution file
setwd("C:/Users/Youngjun Park/Desktop/IoTMU/Captures3")
distribution <- read.csv("device_distributions3.csv", row.names = 1)
#replace 0 with NA so they are not used in analyses
distribution[c(17,18,35,36)][distribution[c(17,18,35,36)] == 0] <- NA
distribution[c(17,18,35,36)] <- log(distribution[c(17,18,35,36)]) #log scale IAT
distribution.means <- apply(distribution, 2, mean, na.rm = TRUE)
#create covariance matrix from the distribution
distribution.cov <- cov(distribution, use="complete.obs")
#sample 120 times from multivariate normal distribution
noise <- mvrnorm(n = 120, mu = distribution.means, Sigma = distribution.cov) %>% data.frame

#undo log scale
noise[c(17,18,35,36)] <- exp(noise[c(17,18,35,36)])


#apply for every column
#if there is a negative number, add 2x the magnitude of minimum value to the column
rescale.col <- function(dist){
  dist[abs(dist) < 0.0001] <- 0
  if (TRUE %in% (dist < 0)){
    dist <- dist + 2*abs((min(dist)))
  }
  return(dist)
}

#recalculate percentage for each feature:
#new percentage = value/row_total
rescale.row <- function(dist){
  total <- sum(dist[1:8])
  dist[1:8] <- (dist[1:8])/total
  total <- sum(dist[9:16])
  dist[9:16] <- (dist[9:16])/total
  total <- sum(dist[19:26])
  dist[19:26] <- (dist[19:26])/total
  total <- sum(dist[27:34])
  dist[27:34] <- (dist[27:34])/total
  return(dist)
}

#apply the functions to the noise data
new.noise <- data.frame(apply(noise, 2, rescale.col))
new.noise <- data.frame(t(apply(new.noise, 1, rescale.row)))
outfile <- cbind(rep(rownames(distribution), 46), new.noise)
#write file
write.csv(outfile, "target_distributions_120.csv", quote = FALSE, row.names = FALSE)