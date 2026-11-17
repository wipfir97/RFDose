# Calculate RF-EMF Dose from Bluetooth Headphones (earset contribution only)

Calculates the tissue-specific RF-EMF dose from Bluetooth headphone use
(earset contribution only).

## Usage

``` r
headphones_earset_dose(tissue, duration_headphones, params = load_params())
```

## Arguments

- tissue:

  Tissue for which to calculate dose (default: "brain" or "body")

- duration_headphones:

  duration of time Bluetooth headphones were worn in s/day

- params:

  Parameter list (optional). If not specified, calculations use default
  parameters.

## Value

Tissue-specific RF-EMF dose from Bluetooth headphone use (earset
contribution only) in mJ/kg/day

## Details

The RF-EMF dose from Bluetooth headphone use (earset contribution) is
calculated as:

\$\$Dose\_{earset} = 2 \times mSAR\_{earset} \times
duration\_{earset}\$\$ \$\$mSAR\_{earset} = nSAR\_{earset} \times
P\_{earset}\$\$

Where:

- 2 is the number of earphones (assumption)

- \\mSAR\_{earset}\\ is the momentary SAR of one earphone in mW/kg

- \\nSAR\_{earset}\\ is the normalized SAR of one earphone in W/kg/W

- \\P\_{earset}\\ is the output power of one earphone in mW

- \\duration\_{earset}\\ is the use duration in s/day

## Examples

``` r
headphones_earset_dose(
  tissue              = "body",
  duration_headphones = 6000)
#> [1] 0.337392
```
