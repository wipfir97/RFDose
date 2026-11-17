# Quantiles of a beta distribution

Quantile function of the beta distribution of
[`r_beta()`](https://wipfir97.github.io/RFDose/reference/r_beta.md).

## Usage

``` r
q_beta(p, mean, alpha)
```

## Arguments

- p:

  Vector of probabilities

- mean:

  Mean (between 0 and 1)

- alpha:

  First shape parameter: the concentration is a0 = alpha/mean

## Value

Vector of quantiles between 0 and 1, increasing with `p`. All quantiles
are equal to `mean` if `mean` is 0 or 1, or `alpha` is infinite.
