# Prepare input data for the dose calculation

Replaces missing values in the input data with default values.

## Usage

``` r
prepare_dose_data(data, default_value_file = NULL)
```

## Arguments

- data:

  A data frame. Must have the exact same columns as the provided example
  dataset.

- default_value_file:

  Path to a .yaml file with default values to replace missing values
  (optional). If not specified, the internal default values are used.

## Value

The data frame with missing values replaced. Side effect of raising a
warning if a column has more than 10% missing values.
