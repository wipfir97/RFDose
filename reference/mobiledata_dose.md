# Calculation of RF-EMF Dose from Mobile Phone Data Use

The mobile data RF-EMF dose is calculated as: \$\$Dose\_{data} =
mSAR\_{data}\*duration\_{data}\$\$

## Usage

``` r
mobiledata_dose(
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

  Tissue for which to calculate dose (default: "brain" or "body")

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

Tissue-specific RF-EMF dose from data use in mJ/kg/day

## Details

Where:

- \\Dose\_{data}\\ is the dose from mobile data use

- \\mSAR\_{data}\\ is the momentary SAR value in mW/kg (see
  [`mpd_msar()`](https://wipfir97.github.io/RFDose/reference/mpd_msar.md))

- \\duration\_{data}\\ is the duration of mobile data use in s/day (sum
  of the durations of the four activities)

We distinguish between 4 types of mobile data use:

1.  Low output power: sending e-mails, browsing the internet, scrolling
    and chatting on social media, sending text messages

2.  Low to medium output power: online gaming, streaming music, sending
    voice messages

3.  Medium to high output power: watching videos, uploading pictures or
    videos, making video calls

4.  High output power: uploading large files

## See also

[`mpd_msar()`](https://wipfir97.github.io/RFDose/reference/mpd_msar.md)

## Examples

``` r
mobiledata_dose(
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
#> [1] 239.2962
```
