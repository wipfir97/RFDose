# Set parameter values

Replaces the values of some parameters, e.g. by one draw of
[`simulate_params()`](https://wipfir97.github.io/RFDose/reference/simulate_params.md).

## Usage

``` r
set_params(params, values, keys = strsplit(names(values), ".", fixed = TRUE))
```

## Arguments

- params:

  Parameter list, as returned by
  [`load_params()`](https://wipfir97.github.io/RFDose/reference/load_params.md)

- values:

  Numeric vector of new values

- keys:

  List with the path of each parameter of `values` (character vectors).
  By default, the names of `values`, with sections separated by ".".

## Value

Parameter list with the new values.
