# Calculate nSAR during WiFi Use on mobile phone

Calculates tissue-specific nSAR from WiFi use on mobile phone.

## Usage

``` r
mpd_sar_wifi(band, tissue, params = load_params())
```

## Arguments

- band:

  Frequency band ("2" for 2.4 GHz, "5" for 5.0 GHz)

- tissue:

  Tissue for which to calculate nSAR (default: "brain" or "body")

- params:

  Parameter list (optional). If not specified, calculations use default
  parameters.

## Value

nSAR in W/kg/W

## Details

The normalized specific absorption rate (nSAR) depends on the tissue and
the frequency band.

## Examples

``` r
mpd_sar_wifi(
tissue       = "brain",
band         = "2")
#> [1] 0.002454054
```
