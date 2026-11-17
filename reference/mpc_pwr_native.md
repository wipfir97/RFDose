# Calculate Mobile Phone Output Power during Native Mobile Phone Calls

Calculates the mean output power of the mobile phone during calls using
the native network.

## Usage

``` r
mpc_pwr_native(band, urbanicity, travel_time, params = load_params())
```

## Arguments

- band:

  Technology ("2g", "3g", "4g" or "5g") used for the call

- urbanicity:

  Urbanicity of home / workplace (rural, suburban, or urban)

- travel_time:

  Time spent commuting in seconds per day

- params:

  Parameter list (optional). If not specified, calculations use default
  parameters.

## Value

Output power in mW, including the duty cycle

## Details

The output power depends on the technology and on where the call is made
(urbanicity; indoors, outdoors or commuting):

\$\$P = DC \times (t\_{ind} \times P\_{ind} + t\_{out} \times P\_{out} +
t\_{travel} \times P\_{travel})\$\$

where \\t\_{ind}\\, \\t\_{out}\\ and \\t\_{travel}\\ are the shares of
the day at home or at work, outdoors and commuting (see
[`location_props()`](https://wipfir97.github.io/RFDose/reference/location_props.md)),
\\P\_{ind}\\, \\P\_{out}\\ and \\P\_{travel}\\ the output powers there
in mW (indoors and outdoors: for the urbanicity), and \\DC\\ the duty
cycle of the technology.

## Examples

``` r
mpc_pwr_native(
band        = "4g",
urbanicity  = "suburban",
travel_time = 1800)
#> [1] 7.69922
```
