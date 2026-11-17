# SAR files included in the package

Lists the names of the SAR files included in the package. A name can be
used instead of a file path to choose the SAR values, e.g.
`calculate_emf_doses(data, tissue, sar_file = "goliat_average")`.

## Usage

``` r
available_sar_files()
```

## Value

Character vector of SAR file names.

## Details

- `"goliat_average"`: GOLIAT, average of the four phantoms (default)

- `"goliat_duke"`, `"goliat_ella"`, `"goliat_eartha"`,
  `"goliat_thelonious"`: GOLIAT, one phantom

- `"etain"`: ETAIN

Each SAR file also sets the placement proportions that go with its SAR
values.

## See also

[`load_params()`](https://wipfir97.github.io/RFDose/reference/load_params.md),
[`calculate_emf_doses()`](https://wipfir97.github.io/RFDose/reference/calculate_emf_doses.md)

## Examples

``` r
available_sar_files()
#> [1] "etain"             "goliat_average"    "goliat_duke"      
#> [4] "goliat_eartha"     "goliat_ella"       "goliat_thelonious"
```
