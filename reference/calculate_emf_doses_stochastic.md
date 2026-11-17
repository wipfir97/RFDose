# Calculate RF-EMF doses with their uncertainty for ALL samples

Stochastic version of
[`calculate_emf_doses()`](https://wipfir97.github.io/RFDose/reference/calculate_emf_doses.md):
calculates the doses of each row many times, each time with other
parameter values and input values drawn from their distributions, and
summarises the doses of all draws.

## Usage

``` r
calculate_emf_doses_stochastic(
  data,
  tissue,
  n = 1000,
  params = NULL,
  distributions = NULL,
  input_distributions = NULL,
  default_value_file = NULL,
  sar_file = NULL,
  sar_sd = 0.25,
  draw_inputs = TRUE,
  probs = c(0.025, 0.5, 0.975),
  keep_draws = FALSE,
  seed = NULL
)
```

## Arguments

- data:

  A data frame. Must have the exact same columns as the provided example
  dataset. Columns must not be missing. Missing values will be replaced
  with default values.

- tissue:

  Tissue for which to calculate dose (default: "brain" or "body")

- n:

  Number of parameter sets (draws)

- params:

  (experimental) Path to a parameter file in .yaml format, as for
  [`calculate_emf_doses()`](https://wipfir97.github.io/RFDose/reference/calculate_emf_doses.md).
  Its values are the means of the distributions.

- distributions:

  (experimental) Path to a distribution file in .yaml format, with the
  structure of the internal distribution file
  (`params_distributions.yaml`). Optional; if not specified, the default
  distributions are used.

- input_distributions:

  (experimental) Path to an input distribution file in .yaml format,
  with the structure of the internal input distribution file
  (`input_distributions.yaml`). Optional; if not specified, the default
  input distributions are used.

- default_value_file:

  List of default values to replace missing values (optional).

- sar_file:

  SAR values (optional): the name of a SAR file included in the package
  (e.g. `"goliat_average"`, the default; see
  [`available_sar_files()`](https://wipfir97.github.io/RFDose/reference/available_sar_files.md))
  or the path to your own .yaml file, as for
  [`calculate_emf_doses()`](https://wipfir97.github.io/RFDose/reference/calculate_emf_doses.md).

- sar_sd:

  Standard deviation of the SAR values, relative to their value
  (default: 25%). With 0, the SAR values are not drawn.

- draw_inputs:

  If FALSE, the inputs are not drawn.

- probs:

  Probabilities of the quantiles of the doses (default: median and 95%
  interval)

- keep_draws:

  If TRUE, also return the doses and parameters of every draw.

- seed:

  Random seed for reproducible draws (optional), as for
  [`set.seed()`](https://rdrr.io/r/base/Random.html). The random state
  of the session is restored afterwards. If NULL, the draws continue
  from the current random state.

## Value

A data frame with one row per row of `data` and dose, in mJ/kg/day:

- `sample_id`: ID of the row, if `data` has a column `sample_id`

- `row`: row of `data`

- `dose`: exposure source (as the columns of
  [`calculate_emf_doses()`](https://wipfir97.github.io/RFDose/reference/calculate_emf_doses.md)),
  or `total_dose` for their sum

- `deterministic`: dose with the parameter values of the parameter file,
  as calculated by
  [`calculate_emf_doses()`](https://wipfir97.github.io/RFDose/reference/calculate_emf_doses.md)

- `mean`, `sd`: mean and standard deviation of the doses of all draws

- one column per quantile of the doses of all draws (e.g. `q2.5`, `q50`,
  `q97.5`)

With `keep_draws = TRUE`, a list with this data frame (`summary`), the
doses of every draw (`doses`, an array row x draw x exposure source),
the drawn parameters and SAR values (`params`, a matrix draw x
parameter) and the drawn inputs (`inputs`, a list of matrices row x
draw, one per input).

## Details

The parameter sets are drawn with
[`simulate_params()`](https://wipfir97.github.io/RFDose/reference/simulate_params.md):
parameters with a distribution (see
[`load_distributions()`](https://wipfir97.github.io/RFDose/reference/load_distributions.md))
and the SAR values vary around their value in the parameter and SAR
files; all other parameters keep their values. Every row is calculated
with the same parameter sets.

The inputs are drawn with
[`simulate_inputs()`](https://wipfir97.github.io/RFDose/reference/simulate_inputs.md):
inputs with a distribution (see
[`load_input_distributions()`](https://wipfir97.github.io/RFDose/reference/load_input_distributions.md))
vary around their value in `data`, or around their default value if
missing; all other inputs keep their values.

The model takes the travel time from the time at home. If the travel
time of a draw is longer than the drawn time at home, it is capped at
the time at home, with a warning.

The doses of a row do not depend on the other rows. Give a `seed` (or
use [`set.seed()`](https://rdrr.io/r/base/Random.html) before) for
reproducible results: the same seed and arguments give the same draws.

## See also

[`calculate_emf_doses()`](https://wipfir97.github.io/RFDose/reference/calculate_emf_doses.md),
[`simulate_params()`](https://wipfir97.github.io/RFDose/reference/simulate_params.md)
