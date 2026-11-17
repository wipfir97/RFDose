# Calculate nSAR from WiFi Router

Calculates tissue-specific nSAR from WiFi Router

## Usage

``` r
wifi_sar(tissue, band, params = load_params())
```

## Arguments

- tissue:

  Tissue for which to calculate nSAR (default: "brain" or "body")

- band:

  Frequency band ("2" for 2.4 GHz, "5" for 5.0 GHz)

- params:

  Parameter list (optional). If not specified, calculations use default
  parameters.

## Value

nSAR in W/kg per W/m\\^2\\ of incident power density

## Details

The normalized specific absorption rate (nSAR) depends on the tissue and
the WiFi frequency band.

## Examples

``` r
wifi_sar(
tissue = "brain",
band   = "5")
#> [1] 0.000537153
```
