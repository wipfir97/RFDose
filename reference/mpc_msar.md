# Calculation of mSAR from Mobile Phone Calls

Calculates mSAR (momentary specifc absorption rate) from mobile calls
for a specific tissue.

## Usage

``` r
mpc_msar(
  tissue,
  prop_native,
  prop_data,
  prop_wifi,
  headp_prop,
  ear_prop,
  speaker_prop,
  urbanicity,
  use_5g,
  travel_time,
  params = load_params()
)
```

## Arguments

- tissue:

  Tissue for which to calculate mSAR (default: "brain" or "body")

- prop_native:

  Proportion of mobile call using native connection

- prop_data:

  Proportion of mobile call using mobile data connection

- prop_wifi:

  Proportion of mobile call using WiFi connection

- headp_prop:

  Proportion of call performed with active Bluetooth connection to
  headphones

- ear_prop:

  Proportion of call performed with phone held against ear

- speaker_prop:

  Proportion of call performed in speaker mode

- urbanicity:

  Urbanicity of home / workplace (rural, suburban, or urban)

- use_5g:

  TRUE if 5g services are used for calls, FALSE if not

- travel_time:

  Time spent commuting in seconds per day

- params:

  Parameter list (optional). If not specified, calculations use default
  parameters.

## Value

Momentary SAR (mSAR) in mW/kg

## Details

The mSAR is calculated as

\$\$mSAR = p\_{native} \times mSAR\_{native} + p\_{data} \times
mSAR\_{data} + p\_{wifi} \times mSAR\_{wifi}\$\$

with, for each network \\n\\ (native, data or WiFi),

\$\$mSAR\_{n} = \sum\_{b} s\_{n,b} \times nSAR\_{n,b} \times
P\_{n,b}\$\$

where

- \\p\_{native}\\, \\p\_{data}\\, \\p\_{wifi}\\ are the proportions of
  the call over the native network, mobile data or WiFi (`prop_native`,
  `prop_data`, `prop_wifi`)

- \\s\_{n,b}\\ is the share of the frequency band \\b\\: 2G to 5G for
  native calls, 3G to 5G for data calls (without 5G if `use_5g` is
  FALSE), 2.4 and 5 GHz for WiFi calls

- \\nSAR\_{n,b}\\ is the normalized SAR in W/kg/W, weighted over the
  positions of the phone (see
  [`mpc_sar_native()`](https://wipfir97.github.io/RFDose/reference/mpc_sar_native.md),
  [`mpc_sar_data()`](https://wipfir97.github.io/RFDose/reference/mpc_sar_data.md),
  [`mpc_sar_wifi()`](https://wipfir97.github.io/RFDose/reference/mpc_sar_wifi.md))

- \\P\_{n,b}\\ is the mean output power of the phone in mW, including
  the duty cycle (see
  [`mpc_pwr_native()`](https://wipfir97.github.io/RFDose/reference/mpc_pwr_native.md),
  [`mpc_pwr_data()`](https://wipfir97.github.io/RFDose/reference/mpc_pwr_data.md),
  [`mpc_pwr_wifi()`](https://wipfir97.github.io/RFDose/reference/mpc_pwr_wifi.md))

## See also

[`mpc_pwr_native()`](https://wipfir97.github.io/RFDose/reference/mpc_pwr_native.md),
[`mpc_pwr_data()`](https://wipfir97.github.io/RFDose/reference/mpc_pwr_data.md),
[`mpc_pwr_wifi()`](https://wipfir97.github.io/RFDose/reference/mpc_pwr_wifi.md),
[`mpc_sar_native()`](https://wipfir97.github.io/RFDose/reference/mpc_sar_native.md),
[`mpc_sar_data()`](https://wipfir97.github.io/RFDose/reference/mpc_sar_data.md),
[`mpc_sar_wifi()`](https://wipfir97.github.io/RFDose/reference/mpc_sar_wifi.md)

## Examples

``` r
mpc_msar(
tissue           = "body",
prop_native      = 0.7,
prop_data        = 0.2,
prop_wifi        = 0.1,
headp_prop       = 0.17,
ear_prop         = 0.67,
speaker_prop     = 0.17,
urbanicity       = "suburban",
use_5g           = TRUE,
travel_time      = 1800)
#> [1] 0.08076201
```
