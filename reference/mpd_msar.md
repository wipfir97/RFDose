# Calculation of mSAR from Mobile Phone Data

Calculates mSAR (momentary specifc absorption rate) from data (mobile
data and WiFi) use for a specific tissue

## Usage

``` r
mpd_msar(
  tissue,
  duration_low,
  duration_lowmed,
  duration_medhigh,
  duration_high,
  use_5g,
  wifi_prop_home,
  wifi_prop_work,
  wifi_prop_travel,
  urbanicity,
  travel_time,
  params = load_params()
)
```

## Arguments

- tissue:

  Tissue for which to calculate mSAR (default: "brain" or "body")

- duration_low:

  Duration (in seconds per day) of low output power activities

- duration_lowmed:

  Duration (in seconds per day) of low-medium output power activities

- duration_medhigh:

  Duration (in seconds per day) of medium-high output power activities

- duration_high:

  Duration (in seconds per day) of high output power activities

- use_5g:

  TRUE if 5G services are used for data transfer, FALSE if not

- wifi_prop_home:

  Proportion of time connected to WiFi (vs mobile data) at home

- wifi_prop_work:

  Proportion of time connected to WiFi (vs mobile data) at school / work

- wifi_prop_travel:

  Proportion of time connected to WiFi (vs mobile data) while commuting

- urbanicity:

  Urbanicity of home / workplace (rural, suburban, or urban)

- travel_time:

  Time spent commuting in seconds per day

- params:

  Parameter list (optional). If not specified, calculations use default
  parameters.

## Value

Momentary SAR (mSAR) from mobile data use in mW/kg

## Details

The mSAR is calculated as

\$\$mSAR = (1 - p\_{wifi}) \times mSAR\_{data} + p\_{wifi} \times
mSAR\_{wifi}\$\$

with, for each network \\n\\ (mobile data or WiFi),

\$\$mSAR\_{n} = \sum\_{b} s\_{n,b} \times nSAR\_{n,b} \times
P\_{n,b}\$\$

where

- \\p\_{wifi} = t\_{home} w\_{home} + t\_{work} w\_{work} + t\_{travel}
  w\_{travel}\\ is the proportion of use over WiFi, with \\t\\ the
  shares of the day at home, at work and commuting (see
  [`location_props()`](https://wipfir97.github.io/RFDose/reference/location_props.md))
  and \\w\\ the WiFi proportions (`wifi_prop_home`, `wifi_prop_work`,
  `wifi_prop_travel`); no WiFi is used outdoors

- \\s\_{n,b}\\ is the share of the frequency band \\b\\: 3G to 5G for
  mobile data (without 5G if `use_5g` is FALSE), 2.4 and 5 GHz for WiFi

- \\nSAR\_{n,b}\\ is the normalized SAR in W/kg/W (see
  [`mpd_sar_data()`](https://wipfir97.github.io/RFDose/reference/mpd_sar_data.md),
  [`mpd_sar_wifi()`](https://wipfir97.github.io/RFDose/reference/mpd_sar_wifi.md))

- \\P\_{n,b}\\ is the mean output power of the phone in mW, including
  the duty cycles of the activities (see
  [`mpd_pwr_data()`](https://wipfir97.github.io/RFDose/reference/mpd_pwr_data.md),
  [`mpd_pwr_wifi()`](https://wipfir97.github.io/RFDose/reference/mpd_pwr_wifi.md))

## See also

[`mpd_pwr_data()`](https://wipfir97.github.io/RFDose/reference/mpd_pwr_data.md),
[`mpd_pwr_wifi()`](https://wipfir97.github.io/RFDose/reference/mpd_pwr_wifi.md),
[`mpd_sar_data()`](https://wipfir97.github.io/RFDose/reference/mpd_sar_data.md),
[`mpd_sar_wifi()`](https://wipfir97.github.io/RFDose/reference/mpd_sar_wifi.md)

## Examples

``` r
mpd_msar(
tissue           = "brain",
duration_low     = 4860,
duration_lowmed  = 540,
duration_medhigh = 4860,
duration_high    = 540,
use_5g           = FALSE,
wifi_prop_home   = 0.5,
wifi_prop_work   = 0.5,
wifi_prop_travel = 0.5,
urbanicity       = "suburban",
travel_time      = 1800)
#> [1] 0.02215706
```
