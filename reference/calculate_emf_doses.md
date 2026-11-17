# Calculate Total RF-EMF Doses for ALL samples

Wrapper function that calculates RF-EMF doses for a data frame of
observations.

## Usage

``` r
calculate_emf_doses(
  data,
  tissue,
  params = NULL,
  default_value_file = NULL,
  sar_file = NULL
)
```

## Arguments

- data:

  A data frame. Must have the exact same columns as the provided example
  dataset. Columns must not be missing. Missing values will be replaced
  with default values.

- tissue:

  Tissue for which to calculate dose (default: "brain" or "body")

- params:

  (experimental) Path to a parameter file in .yaml format. Must match
  the structure of the internal parameter file. Optional; if not
  specified, calculations use default parameters. SAR values may be left
  out (see `sar_file`).

- default_value_file:

  List of default values to replace missing values (optional).

- sar_file:

  SAR values (optional): the name of a SAR file included in the package,
  or the path to your own .yaml file with the structure of the included
  SAR files. Included SAR files (see
  [`available_sar_files()`](https://wipfir97.github.io/RFDose/reference/available_sar_files.md)):

  - `"goliat_average"`: GOLIAT, average of the four phantoms (default)

  - `"goliat_duke"`, `"goliat_ella"`, `"goliat_eartha"`,
    `"goliat_thelonious"`: GOLIAT, one phantom

  - `"etain"`: ETAIN

  Its values replace those of `params`, including device parameters it
  sets with its SAR values (e.g. placement proportions). If not
  specified, the SAR values of `params` are used, or the default SAR
  values if `params` has none.

## Value

A data frame: the columns of `data`, plus one column per exposure source
with the RF-EMF dose of each row in mJ/kg/day for the chosen tissue.

## Details

Additional details will follow.

## Examples

``` r
# Brain doses of the example data, in mJ/kg/day: the input columns, plus one
# column per exposure source
doses   <- calculate_emf_doses(example_data, tissue = "brain")
sources <- c("call_dose", "data_dose", "dect_dose", "farf_dose", "wifi_dose",
             "lptp_dose", "tblt_dose", "other_dose")
doses[, c("sample_id", sources)]
#>   sample_id call_dose data_dose dect_dose farf_dose wifi_dose lptp_dose
#> 1     TEST1   73.1587  203.0995  87.01276 160.64975  2.804097  11.41956
#> 2     TEST2   27.8527    0.0000 221.80559  38.33047  2.804097   0.00000
#> 3     TEST3  170.9787    0.0000  22.50849 231.51558  2.804097   0.00000
#>   tblt_dose other_dose
#> 1  25.70129   1.150865
#> 2   0.00000 163.734543
#> 3   0.00000   4.693819

# Total brain dose of each row
rowSums(doses[, sources])
#> [1] 564.9965 454.5274 432.5007

# Whole-body doses
body <- calculate_emf_doses(example_data, tissue = "body")
body[, c("sample_id", sources)]
#>   sample_id call_dose data_dose dect_dose farf_dose wifi_dose lptp_dose
#> 1     TEST1  34.36364  216.1555 32.619818 180.14249  5.638597  129.2898
#> 2     TEST2  12.50237    0.0000 83.750219  42.98136  5.638597    0.0000
#> 3     TEST3  78.02167    0.0000  8.809607 259.60694  5.638597    0.0000
#>   tblt_dose other_dose
#> 1  34.31277   1.865883
#> 2   0.00000 109.850750
#> 3   0.00000  17.733269

# With the SAR values of one GOLIAT phantom (see available_sar_files())
duke <- calculate_emf_doses(example_data, tissue = "brain", sar_file = "goliat_duke")
duke[, c("sample_id", sources)]
#>   sample_id call_dose data_dose dect_dose farf_dose wifi_dose lptp_dose
#> 1     TEST1  86.62188  76.95616 126.34999 133.38292  1.682686  1.529422
#> 2     TEST2  33.09208   0.00000 320.37405  31.82469  1.682686  0.000000
#> 3     TEST3 206.72676   0.00000  31.62494 192.22079  1.682686  0.000000
#>   tblt_dose  other_dose
#> 1  10.74767   0.4544001
#> 2   0.00000 285.3196577
#> 3   0.00000   2.2486196

# With your own parameter and SAR files (YAML, with the structure of the
# included files)
if (FALSE) { # \dontrun{
calculate_emf_doses(
  example_data,
  tissue   = "brain",
  params   = "path_to_my_file/my_params.yaml",
  sar_file = "path_to_my_file/my_sar.yaml")
} # }
```
