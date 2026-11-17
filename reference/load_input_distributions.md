# Load input distributions

Loads the distributions of the input variables that are drawn in the
stochastic dose calculation.

## Usage

``` r
load_input_distributions(path = NULL)
```

## Arguments

- path:

  Path of an input distribution file (must be a YAML file). If null, the
  default input distributions are loaded.

## Value

Named list of input distributions.

## Details

Each input is drawn around its value: the value given in the input data,
or else its default value. Its distribution only gives the shape:

- `trunc_lognormal`: `sd_rel` (standard deviation relative to the
  value), `min`, `max` (lognormal truncated to `min`-`max`)

- `lognormal`: `sd_rel`

- `beta`: `alpha` (a0 = alpha/value)

- `dirichlet`: `a0` and `group`. The inputs of a group are shares of a
  whole and are drawn together with its rest (e.g. the speaker mode of
  calls).

- `categorical`: `probs`, the probability of each value, for each given
  value

Inputs without a distribution are not drawn. The default input
distributions (`input_distributions.yaml`) are generated from the same
Excel file as the default values.

## See also

[`simulate_inputs()`](https://wipfir97.github.io/RFDose/reference/simulate_inputs.md)
