# Calculate Power Density of WiFi Router

Calculates the power density of WiFi router

## Usage

``` r
wifi_pwr(band, params = load_params())
```

## Arguments

- band:

  Frequency band ("2" for 2.4 GHz, "5" for 5.0 GHz)

- params:

  Parameter list (optional). If not specified, calculations use default
  parameters.

## Value

Power density in mW/m\\^2\\

## Details

The power density depends on the WiFi frequency band.

## Examples

``` r
wifi_pwr(
band = "2")
#> [1] 0.018
```
