# Mean of a truncated lognormal distribution

Mean of a truncated lognormal distribution

## Usage

``` r
trunc_lognormal_mean(meanlog, sdlog, min, max)
```

## Arguments

- meanlog:

  Mean on the log scale, before truncation

- sdlog:

  Standard deviation on the log scale, before truncation

- min:

  Lower bound

- max:

  Upper bound

## Value

Mean of the lognormal distribution truncated to `min`-`max`.
