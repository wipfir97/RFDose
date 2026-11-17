# Calculate doses for drawn parameter sets

Calculates the doses of each sample with each parameter set and its
drawn inputs.

## Usage

``` r
stochastic_doses(
  samples,
  tissue,
  params,
  draws,
  inputs = NULL,
  known_warnings = character(0)
)
```

## Arguments

- samples:

  List of samples (input values of a single observation each), as for
  [`total_dose()`](https://wipfir97.github.io/RFDose/reference/total_dose.md)

- tissue:

  Tissue for which to calculate dose (default: "brain" or "body")

- params:

  Parameter list, as returned by
  [`load_params()`](https://wipfir97.github.io/RFDose/reference/load_params.md)

- draws:

  Drawn parameter sets, as returned by
  [`simulate_params()`](https://wipfir97.github.io/RFDose/reference/simulate_params.md)

- inputs:

  Drawn inputs, as returned by
  [`simulate_inputs()`](https://wipfir97.github.io/RFDose/reference/simulate_inputs.md)
  (optional). If NULL, the inputs of the samples are used in every draw.

- known_warnings:

  Warning messages that were already raised. Other warnings are raised
  once, with the number of times they occurred.

## Value

Array of doses in mJ/kg/day: sample x draw x exposure source.
