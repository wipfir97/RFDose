# Calculate Mobile Phone Output Power during WiFi Mobile Phone Calls

Calculates the mean output power of the mobile phone during calls using
WiFi connection.

## Usage

``` r
mpc_pwr_wifi(band, params = load_params())
```

## Arguments

- band:

  Frequency band ("2" for 2.4 GHz, "5" for 5.0 GHz) used for the call

- params:

  Parameter list (optional). If not specified, calculations use default
  parameters.

## Value

Output power in mW, including the duty cycle

## Details

The output power depends on the frequency band (2.4 GHz or 5.0 GHz):

\$\$P = DC \times P\_{wifi}\$\$

where \\P\_{wifi}\\ is the output power of the band in mW and \\DC\\ its
duty cycle.

## Examples

``` r
mpc_pwr_wifi(
band  = "5")
#> [1] 9.86
```
