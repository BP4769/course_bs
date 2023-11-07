data {
  int<lower=1> n;                           // Number of data points
  array[n] int <lower=1, upper=3> fertiliser;   // Fertiliser type
  vector[n] yield;                          // Yield data
}

parameters {
  vector[3] mu;             // Mean yield for each fertiliser
  vector<lower=0>[3] sigma; // Standard deviation for each fertiliser
}

model {
  // Priors
  mu ~ normal(170, 50);
  sigma ~ cauchy(0, 5);


  // Likelihood
  yield ~ normal(mu[fertiliser], sigma[fertiliser]);
}
