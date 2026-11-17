# Path of a SAR file

Path of a SAR file

## Usage

``` r
sar_file_path(sar_file)
```

## Arguments

- sar_file:

  Name of a SAR file included in the package (see
  [`available_sar_files()`](https://wipfir97.github.io/RFDose/reference/available_sar_files.md),
  case is ignored) or path of a YAML file

## Value

Path of the SAR file. Side effect of stopping calculation if the file
does not exist.
