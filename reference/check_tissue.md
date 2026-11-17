# Check if tissue is valid

Check if tissue with this name can be found in YAML file, and if it has
any nested parameters. Parameters themselves are NOT checked for
validity.

## Usage

``` r
check_tissue(tissue, device, params)
```

## Arguments

- tissue:

  Name of tissue to be checked (character, length 1)

- device:

  Device for which to check tissue (character, length 1)

- params:

  Parameter list, as returned by
  [`load_params()`](https://wipfir97.github.io/RFDose/reference/load_params.md)

## Value

Returns invisible TRUE if all checks pass. Side effect of stopping
calculations if any check fails.
