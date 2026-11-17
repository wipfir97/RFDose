# Load parameter distributions

Loads the distributions of the parameters that are drawn in the
stochastic dose calculation and returns them as a nested list, with the
structure of the parameter list.

## Usage

``` r
load_distributions(path = NULL)
```

## Arguments

- path:

  Path of a distribution file (must be a YAML file). If null, the
  default distributions are loaded.

## Value

Nested list of distributions.

## Details

Each drawn parameter has a distribution and the values that set its
shape:

- `lognormal`: `sd_rel` (standard deviation relative to the mean)

- `trunc_lognormal`: `sd_rel`, `min`, `max` (lognormal truncated to
  `min`-`max`)

- `beta`: `alpha` (a0 = alpha/mean)

- `dirichlet`: `a0` and `group`. The parameters of a group are drawn
  together and sum to 1.

The mean of each distribution is the value of the parameter in the
parameter list (see
[`load_params()`](https://wipfir97.github.io/RFDose/reference/load_params.md)).
Parameters without a distribution are not drawn. The default
distributions (`params_distributions.yaml`) are generated from the same
Excel file as the default parameters.

## See also

[`simulate_params()`](https://wipfir97.github.io/RFDose/reference/simulate_params.md)
