# Quantiles of a truncated lognormal distribution

Quantile function of the truncated lognormal distribution of
[`r_trunc_lognormal()`](https://wipfir97.github.io/RFDose/reference/r_trunc_lognormal.md),
which keeps the given mean.

## Usage

``` r
q_trunc_lognormal(p, mean, sd, min, max)
```

## Arguments

- p:

  Vector of probabilities

- mean:

  Mean of the truncated distribution (between `min` and `max`)

- sd:

  Standard deviation, before truncation

- min:

  Lower bound (0 or more)

- max:

  Upper bound

## Value

Vector of quantiles between `min` and `max`, increasing with `p`. All
quantiles are equal to `mean` if `sd` is 0.

## Details

The probabilities are computed as logarithms, so that the quantiles are
also right very close to a bound (e.g. a mean just below `max`), where
the probabilities can be too small to be stored as numbers.
