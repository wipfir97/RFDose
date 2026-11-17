# Calculate nSAR during WiFi Mobile Phone Calls

Calculates tissue-specific nSAR from mobile phone calls using WiFi
connection.

## Usage

``` r
mpc_sar_wifi(
  tissue,
  band,
  headp_prop,
  ear_prop,
  speaker_prop,
  params = load_params()
)
```

## Arguments

- tissue:

  Tissue for which to calculate nSAR (default: "brain" or "body")

- band:

  Frequency band ("2" for 2.4 GHz, "5" for 5.0 GHz) used for the call

- headp_prop:

  Proportion of call performed with active Bluetooth connection to
  headphones

- ear_prop:

  Proportion of call performed with phone held against ear

- speaker_prop:

  Proportion of call performed in speaker mode

- params:

  Parameter list (optional). If not specified, calculations use default
  parameters.

## Value

nSAR in W/kg/W

## Details

The normalized specific absorption rate (nSAR) depends on the tissue,
the frequency band (2.4 GHz or 5.0 GHz), and the position of the phone
during the call (against the ear, with Bluetooth headphones, in speaker
mode):

\$\$nSAR = p\_{ear} \times nSAR\_{ear} + p\_{headp} \times
nSAR\_{headp} + p\_{speaker} \times nSAR\_{speaker}\$\$
\$\$nSAR\_{headp} = f\_{face} \times nSAR\_{face} + f\_{pock} \times
nSAR\_{pock} + f\_{else} \times nSAR\_{else}\$\$

where \\p\\ are the proportions of the call in each position
(`ear_prop`, `headp_prop`, `speaker_prop`), \\f\\ the proportions of the
places of the phone during calls with headphones (parameters
`headp_face_prop`, `headp_pock_prop`, `headp_else_prop`), and the nSAR
values are in W/kg/W.

## Examples

``` r
mpc_sar_wifi(
tissue       = "brain",
band         = "2",
headp_prop   = 0.17,
ear_prop     = 0.67,
speaker_prop = 0.17)
#> [1] 0.02256026
```
