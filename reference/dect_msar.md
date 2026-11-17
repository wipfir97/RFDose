# Calculate mSAR from Cordless Calls

Calculates mSAR (momentary SAR) from making calls with cordless phone
(also known as DECT phone).

## Usage

``` r
dect_msar(tissue, ear_prop, params = load_params())
```

## Arguments

- tissue:

  Tissue for which to calculate mSAR (default: "brain" or "body")

- ear_prop:

  Proportion of time cordless phone is held against ear during calls.

- params:

  Parameter list (optional). If not specified, calculations use default
  parameters.

## Value

Tissue-specific mSAR from DECT/cordless phone calls in mW/kg

## Details

The mSAR is calculated as

\$\$mSAR\_{DECT} = nSAR\_{DECT} \times P\_{DECT}\$\$

Where:

- \\mSAR\_{DECT}\\ is the mSAR from DECT/cordless phone calls in mW/kg

- \\nSAR\_{DECT}\\ is the nSAR (normalized specific absorption rate) in
  W/kg/W, weighted over the positions of the phone (see
  [`dect_sar()`](https://wipfir97.github.io/RFDose/reference/dect_sar.md))

- \\P\_{DECT}\\ is the mean output power of the phone in mW, including
  the duty cycle (see
  [`dect_pwr()`](https://wipfir97.github.io/RFDose/reference/dect_pwr.md))

## See also

[`dect_pwr()`](https://wipfir97.github.io/RFDose/reference/dect_pwr.md),
[`dect_sar()`](https://wipfir97.github.io/RFDose/reference/dect_sar.md)

## Examples

``` r
dect_msar(
  tissue      = "brain",
  ear_prop    = 0.9)
#> [1] 0.4265331
```
