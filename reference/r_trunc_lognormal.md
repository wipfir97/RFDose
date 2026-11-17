# Draw from a truncated lognormal distribution

Draws from a lognormal distribution truncated to the interval
`min`-`max`, which keeps the given mean.

## Usage

``` r
r_trunc_lognormal(n, mean, sd, min, max)
```

## Arguments

- n:

  Number of draws

- mean:

  Mean of the truncated distribution (between `min` and `max`)

- sd:

  Standard deviation, before truncation

- min:

  Lower bound (0 or more)

- max:

  Upper bound

## Value

Vector of `n` draws between `min` and `max`. All draws are equal to
`mean` if `sd` is 0.

## Details

Truncation alone would move the mean, e.g. down if the mean is close to
`max`. The lognormal distribution before truncation is therefore shifted
(on the log scale), until the mean of the truncated distribution is
`mean`. The spread on the log scale is the one of a lognormal
distribution with `mean` and `sd`; truncation makes the standard
deviation of the draws smaller than `sd`.
