# Calculate nSAR during Laptop Use

Calculates tissue-specific nSAR from laptop use.

## Usage

``` r
laptop_sar(tissue, band, params = load_params())
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

The normalized specific absorption rate (nSAR) depends on the tissue,
the frequency band and the placement of the laptop (on the legs or on a
table):

\$\$nSAR = f\_{legs} \times nSAR\_{legs} + f\_{table} \times
nSAR\_{table}\$\$

where \\f\_{legs}\\ and \\f\_{table}\\ are the proportions of the
placements (parameters `legs_prop` and `tabl_prop`, set by the SAR file)
and the nSAR values are in W/kg/W.

## Examples

``` r
laptop_sar(
tissue       = "brain",
band         = "2")
#> [1] 0.0003988323
```
