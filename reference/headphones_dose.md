# Calculate RF-EMF Dose from Bluetooth Headphones

Calculates the tissue-specific RF-EMF dose from bluetooth headphones
(calls excluded)

## Usage

``` r
headphones_dose(tissue, duration_headphones, params = load_params())
```

## Arguments

- tissue:

  Tissue for which to calculate dose (default: "brain" or "body")

- duration_headphones:

  duration of time Bluetooth headphones were used in s/day

- params:

  Parameter list (optional). If not specified, calculations use default
  parameters.

## Value

Tissue-specific RF-EMF dose from Bluetooth headphone use in mJ/kg/day

## Details

The RF-EMF dose from Bluetooth headphone use is calculated as:

\$\$Dose\_{headphones} = Dose\_{earset} + Dose\_{phone}\$\$

Where:

- \\Dose\_{earset}\\ is the dose contribution from the headphones
  themselves

- \\Dose\_{phone}\\ is the dose contribution from the phone connection
  to the headphones

## See also

[`headphones_earset_dose()`](https://wipfir97.github.io/RFDose/reference/headphones_earset_dose.md),
[`headphones_phone_dose()`](https://wipfir97.github.io/RFDose/reference/headphones_phone_dose.md)

## Examples

``` r
headphones_dose(
  tissue              = "body",
  duration_headphones = 6000)
#> [1] 2.600112
```
