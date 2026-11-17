# Calculate RF-EMF Dose from Smart Watch (phone contribution only)

Calculates the tissue-specific RF-EMF dose from smart-watch use (phone
contribution only).

## Usage

``` r
smartwatch_phone_dose(tissue, duration_smartwatch, params = load_params())
```

## Arguments

- tissue:

  Tissue for which to calculate dose (default: "brain" or "body")

- duration_smartwatch:

  duration of time smart-watch was worn in s/day

- params:

  Parameter list (optional). If not specified, calculations use default
  parameters.

## Value

Tissue-specific RF-EMF dose from smart-watch use (phone contribution
only) in mJ/kg/day

## Details

The RF-EMF dose from smart-watch use (phone contribution) is calculated
as:

\$\$Dose\_{phone} = mSAR\_{phone} \times duration\_{phone}\$\$
\$\$mSAR\_{phone} = nSAR\_{phone} \times P\_{phone}\$\$

Where:

- \\mSAR\_{phone}\\ is the momentary SAR in mW/kg

- \\nSAR\_{phone}\\ is the normalized SAR of the phone in W/kg/W

- \\P\_{phone}\\ is the output power of the phone's connection to the
  watch in mW

- \\duration\_{phone}\\ is the time the watch is worn in s/day

## Examples

``` r
smartwatch_phone_dose(
  tissue              = "body",
  duration_smartwatch = 6000)
#> [1] 0.02827944
```
