# Summarise the doses of all draws

Summarise the doses of all draws

## Usage

``` r
summarise_doses(deterministic, doses, probs)
```

## Arguments

- deterministic:

  Matrix of doses with the parameter values of the parameter file:
  sample x exposure source

- doses:

  Array of doses with drawn parameter sets: sample x draw x exposure
  source, as returned by
  [`stochastic_doses()`](https://wipfir97.github.io/RFDose/reference/stochastic_doses.md)

- probs:

  Probabilities of the quantiles

## Value

Data frame with one row per sample and dose (each exposure source and
their sum, `total_dose`).
