# libraries --------------------------------------------------------------------
library(cmdstanr) # for interfacing Stan
library(ggplot2) # for visualizations
library(ggdist) # for distribution visualizations
library(tidyverse) # for data prep
library(posterior) # for extracting samples
library(bayesplot) # for some quick MCMC visualizations
library(mcmcse) # for comparing samples and calculating MCSE

# Read the dataset
data <- read.csv("HW1/data/crop.csv")
n <- nrow(data)

# normalize & standardize data


# Prepare data for Stan
stan_data <- list(n = n, fertiliser = data$fertilizer, yield = data$yield)

# Compile the Stan model
model <- cmdstan_model("HW1/models/crop_normal.stan")

# fit
fit <- model$sample(
  data = stan_data,
  seed = 1
)

# diagnostics ------------------------------------------------------------------
# traceplot
mcmc_trace(fit$draws())

# summary
fit$summary()

# analysis ---------------------------------------------------------------------
# convert samples to data frame
df <- as_draws_df(fit$draws())

# rename columns to mu1, mu2, mu3, sigma1, sigma2, sigma3
colnames(df) <- c("mu1", "mu2", "mu3", "sigma1", "sigma2", "sigma3")

# How do fertilisers fare against each other on average? In other words,
# what is the probability that fertiliser #1 gives better average yield than 
# fertiliser #2 (and similarly for fertiliser #1 vs fertiliser #3 and 
# fertiliser #2 vs fertiliser #3)?

# comparison
mcse(df$mu1 > df$mu2)
mcse(df$mu1 > df$mu3)
mcse(df$mu2 > df$mu3)



