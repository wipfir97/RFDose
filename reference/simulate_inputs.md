# Draw input values

Draws the input values of each row for the stochastic dose calculation,
each around its value in the input data.

## Usage

``` r
simulate_inputs(n, data, input_distributions = load_input_distributions())
```

## Arguments

- n:

  Number of draws

- data:

  Data frame of inputs without missing values (see
  [`calculate_emf_doses()`](https://wipfir97.github.io/RFDose/reference/calculate_emf_doses.md))

- input_distributions:

  Named list of input distributions, as returned by
  [`load_input_distributions()`](https://wipfir97.github.io/RFDose/reference/load_input_distributions.md)

## Value

Named list with one element per drawn input: a matrix with one row per
row of `data` and one column per draw.

## Details

All rows are drawn with the same random numbers, each transformed by the
distribution around its own value, so the draws of a row do not depend
on the other rows. Durations of 0 stay 0, and so do values at the bounds
of a truncated distribution. The inputs of a Dirichlet group are drawn
together with the rest of their whole, so they sum to 1 at most. Use
[`set.seed()`](https://rdrr.io/r/base/Random.html) before for
reproducible draws.

## See also

[`load_input_distributions()`](https://wipfir97.github.io/RFDose/reference/load_input_distributions.md)
