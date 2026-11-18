# Deterministic Calculations

``` r

library(RFDose)
```

## Basic Example

A basic example will be added here.

## Using individual source functions

Behind the scenes,
[`calculate_emf_doses()`](https://wipfir97.github.io/RFDose/reference/calculate_emf_doses.md)
calls various source-specific dose functions, which calculate the
individual contributions of different sources (e.g. mobile phone calls).
These functions may be used individually.

An example will be added here.

## Using Your Own Parameter File

Use your own parameters by providing a custom file using the `params`
argument. This file must be in YAML format and follow the same structure
as the [inbuilt parameter
file](https://wipfir97.github.io/RFDose/articles/inst/extdata/params.yaml),
which contains all parameters except SAR values (for changing the SAR
values, please check the next section).

**Note that the R package does not currently check the structure of
custom parameter files, so mismatches may result in faulty
calculations.**

## Changing the SAR Values

`RFDose` provides the following SAR values to use for the calculations,
which the input argument `sar_file` takes by name
([`available_sar_files()`](https://wipfir97.github.io/RFDose/reference/available_sar_files.md)
lists them):

| Name | SAR values | File in `inst/extdata/` |
|----|----|----|
| `"goliat_average"` | GOLIAT, average of the four phantoms (default) | `sar_goliat_average.yaml` |
| `"goliat_duke"`, `"goliat_ella"`, `"goliat_eartha"`, `"goliat_thelonious"` | GOLIAT, one phantom | `sar_goliat_<phantom>.yaml` |
| `"etain"` | ETAIN | `sar_etain.yaml` |

Each of these files also sets the laptop and headphone placement
proportions that go with its SAR values. The assumptions behind the
GOLIAT files are described in [GOLIAT SAR values](#goliat-sar-values).

``` r

# Calculate example doses with the GOLIAT SAR values, average of the four phantoms (default)
calculate_emf_doses(
  example_data, 
  tissue = "brain", 
  sar_file = "goliat_average")
#>   sample_id use_5g travel_time country urbanicity headp_ear_num mpc_duration
#> 1     TEST1   TRUE        1800   Other   suburban             2          425
#> 2     TEST2   TRUE        1800      CH      rural             2          120
#> 3     TEST3  FALSE        1800      ES      urban             1          903
#>   mpc_ear_prop mpc_headp_prop mpd_wifi_prop_home mpd_wifi_prop_travel
#> 1         0.66           0.17                0.5                  0.5
#> 2         0.80           0.00                0.5                  0.5
#> 3         0.90           0.10                0.5                  0.5
#>   mpd_wifi_prop_work mpd_dur_low mpd_dur_lowtomed mpd_dur_medtohigh
#> 1                0.5        4860              540              4860
#> 2                0.5           0                0                 0
#> 3                0.5           0                0                 0
#>   mpd_dur_high dect_duration dect_ear_prop lptp_dur_low lptp_dur_lowtomed
#> 1          540           204           0.9         1967               219
#> 2            0           580           0.8            0                 0
#> 3            0            90           0.5            0                 0
#>   lptp_dur_medtohigh lptp_dur_high tblt_dur_low tblt_dur_lowtomed
#> 1               1967           219          728                81
#> 2                  0             0            0                 0
#> 3                  0             0            0                 0
#>   tblt_dur_medtohigh tblt_dur_high hotspot_duration smartwatch_duration
#> 1                728            81                0                   0
#> 2                  0             0                0               86400
#> 3                  0             0              600                   0
#>   vr_duration headphone_duration gaming_duration call_dose data_dose dect_dose
#> 1           0                  0             600   73.1587  203.0995  87.01276
#> 2        1200                  0               0   27.8527    0.0000 221.80559
#> 3           0               8280            1200  170.9787    0.0000  22.50849
#>   farf_dose wifi_dose lptp_dose tblt_dose other_dose
#> 1 160.64975  2.804097  11.41956  25.70129   1.150865
#> 2  38.33047  2.804097   0.00000   0.00000 163.734543
#> 3 231.51558  2.804097   0.00000   0.00000   4.693819

# Calculate example doses with the SAR values of one GOLIAT phantom
calculate_emf_doses(
  example_data, 
  tissue = "brain", 
  sar_file = "goliat_duke")
#>   sample_id use_5g travel_time country urbanicity headp_ear_num mpc_duration
#> 1     TEST1   TRUE        1800   Other   suburban             2          425
#> 2     TEST2   TRUE        1800      CH      rural             2          120
#> 3     TEST3  FALSE        1800      ES      urban             1          903
#>   mpc_ear_prop mpc_headp_prop mpd_wifi_prop_home mpd_wifi_prop_travel
#> 1         0.66           0.17                0.5                  0.5
#> 2         0.80           0.00                0.5                  0.5
#> 3         0.90           0.10                0.5                  0.5
#>   mpd_wifi_prop_work mpd_dur_low mpd_dur_lowtomed mpd_dur_medtohigh
#> 1                0.5        4860              540              4860
#> 2                0.5           0                0                 0
#> 3                0.5           0                0                 0
#>   mpd_dur_high dect_duration dect_ear_prop lptp_dur_low lptp_dur_lowtomed
#> 1          540           204           0.9         1967               219
#> 2            0           580           0.8            0                 0
#> 3            0            90           0.5            0                 0
#>   lptp_dur_medtohigh lptp_dur_high tblt_dur_low tblt_dur_lowtomed
#> 1               1967           219          728                81
#> 2                  0             0            0                 0
#> 3                  0             0            0                 0
#>   tblt_dur_medtohigh tblt_dur_high hotspot_duration smartwatch_duration
#> 1                728            81                0                   0
#> 2                  0             0                0               86400
#> 3                  0             0              600                   0
#>   vr_duration headphone_duration gaming_duration call_dose data_dose dect_dose
#> 1           0                  0             600  86.62188  76.95616 126.34999
#> 2        1200                  0               0  33.09208   0.00000 320.37405
#> 3           0               8280            1200 206.72676   0.00000  31.62494
#>   farf_dose wifi_dose lptp_dose tblt_dose  other_dose
#> 1 133.38292  1.682686  1.529422  10.74767   0.4544001
#> 2  31.82469  1.682686  0.000000   0.00000 285.3196577
#> 3 192.22079  1.682686  0.000000   0.00000   2.2486196
```

If you would like to provide your own SAR values to the calculations,
provide a YAML file containing the SAR values. Make sure it follows the
same structure as the [inbuilt SAR
files](https://wipfir97.github.io/RFDose/articles/inst/extdata/sar_goliat_average.yaml).
All other parameters keep their default values (or the values of
`params`, if supplied), except device parameters that the SAR file sets
itself (e.g. placement proportions that go with its SAR values).

## Missing data and default values

`RFDose` currently handles missing values by replacing them with default
values, which are derived from survey responses of the ongoing [GOLIAT
consortium studies](https://projectgoliat.eu/).

Default values are specified in [this YAML
file](https://wipfir97.github.io/RFDose/articles/inst/extdata/defaultvariables.yaml)

## Output

`calculate_emf_doses` returns a data frame containing the original data
columns, as well as one additional column per source with its dose
contribution in mJ/kg/day for the chosen tissue:

| Column | Source |
|----|----|
| call_dose | Mobile phone calls (mpc) |
| data_dose | Mobile data (mpd) |
| dect_dose | Cordless phone (dect) |
| farf_dose | Far-field (farf) |
| wifi_dose | WiFi router (wifi) |
| lptp_dose | Laptop (lptp) |
| tblt_dose | Tablet (tblt) |
| other_dose | Other devices: smartwatch, VR headset, hotspot, Bluetooth headphones, and gaming consoles (other) |

The doses depend on the SAR values used (GOLIAT by default, see [GOLIAT
SAR values](#goliat-sar-values)).
