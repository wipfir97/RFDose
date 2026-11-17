# Calculate nSAR from Cordless Calls

Calculates nSAR (normalized specific absorption rate) from making calls
with cordless phone (also known as DECT phone).

## Usage

``` r
dect_sar(tissue, ear_prop, params = load_params())
```

## Arguments

- tissue:

  Tissue for which to calculate the nSAR (default: "brain" or "body")

- ear_prop:

  Proportion of time cordless phone is held against ear during calls.

- params:

  Parameter list (optional). If not specified, calculations use default
  parameters.

## Value

Tissue-specific nSAR from DECT/cordless phone calls in W/kg/W

## Details

\$\$nSAR\_{DECT} = p\_{ear} \times nSAR\_{ear} + (1 - p\_{ear}) \times
nSAR\_{speaker}\$\$

where \\p\_{ear}\\ is the proportion of the call with the phone against
the ear (`ear_prop`), the rest in speaker mode, and the nSAR values are
in W/kg/W.

## Examples

``` r
dect_sar(
  tissue      = "brain",
  ear_prop    = 0.9)
#> [1] 0.04265331
```
