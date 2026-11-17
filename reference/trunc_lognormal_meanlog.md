# Log-scale mean of a lognormal distribution, from the mean after truncation

Log-scale mean of a lognormal distribution, from the mean after
truncation

## Usage

``` r
trunc_lognormal_meanlog(mean, sdlog, min, max)
```

## Arguments

- mean:

  Mean of the truncated distribution

- sdlog:

  Standard deviation on the log scale, before truncation

- min:

  Lower bound

- max:

  Upper bound

## Value

Mean on the log scale, before truncation, for which the lognormal
distribution truncated to `min`-`max` has the mean `mean`.
