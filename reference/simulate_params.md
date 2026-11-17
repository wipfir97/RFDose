# Draw parameter sets

Draws parameter sets for the stochastic dose calculation: each drawn
parameter from its distribution, around its value in the parameter list.

## Usage

``` r
simulate_params(
  n,
  params = load_params(),
  distributions = load_distributions(),
  sar_sd = 0.25
)
```

## Arguments

- n:

  Number of parameter sets

- params:

  Parameter list, as returned by
  [`load_params()`](https://wipfir97.github.io/RFDose/reference/load_params.md).
  Its values are the means of the distributions.

- distributions:

  Nested list of distributions, as returned by
  [`load_distributions()`](https://wipfir97.github.io/RFDose/reference/load_distributions.md)

- sar_sd:

  Standard deviation of the SAR values, relative to their value. With 0,
  the SAR values are not drawn.

## Value

Matrix with one row per parameter set and one column per drawn parameter
and SAR value, named by its path in the parameter list (sections
separated by "."). Parameters that are not drawn keep their value in
`params`.

## Details

The parameters of a Dirichlet group are drawn together, so that they sum
to 1 in every draw.

The SAR values are drawn too, from a lognormal distribution around their
value in the parameter list, with standard deviation `sar_sd` times the
value. SAR values with the same value for the same tissue come from the
same simulation and are drawn together; SAR values of 0 stay 0.

The SAR values are drawn after the other parameters, so the draws of the
other parameters do not depend on `sar_sd`. Use
[`set.seed()`](https://rdrr.io/r/base/Random.html) before for
reproducible draws.

## See also

[`load_distributions()`](https://wipfir97.github.io/RFDose/reference/load_distributions.md)
