# Calculate nSAR during mobile data use on mobile phone

Calculates tissue-specific nSAR from mobile data use on mobile phone.

## Usage

``` r
mpd_sar_data(band, tissue, params = load_params())
```

## Arguments

- band:

  Technology ("3g", "4g", or "5g")

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
mpd_sar_data(
tissue       = "brain",
band         = "5g")
#> [1] 0.001216432
```
