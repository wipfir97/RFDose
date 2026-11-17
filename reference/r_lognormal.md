# Draw from a lognormal distribution

Draw from a lognormal distribution

## Usage

``` r
r_lognormal(n, mean, sd)
```

## Arguments

- n:

  Number of draws

- mean:

  Mean (arithmetic, not on the log scale)

- sd:

  Standard deviation (arithmetic, not on the log scale)

## Value

Vector of `n` draws. All draws are equal to `mean` if `mean` or `sd` is
0.
