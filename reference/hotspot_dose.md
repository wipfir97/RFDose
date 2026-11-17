# Calculate RF-EMF Dose from Mobile Phone Hotspot

Calculates the tissue-specific RF-EMF dose from hotspot

## Usage

``` r
hotspot_dose(tissue, duration_hotspot, params = load_params())
```

## Arguments

- tissue:

  Tissue for which to calculate dose (default: "brain" or "body")

- duration_hotspot:

  duration of time hotspot was active in s/day

- params:

  Parameter list (optional). If not specified, calculations use default
  parameters.

## Value

Tissue-specific RF-EMF dose from hotspot use in mJ/kg/day

## Details

The RF-EMF dose from hotspot use is calculated as:

\$\$Dose\_{hotspot} = mSAR\_{hotspot} \times duration\_{hotspot}\$\$
\$\$mSAR\_{hotspot} = nSAR\_{hotspot} \times P\_{hotspot}\$\$

Where:

- \\mSAR\_{hotspot}\\ is the mSAR of hotspot use in mW/kg

- \\nSAR\_{hotspot}\\ is the normalized SAR of the phone in W/kg/W

- \\P\_{hotspot}\\ is the mean output power of the phone used as hotspot
  in mW

- \\duration\_{hotspot}\\ is the duration of hotspot use in s/day

## Examples

``` r
hotspot_dose(
  tissue           = "body",
  duration_hotspot = 600)
#> [1] 10.41335
```
