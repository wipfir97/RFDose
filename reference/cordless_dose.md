# Calculate Dose from Cordless Calls

Calculates RF-EMF dose from making calls with cordless phone (also known
as DECT phone).

## Usage

``` r
cordless_dose(tissue, duration, ear_prop, params = load_params())
```

## Arguments

- tissue:

  Tissue for which to calculate dose (default: "brain" or "body")

- duration:

  Duration of cordless calls in s/day.

- ear_prop:

  Proportion of time cordless phone is held against ear during calls.

- params:

  Parameter list (optional). If not specified, calculations use default
  parameters.

## Value

Tissue-specific RF-EMF dose from DECT/cordless phone calls in mJ/kg/day

## Details

The dose is calculated as

\$\$Dose\_{DECT} = mSAR\_{DECT}\*duration\_{DECT}\$\$

Where:

- \\Dose\_{DECT}\\ is the dose from DECT/cordless phone calls

- \\mSAR\_{DECT}\\ is the momentary SAR value in mW/kg (see
  [`dect_msar()`](https://wipfir97.github.io/RFDose/reference/dect_msar.md))

- \\duration\_{DECT}\\ is the duration of the calls in s/day

## See also

[`dect_msar()`](https://wipfir97.github.io/RFDose/reference/dect_msar.md)

## Examples

``` r
cordless_dose(
  tissue      = "brain",
  duration    = 600,
  ear_prop    = 0.9)
#> [1] 255.9199
```
