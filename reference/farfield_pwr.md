# Calculate Power Density of Far-field Sources

Calculates the power density of far-field sources

## Usage

``` r
farfield_pwr(country, urbanicity, travel_time, params = load_params())
```

## Arguments

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

Power density in mW/m\\^2\\

## Details

The power density depends on the country, urbanicity, and time spent
commuting:

\$\$S = t\_{home} \times S\_{home} + t\_{work} \times S\_{work} +
t\_{out} \times S\_{out} + t\_{travel} \times S\_{travel}\$\$

where \\t\\ are the shares of the day at home, at work, outdoors and
commuting (see
[`location_props()`](https://wipfir97.github.io/RFDose/reference/location_props.md))
and \\S\_{home}\\, \\S\_{work}\\, \\S\_{out}\\, \\S\_{travel}\\ the
power densities there in mW/m\\^2\\, for the country (and, except while
commuting, for the urbanicity).

## Examples

``` r
farfield_pwr(
country     = "CH",
urbanicity  = "suburban",
travel_time = 1800)
#> [1] 0.1103119
```
