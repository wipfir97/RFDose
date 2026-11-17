# Calculate RF-EMF Dose from Bluetooth Headphones (phone contribution only)

Calculates the tissue-specific RF-EMF dose from Bluetooth headphone use
(phone contribution only).

## Usage

``` r
headphones_phone_dose(tissue, duration_headphones, params = load_params())
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

Tissue-specific RF-EMF dose from Bluetooth headphone use (phone
contribution only) in mJ/kg/day

## Details

The RF-EMF dose from Bluetooth headphone use (phone contribution) is
calculated as:

\$\$Dose\_{phone} = mSAR\_{phone} \times duration\_{phone}\$\$
\$\$mSAR\_{phone} = nSAR\_{phone} \times P\_{phone}\$\$

Where:

- \\mSAR\_{phone}\\ is the momentary SAR for the headphone connection in
  mW/kg

- \\nSAR\_{phone}\\ is the normalized SAR of the phone in W/kg/W

- \\P\_{phone}\\ is the output power of the phone's connection to the
  headphones in mW

- \\duration\_{phone}\\ is the use duration in s/day

## Examples

``` r
headphones_phone_dose(
  tissue              = "body",
  duration_headphones = 6000)
#> [1] 2.26272
```
