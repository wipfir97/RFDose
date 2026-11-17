# Fill missing values in input data frame with missing values

Replaces missing values in input data frame with values specified as
default values. In case a column is completely missing, it is added to
the data frame, with all values being the default value.

## Usage

``` r
fill_missing_variables(data, defaults, warn_threshold = 0.1)
```

## Arguments

- data:

  Input data frame

- defaults:

  Named list (key = column name, value = default value to replace
  missing values in this column)

- warn_threshold:

  threshold proportion of missing data per column to raise warning

## Value

data frame with missing data replaced with default values. Side effect
of raising warning if proportion of missing data exceeds warn_threshold
for at least one column.
