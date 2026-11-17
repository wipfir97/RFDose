# Calculate RF-EMF Dose from Smart Watch

Calculates the tissue-specific RF-EMF dose from smart-watch use

## Usage

``` r
smartwatch_dose(tissue, duration_smartwatch, params = load_params())
```

## Arguments

- tissue:

  Tissue for which to calculate dose (default: "brain" or "body")

- duration_smartwatch:

  duration of time smartwatch was worn in s/day

- params:

  Parameter list (optional). If not specified, calculations use default
  parameters.

## Value

Tissue-specific RF-EMF dose from smart-watch use in mJ/kg/day

## Details

The RF-EMF dose from smart-watch use is calculated as:

\$\$Dose\_{smartwatch} = Dose\_{watch} + Dose\_{phone}\$\$

Where:

- \\Dose\_{watch}\\ is the dose contribution from the smart-watch itself

- \\Dose\_{phone}\\ is the dose contribution from the phone connection
  to the smart-watch

## See also

[`smartwatch_watch_dose()`](https://wipfir97.github.io/RFDose/reference/smartwatch_watch_dose.md),
[`smartwatch_phone_dose()`](https://wipfir97.github.io/RFDose/reference/smartwatch_phone_dose.md)

## Examples

``` r
smartwatch_dose(
  tissue              = "body",
  duration_smartwatch = 6000)
#> [1] 0.2001034
```
