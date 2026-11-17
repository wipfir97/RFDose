# Quantiles of shares of a whole

Dirichlet distribution of shares and the rest of their whole, from the
quantiles of independent gamma distributions.

## Usage

``` r
q_shares(p, values, a0)
```

## Arguments

- p:

  Matrix of probabilities: one row per draw, one column per share and
  one for the rest

- values:

  Shares (their sum is 1 at most)

- a0:

  Concentration: the larger, the closer the draws are to `values`

## Value

Matrix with one row per draw and one column per share. Shares of 0 stay
0.
