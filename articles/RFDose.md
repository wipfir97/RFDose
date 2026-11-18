# RFDose

``` r

library(RFDose)
```

## Overview

RFDose is an R package designed to estimate personal radio-frequency
electromagnetic field (RF-EMF) doses. It takes into account different
device types and tissues, as well as exposure from far-field sources.

## Background

The calculations in this package are based on an RF-EMF dose model
developed by Jalilian et al (publication in writing stage as of November
2026). On [this
page](https://wipfir97.github.io/RFDose/articles/dose_model_background.html),
you can find a summary of the background of this model.

## Expected Input Data

The expected input data will be described here once finalized.

## Example Usage

``` r

# Load example data from three hypothetical study participants
data(example_data)
# View example data
head(example_data)
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
#>   vr_duration headphone_duration gaming_duration
#> 1           0                  0             600
#> 2        1200                  0               0
#> 3           0               8280            1200
```

``` r

# Calculate example doses
calculate_emf_doses(example_data, tissue = "brain") # brain dose
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
calculate_emf_doses(example_data, tissue = "body")  # body dose
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
#> 1           0                  0             600  34.36364  216.1555 32.619818
#> 2        1200                  0               0  12.50237    0.0000 83.750219
#> 3           0               8280            1200  78.02167    0.0000  8.809607
#>   farf_dose wifi_dose lptp_dose tblt_dose other_dose
#> 1 180.14249  5.638597  129.2898  34.31277   1.865883
#> 2  42.98136  5.638597    0.0000   0.00000 109.850750
#> 3 259.60694  5.638597    0.0000   0.00000  17.733269
```

## Development Status

The `RFDose` package is still undergoing development. The calculations
of the dose may change in future versions.

## References

- Detailed background on the RF-EMF dose model by Jalilian et
  al. (manuscript in preparation)
- Short research paper on the `RFDOSE` package (manuscript in
  preparation)
- The [online version](https://swisstph.shinyapps.io/rfdose-online/) of
  `RFDose`
- The [GOLIAT project website](https://projectgoliat.eu/)
- The [ETAIN project website](https://www.etainproject.eu/)

## Contributors and Acknowledgements

Individual contributors will be listed here and in the `RFDose` research
paper once finalized.

`RFDose` was developed as part of the
[GOLIAT](https://projectgoliat.eu/) and
[ETAIN](https://www.etainproject.eu/) consortia.
