# Calculate nSAR during Tablet Use

Calculates tissue-specific nSAR from tablet use.

## Usage

``` r
tablet_sar(tissue, band, params = load_params())
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

nSAR in W/kg/W

## Details

The normalized specific absorption rate (nSAR) depends on the tissue and
the frequency band.

## Examples

``` r
tablet_sar(
tissue       = "brain",
band         = "2")
#> [1] 0.002454054
```
