# Calculate RF-EMF Dose from Other Sources

Wrapper function that calculates total dose from additional devices and
activities, as used in the GOLIAT consortium study dose calculation.

## Usage

``` r
other_dose_wrapper(
  tissue,
  duration_hotspot,
  duration_smartwatch,
  duration_vr,
  duration_headphones,
  duration_gaming,
  params = load_params()
)
```

## Arguments

- tissue:

  Tissue for which to calculate dose (default: "brain" or "body")

- duration_hotspot:

  Duration of time hotspot was active in s/day

- duration_smartwatch:

  Duration of time smartwatch was used in s/day

- duration_vr:

  Duration of time VR headset was used in s/day

- duration_headphones:

  Duration of time Bluetooth headphones were used in s/day

- duration_gaming:

  Duration of gaming with portable console in s/day

- params:

  Parameter list (optional). If not specified, calculations use default
  parameters.

## Value

Tissue-specific RF-EMF dose from other sources in mJ/kg/day

## Details

The RF-EMF dose from other sources takes into account 5 additional
sources:

1.  Hotspot (smartphone)

2.  Smart watch

3.  Virtual reality (VR) headset

4.  Bluetooth headphones

5.  Portable gaming consoles

The dose is calculated as

\$\$Dose\_{other} = Dose\_{hotspot} + Dose\_{smartwatch} + Dose\_{vr} +
Dose\_{headphones} + Dose\_{gaming}\$\$

The dose from each source is calculated from the corresponding dose
functions.

## See also

[`hotspot_dose()`](https://wipfir97.github.io/RFDose/reference/hotspot_dose.md),
[`smartwatch_dose()`](https://wipfir97.github.io/RFDose/reference/smartwatch_dose.md),
[`vr_dose()`](https://wipfir97.github.io/RFDose/reference/vr_dose.md),
[`headphones_dose()`](https://wipfir97.github.io/RFDose/reference/headphones_dose.md),
[`gaming_dose()`](https://wipfir97.github.io/RFDose/reference/gaming_dose.md)

## Examples

``` r
other_dose_wrapper(
  tissue              = "brain",
  duration_hotspot    = 600,
  duration_smartwatch = 86400,
  duration_vr         = 0,
  duration_headphones = 8280,
  duration_gaming     = 3600)
#> [1] 9.366622
```
