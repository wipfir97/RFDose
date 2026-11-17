# Calculate RF-EMF Dose from WiFi Router

Calculates the tissue-specific RF-EMF dose from WiFi router

## Usage

``` r
wifi_dose(tissue, travel_time, wifi_prop_travel, params = load_params())
```

## Arguments

- tissue:

  Tissue for which to calculate dose (default: "brain" or "body")

- travel_time:

  Time spent commuting in seconds per day

- wifi_prop_travel:

  Proportion of time connected to WiFi (vs mobile data) while commuting

- params:

  Parameter list (optional). If not specified, calculations use default
  parameters.

## Value

Tissue-specific RF-EMF dose from Wifi router in mJ/kg/day

## Details

The RF-EMF dose from WiFi router is calculated as:

\$\$Dose\_{WiFi} = mSAR\_{WiFi} \times duration\_{WiFi}\$\$

Where:

- \\Dose\_{WiFi}\\ is the dose from WiFi Router

- \\mSAR\_{WiFi}\\ is the momentary SAR value in mW/kg (see
  [`wifi_msar()`](https://wipfir97.github.io/RFDose/reference/wifi_msar.md))

- \\duration\_{WiFi}\\ is the duration of time exposed to a WiFi router
  in seconds/day

The exposure lasts the whole time at home and at work, none of the time
outdoors, and the whole time commuting if WiFi is used while commuting
(`wifi_prop_travel` above 0):

\$\$duration\_{WiFi} = 86400 \times (t\_{home} + t\_{work} +
t\_{travel})\$\$

where \\t\\ are the shares of the day at home, at work and commuting
(see
[`location_props()`](https://wipfir97.github.io/RFDose/reference/location_props.md));
\\t\_{travel}\\ counts only if `wifi_prop_travel` is above 0.

## See also

[`wifi_msar()`](https://wipfir97.github.io/RFDose/reference/wifi_msar.md)

## Examples

``` r
wifi_dose(
  tissue           = "body",
  travel_time      = 1800,
  wifi_prop_travel = 0.5)
#> [1] 5.638597
```
