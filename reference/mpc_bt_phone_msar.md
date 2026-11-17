# Calculate mobile call mSAR for Bluetooth headphones (phone only)

Calculates the mSAR for mobile calling using Bluetooth headphones
(Bluetooth connection of the phone only; the contribution of the
headphones/earset is calculated separately).

## Usage

``` r
mpc_bt_phone_msar(tissue, params = load_params())
```

## Arguments

- tissue:

  Tissue for which to calculate mSAR (default: "brain" or "body")

- params:

  Parameter list (optional). If not specified, calculations use default
  parameters.

## Value

mSAR from Bluetooth calls (phone contribution only) in mW/kg

## Details

The mSAR is calculated as

\$\$mSAR\_{btphone} = P\_{bt} \times (f\_{face} \times nSAR\_{face} +
f\_{pock} \times nSAR\_{pock} + f\_{else} \times nSAR\_{else})\$\$

where \\P\_{bt}\\ is the Bluetooth output power in mW, \\f\\ the
proportions of the places of the phone during calls with headphones
(parameters `headp_face_prop`, `headp_pock_prop`, `headp_else_prop`) and
the nSAR values are in W/kg/W.

## See also

[`mpc_bt_earset_msar()`](https://wipfir97.github.io/RFDose/reference/mpc_bt_earset_msar.md)

## Examples

``` r
mpc_bt_phone_msar(
tissue = "brain"
)
#> [1] 6.381316e-05
```
