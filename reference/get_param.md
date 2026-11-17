# Get a parameter value

Get a parameter value

## Usage

``` r
get_param(params, key)
```

## Arguments

- params:

  Parameter list, as returned by
  [`load_params()`](https://wipfir97.github.io/RFDose/reference/load_params.md)

- key:

  Path of the parameter in the parameter list (character vector)

## Value

Value of the parameter. Side effect of stopping calculation if the
parameter is not a single number.
