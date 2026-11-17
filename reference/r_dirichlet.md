# Draw from a Dirichlet distribution

Draw from a Dirichlet distribution

## Usage

``` r
r_dirichlet(n, mean, a0)
```

## Arguments

- n:

  Number of draws

- mean:

  Vector of means (proportions that sum to 1)

- a0:

  Concentration: the larger, the closer the draws are to `mean`

## Value

Matrix with one row per draw and one column per proportion; each row
sums to 1. Proportions with mean 0 stay 0. All rows are equal to `mean`
if `a0` is infinite.
