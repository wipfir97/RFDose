# Calculate mSAR of Far-field Sources

Calculates the mSAR of far-field sources

## Usage

``` r
farfield_msar(tissue, country, urbanicity, travel_time, params = load_params())
```

## Arguments

- tissue:

  Tissue for which to calculate nSAR (default: "brain" or "body")

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

mSAR in mW/kg

## Details

\$\$mSAR\_{farfield} = nSAR\_{farfield} \times S\$\$

where \\nSAR\_{farfield}\\ is the normalized SAR in W/kg per W/m\\^2\\
(see
[`farfield_sar()`](https://wipfir97.github.io/RFDose/reference/farfield_sar.md))
and \\S\\ the power density in mW/m\\^2\\ (see
[`farfield_pwr()`](https://wipfir97.github.io/RFDose/reference/farfield_pwr.md)).
The power density depends on the country, urbanicity, and time spent
commuting.

## See also

[`farfield_pwr()`](https://wipfir97.github.io/RFDose/reference/farfield_pwr.md),
[`farfield_sar()`](https://wipfir97.github.io/RFDose/reference/farfield_sar.md)

## Examples

``` r
farfield_msar(
  tissue      = "body",
  country     = "CH",
  urbanicity  = "suburban",
  travel_time = 1800)
#> [1] 0.0006716403
```
