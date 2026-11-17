# Calculate RF-EMF Dose from Far-field Sources

Calculates the tissue-specific RF-EMF dose from far-field sources

## Usage

``` r
farfield_dose(tissue, country, urbanicity, travel_time, params = load_params())
```

## Arguments

- tissue:

  Tissue for which to calculate dose (default: "brain" or "body")

- country:

  Country of residence (Austria = "AT", Belgium = "BE", France = FR,
  Hungary = "HU", Italy = "IT", Netherlands = "NL", Poland = "PL", Spain
  = "ES", Switzerland = "CH", United Kingdom = "UK", elsewhere =
  "Other")

- urbanicity:

  Urbanicity of home / workplace (rural, suburban, or urban)

- travel_time:

  Time spent commuting in seconds per day

- params:

  Parameter list (optional). If not specified, calculations use default
  parameters.

## Value

Tissue-specific RF-EMF dose from far-field sources in mJ/kg/day

## Details

The RF-EMF dose from far-field sources is calculated as:

\$\$Dose\_{farfield} = mSAR\_{farfield} \times 86400\$\$

Where:

- \\Dose\_{farfield}\\ is the dose from far-field sources

- \\mSAR\_{farfield}\\ is the momentary SAR value in mW/kg (see
  [`farfield_msar()`](https://wipfir97.github.io/RFDose/reference/farfield_msar.md))

- 86400 s/day: the far-field exposure lasts the whole day

## See also

[`farfield_msar()`](https://wipfir97.github.io/RFDose/reference/farfield_msar.md)

## Examples

``` r
farfield_dose(
  tissue      = "body",
  country     = "CH",
  urbanicity  = "suburban",
  travel_time = 1800)
#> [1] 58.02972
```
