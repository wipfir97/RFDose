# Calculate mobile call mSAR for Bluetooth headphones (headphones only)

Calculates the mSAR for mobile calling using Bluetooth headphones
(headphone/earset only; the contribution of the mobile phone is
calculated separately).

## Usage

``` r
mpc_bt_earset_msar(tissue, params = load_params())
```

## Arguments

- tissue:

  Tissue for which to calculate mSAR (default: "brain" or "body")

- params:

  Parameter list (optional). If not specified, calculations use default
  parameters.

## Value

mSAR from Bluetooth calls (one earphone only) in mW/kg

## Details

The mSAR of one earphone is calculated as

\$\$mSAR\_{earset} = nSAR\_{earset} \times P\_{bt}\$\$

where \\nSAR\_{earset}\\ is the normalized SAR of the earphone in W/kg/W
and \\P\_{bt}\\ the Bluetooth output power in mW.
[`mobilecall_dose()`](https://wipfir97.github.io/RFDose/reference/mobilecall_dose.md)
multiplies it by the number of earphones.

## See also

[`mpc_bt_phone_msar()`](https://wipfir97.github.io/RFDose/reference/mpc_bt_phone_msar.md)

## Examples

``` r
mpc_bt_earset_msar(
  tissue = "brain"
)
#> [1] 0.002718427
```
