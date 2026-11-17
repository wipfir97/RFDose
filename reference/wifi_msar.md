# Calculate mSAR of WiFi Router

Calculates the mSAR of WiFi Router

## Usage

``` r
wifi_msar(tissue, params = load_params())
```

## Arguments

- tissue:

  Tissue for which to calculate mSAR (default: "brain" or "body")

- params:

  Parameter list (optional). If not specified, calculations use default
  parameters.

## Value

mSAR in mW/kg

## Details

\$\$mSAR\_{WiFi} = \sum\_{b} s\_{b} \times nSAR\_{b} \times S\_{b}\$\$

where \\s\_{b}\\ is the share of the frequency band \\b\\ (2.4 and 5
GHz), \\nSAR\_{b}\\ the normalized SAR in W/kg per W/m\\^2\\ (see
[`wifi_sar()`](https://wipfir97.github.io/RFDose/reference/wifi_sar.md))
and \\S\_{b}\\ the power density of the WiFi router in mW/m\\^2\\ (see
[`wifi_pwr()`](https://wipfir97.github.io/RFDose/reference/wifi_pwr.md)).
The time spent commuting and the WiFi use while commuting only change
the exposure time (see
[`wifi_dose()`](https://wipfir97.github.io/RFDose/reference/wifi_dose.md)).

## See also

[`wifi_pwr()`](https://wipfir97.github.io/RFDose/reference/wifi_pwr.md),
[`wifi_sar()`](https://wipfir97.github.io/RFDose/reference/wifi_sar.md)

## Examples

``` r
wifi_msar(
  tissue = "body")
#> [1] 7.11944e-05
```
