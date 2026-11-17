# List SAR values

Lists the SAR values of a parameter list (the values in the tissue
sections of each device), except those that are 0.

## Usage

``` r
list_sar(params)
```

## Arguments

- params:

  Parameter list, as returned by
  [`load_params()`](https://wipfir97.github.io/RFDose/reference/load_params.md)

## Value

Data frame with one row per SAR value that is not 0: its path in the
parameter list (`name`, sections separated by "."), its tissue and its
value.
