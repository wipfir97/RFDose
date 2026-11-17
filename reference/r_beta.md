# Draw from a beta distribution

Draw from a beta distribution

## Usage

``` r
r_beta(n, mean, alpha)
```

## Arguments

- n:

  Number of draws

- mean:

  Mean (between 0 and 1)

- alpha:

  First shape parameter: the concentration is a0 = alpha/mean

## Value

Vector of `n` draws between 0 and 1. All draws are equal to `mean` if
`mean` is 0 or 1, or `alpha` is infinite.
