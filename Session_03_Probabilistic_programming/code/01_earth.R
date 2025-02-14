# library
library(tidyverse)
library(ggplot2)

# x axis
x <- seq(0, 1, 0.1)

# water
water <- x * 2

# land
land <- 2 - water

# prior
prior <- rep(1, 11) / 11

# plot our initial belief
df <- data.frame(x, prior)
ggplot(df, aes(x, prior)) +
    geom_bar(stat = "identity") +
    xlab("Water percentage") +
    ylab("Belief") +
    ylim(0, 1)

# set posterior
our_belief <- NULL

saw_land <- function(our_belief) {
    # calculate the posterior
    if (is.null(our_belief)) {
        posterior <- prior * land
    } else {
        posterior <- our_belief * land
    }
    posterior <- posterior / sum(posterior)

    # plot
    df <- data.frame(x, posterior)
    p <- ggplot(df, aes(x, posterior)) +
        geom_bar(stat = "identity") +
        xlab("Water percentage") +
        ylab("Belief") +
        ylim(0, 1)
    print(p)

    return(posterior)
}

saw_water <- function(our_belief) {
    # calculate the posterior
    if (is.null(our_belief)) {
        posterior <- prior * water
    } else {
        posterior <- our_belief * water
    }
    posterior <- posterior / sum(posterior)

    # plot
    df <- data.frame(x, posterior)
    p <- ggplot(df, aes(x, posterior)) +
        geom_bar(stat = "identity") +
        xlab("Water percentage") +
        ylab("Belief") +
        ylim(0, 1)
    print(p)

    return(posterior)
}

# sample location from https://www.realrandom.net/location.html

# saw land
our_belief <- saw_land(our_belief)

# saw water
our_belief <- saw_water(our_belief)
