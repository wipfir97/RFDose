# Calculation of RF-EMF Dose from Mobile Phone Calls

Includes RF-EMF exposure from phone itself, for Bluetooth connection to
headphones, and from headphones themselves

## Usage

``` r
mobilecall_dose(
  tissue,
  duration,
  ear_prop,
  headp_prop,
  urbanicity,
  use_5g,
  travel_time,
  headp_ear_num,
  wifi_prop_home,
  wifi_prop_work,
  wifi_prop_travel,
  params = load_params()
)
```

## Arguments

- tissue:

  Tissue for which to calculate dose (default: "brain" or "body")

- duration:

  Duration of mobile phone call in seconds per day

- ear_prop:

  Proportion of call performed with phone held against ear

- headp_prop:

  Proportion of call performed with active Bluetooth connection to
  headphones

- urbanicity:

  Urbanicity of home / workplace (rural, suburban, or urban)

- use_5g:

  TRUE if 5g services are used for calls, FALSE if not

- travel_time:

  Time spent commuting in seconds per day

- headp_ear_num:

  Number of Bluetooth earphones worn during the call (0, 1 or 2)

- wifi_prop_home:

  Proportion of time connected to WiFi (vs mobile data) at home

- wifi_prop_work:

  Proportion of time connected to WiFi (vs mobile data) at school / work

- wifi_prop_travel:

  Proportion of time connected to WiFi (vs mobile data) while commuting

- params:

  Parameter list (optional). If not specified, calculations use default
  parameters.

## Value

Tissue-specific RF-EMF dose in mJ/kg/day

## Details

The mobile call RF-EMF dose is calculated as:

\$\$Dose\_{mobilecall} = Dose\_{phone} + Dose\_{earset} +
Dose\_{btphone}\$\$

with

\$\$Dose\_{phone} = mSAR\_{phone} \times duration\$\$ \$\$Dose\_{earset}
= mSAR\_{earset} \times p\_{headp} \times n\_{ear} \times duration\$\$
\$\$Dose\_{btphone} = mSAR\_{btphone} \times p\_{headp} \times
duration\$\$

Where:

- \\Dose\_{phone}\\ is the dose from the mobile phone (no Bluetooth)

- \\Dose\_{earset}\\ and \\Dose\_{btphone}\\ are the doses from the
  Bluetooth earphones and from the Bluetooth connection of the phone

- \\mSAR\_{phone}\\, \\mSAR\_{earset}\\ and \\mSAR\_{btphone}\\ are the
  momentary SAR values in mW/kg (see
  [`mpc_msar()`](https://wipfir97.github.io/RFDose/reference/mpc_msar.md),
  [`mpc_bt_earset_msar()`](https://wipfir97.github.io/RFDose/reference/mpc_bt_earset_msar.md)
  and
  [`mpc_bt_phone_msar()`](https://wipfir97.github.io/RFDose/reference/mpc_bt_phone_msar.md))

- \\p\_{headp}\\ is the proportion of the call with Bluetooth headphones
  (`headp_prop`) and \\n\_{ear}\\ the number of earphones
  (`headp_ear_num`)

- \\duration\\ is the call duration in s/day

The phone is in speaker mode for the rest of the call, \\1 - p\_{ear} -
p\_{headp}\\. The call goes over the native network for the proportion
\\p\_{native}\\ (parameter `native_prop`), over WiFi for \\p\_{wifi} =
(1 - p\_{native}) \times (t\_{home} w\_{home} + t\_{work} w\_{work} +
t\_{travel} w\_{travel})\\ and over mobile data for the rest, where
\\t\\ are the shares of the day at home, at work and commuting (see
[`location_props()`](https://wipfir97.github.io/RFDose/reference/location_props.md))
and \\w\\ the WiFi proportions (`wifi_prop_home`, `wifi_prop_work`,
`wifi_prop_travel`).

## See also

[`mpc_msar()`](https://wipfir97.github.io/RFDose/reference/mpc_msar.md)

## Examples

``` r
mobilecall_dose(
tissue           = "brain",
duration         = 400,
ear_prop         = 0.67,
headp_prop       = 0.17,
urbanicity       = "suburban",
use_5g           = TRUE,
travel_time      = 1800,
headp_ear_num    = 2,
wifi_prop_home   = 1,
wifi_prop_work   = 0.8,
wifi_prop_travel = 0)
#> [1] 68.32633
```
