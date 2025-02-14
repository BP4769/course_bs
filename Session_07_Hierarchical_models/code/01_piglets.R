# libraries --------------------------------------------------------------------
library(cmdstanr)
library(ggplot2)
library(bayesplot)
library(posterior)
library(tidyverse)
library(HDInterval)
library(cowplot)

# data prep and model compilation ----------------------------------------------
# load data
data <- read.csv("../data/piglets.csv")

# normal model -----------------------------------------------------------------
model_n <- cmdstan_model("../models/normal.stan")

# data prep
stan_data <- list(
  n = nrow(data),
  y = data$piglet_weight
)

# fit
fit_n <- model_n$sample(
  data = stan_data,
  parallel_chains = 4,
  seed = 1
)

# diagnostics
mcmc_trace(fit_n$draws())
fit_n$summary()

# samples
df_n <- as_draws_df(fit_n$draws(c("sigma", "mu")))
df_n <- df_n %>% select(-.draw, -.chain, -.iteration)

# visual posterior check
# use only a subsample
n_dist <- 20
df_sample_n <- sample_n(df_n, n_dist)

# we will plot weights and distributions from 0 to 6
x <- seq(0, 6, length.out = 1000)

# data frame for storing generated data
df_generated_n <- data.frame(
  x = numeric(),
  y = numeric(),
  iteration = numeric()
)
for (i in 1:n_dist) {
  y <- dnorm(x,
    mean = df_sample_n$mu[i],
    sd = df_sample_n$sigma[i]
  )

  # bind
  df_generated_n <- rbind(
    df_generated_n,
    data.frame(x = x, y = y, iteration = i)
  )
}

# plot
ggplot() +
  geom_density(
    data = data, aes(x = piglet_weight),
    fill = "skyblue", alpha = 0.75, color = NA
  ) +
  geom_line(
    data = df_generated_n,
    aes(x = x, y = y, group = iteration), alpha = 0.2, linewidth = 1
  ) +
  theme_minimal() +
  xlab("Weight") +
  ylab("Density")

# subjects normal model --------------------------------------------------------
model_s <- cmdstan_model("../models/subjects_normal.stan")

# data prep
stan_data <- list(
  n = nrow(data),
  m = max(data$mama_pig),
  y = data$piglet_weight,
  s = data$mama_pig
)

# fit
fit_s <- model_s$sample(
  data = stan_data,
  parallel_chains = 4,
  seed = 1
)

# diagnostics
mcmc_trace(fit_s$draws())
fit_s$summary()

# samples
df_s <- as_draws_df(fit_s$draws(c("sigma", "mu")))
df_s <- df_s %>% select(-.draw, -.chain, -.iteration)

# visual posterior check
# use only n_dist distributions
df_sample_s <- sample_n(df_s, n_dist)

# number of mama pigs
n_mamas <- max(data$mama_pig)

# prep for plotting
df_generated_s <- data.frame(
  x = numeric(),
  y = factor(),
  iteration = numeric(),
  mama_pig = numeric()
)

for (i in 1:n_mamas) {
  for (j in 1:n_dist) {
    # mu for piglet i is in column i+1
    # sigma is always in the first column
    y <- dnorm(x,
      mean = df_sample_s[j, i + 1][[1]],
      sd = df_sample_s[j, ]$sigma
    )

    df_generated_s <- rbind(
      df_generated_s,
      data.frame(
        x = x, y = y,
        iteration = j, mama_pig = i
      )
    )
  }
}

# plot
ggplot() +
  geom_density(
    data = data, aes(x = piglet_weight),
    fill = "skyblue", alpha = 0.75, color = NA
  ) +
  geom_line(
    data = df_generated_s,
    aes(x = x, y = y, group = iteration), alpha = 0.1, linewidth = 1
  ) +
  facet_wrap(. ~ mama_pig, ncol = 4) +
  xlim(0, 6) +
  xlab("Weight") +
  ylab("Density")

# hierarchical normal model ----------------------------------------------------
model_h <- cmdstan_model("../models/hierarchical_normal.stan")

# data prep
stan_data <- list(
  n = nrow(data),
  m = max(data$mama_pig),
  y = data$piglet_weight,
  s = data$mama_pig
)

# fit
fit_h <- model_h$sample(
  data = stan_data,
  parallel_chains = 4,
  seed = 1
)

# diagnostics
mcmc_trace(fit_h$draws())
fit_h$summary()

# samples
df_h <- as_draws_df(fit_h$draws(c("sigma", "mu", "mu_mu", "sigma_mu")))
df_h <- df_h %>% select(-.draw, -.chain, -.iteration)

# visual posterior check
# use only n_dist distributions
df_sample_h <- sample_n(df_h, n_dist)

# prep for plotting
df_generated_h <- data.frame(
  x = numeric(),
  y = factor(),
  iteration = numeric(),
  mama_pig = numeric()
)

for (i in 1:n_mamas) {
  for (j in 1:n_dist) {
    # mu for piglet i is in column i+1
    # sigma is always in the first column
    y <- dnorm(x,
      mean = df_sample_h[j, i + 1][[1]],
      sd = df_sample_h[j, ]$sigma
    )

    df_generated_h <- rbind(
      df_generated_h,
      data.frame(
        x = x, y = y,
        iteration = j, mama_pig = i
      )
    )
  }
}

# plot
ggplot() +
  geom_density(
    data = data, aes(x = piglet_weight),
    fill = "skyblue", alpha = 0.75, color = NA
  ) +
  geom_line(
    data = df_generated_h,
    aes(x = x, y = y, group = iteration), alpha = 0.1, linewidth = 1
  ) +
  facet_wrap(. ~ mama_pig, ncol = 4) +
  xlim(0, 6) +
  xlab("Weight") +
  ylab("Density")

# compare group level means ----------------------------------------------------
df_group <- data.frame(
  Mean = numeric(),
  HDI5 = numeric(),
  HDI95 = numeric(),
  Model = character()
)

# sample
sample_mean <- mean(data$piglet_weight)
df_group <- rbind(df_group, data.frame(
  Mean = sample_mean,
  HDI5 = sample_mean,
  HDI95 = sample_mean,
  Model = "Sample"
))

# simple normal model
normal_mean <- mean(df_n$mu)
normal_90_hdi <- hdi(df_n$mu, credMass = 0.9)
df_group <- rbind(df_group, data.frame(
  Mean = normal_mean,
  HDI5 = normal_90_hdi[1],
  HDI95 = normal_90_hdi[2],
  Model = "Normal"
))

# hierarchical model
hierarchical_mean <- mean(df_h$mu_mu)
hierarchical_90_hdi <- hdi(df_h$mu_mu, credMass = 0.9)
df_group <- rbind(df_group, data.frame(
  Mean = hierarchical_mean,
  HDI5 = hierarchical_90_hdi[1],
  HDI95 = hierarchical_90_hdi[2],
  Model = "Hierarchical"
))

# plot
# set model factors so the colors are the same
df_group$Model <- factor(df_group$Model,
  levels = c("Normal", "Hierarchical", "Sample")
)

ggplot(
  data = df_group,
  aes(
    x = Model,
    y = Mean,
    ymin = HDI5,
    ymax = HDI95,
    colour = Model
  )
) +
  geom_point() +
  geom_errorbar(width = 0.2) +
  scale_color_brewer(palette = "Set1") +
  ylim(0, 6) +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())

# compare subject level means --------------------------------------------------
df_subject <- data.frame(
  Mean = numeric(),
  Q5 = numeric(),
  Q95 = numeric(),
  Model = character(),
  mama_pig = numeric()
)

# sample means
df_mu_sample <- data %>%
  group_by(mama_pig) %>%
  summarise(mean_weight = mean(piglet_weight))
df_subject <- rbind(df_subject, data.frame(
  Mean = df_mu_sample$mean_weight,
  HDI5 = df_mu_sample$mean_weight,
  HDI95 = df_mu_sample$mean_weight,
  Model = "Sample",
  mama_pig = seq(1:n_mamas)
))

# subject means
df_mu_s <- df_s %>% select(2:(1 + n_mamas))
s_means <- colMeans(df_mu_s)
s_90_hdi <- apply(df_mu_s, 2, hdi, credMass = 0.9)
df_subject <- rbind(df_subject, data.frame(
  Mean = s_means,
  HDI5 = s_90_hdi[1, ],
  HDI95 = s_90_hdi[2, ],
  Model = "Subject",
  mama_pig = seq(1:n_mamas)
))

# hierarchical means
df_mu_h <- df_h %>% select(2:(1 + n_mamas))
h_means <- colMeans(df_mu_h)
h_hdi90 <- apply(df_mu_h, 2, hdi, credMass = 0.9)
df_subject <- rbind(df_subject, data.frame(
  Mean = h_means,
  HDI5 = h_hdi90[1, ],
  HDI95 = h_hdi90[2, ],
  Model = "Hierarchical",
  mama_pig = seq(1:n_mamas)
))

# plot
# set model factors so the colors are the same
df_subject$Model <- factor(df_subject$Model,
  levels = c("Subject", "Hierarchical", "Sample")
)

# plot
ggplot(
  data = df_subject,
  aes(
    x = Model,
    y = Mean,
    ymin = HDI5,
    ymax = HDI95,
    colour = Model
  )
) +
  geom_hline(yintercept = mean(data$piglet_weight), color = "grey75") +
  geom_point() +
  geom_errorbar(width = 0.2) +
  scale_color_brewer(palette = "Set1") +
  ylim(0, 6) +
  facet_wrap(. ~ mama_pig, ncol = 4) +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())
