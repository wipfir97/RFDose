# Calculate nSAR from Far-Field Sources

Calculates tissue-specific nSAR from far-field sources.

## Usage

``` r
farfield_sar(tissue, params = load_params())
```

## Arguments

- tissue:

  Tissue for which to calculate nSAR (default: "brain" or "body")

- params:

  Parameter list (optional). If not specified, calculations use default
  parameters.

## Value

nSAR in W/kg per W/m\\^2\\ of incident power density

## Details

The normalized specific absorption rate (nSAR) depends on the tissue.

## Examples

``` r
farfield_sar(
tissue       = "brain")
#> [1] 0.005429732
```
