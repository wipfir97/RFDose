# Calculate RF-EMF Dose from Virtual Reality Headset

Calculates the tissue-specific RF-EMF dose from VR headset

## Usage

``` r
vr_dose(tissue, duration_vr, params = load_params())
```

## Arguments

- tissue:

  Tissue for which to calculate dose (default: "brain" or "body")

- duration_vr:

  duration of time VR headset was used in s/day

- params:

  Parameter list (optional). If not specified, calculations use default
  parameters.

## Value

Tissue-specific RF-EMF dose from VR headset use in mJ/kg/day

## Details

The RF-EMF dose from VR headset is calculated as:

\$\$Dose\_{vr} = mSAR\_{vr} \times f\_{online} \times duration\_{vr}\$\$
\$\$mSAR\_{vr} = \sum\_{b} s\_{b} \times nSAR\_{b} \times DC\_{b} \times
P\_{b}\$\$

Where:

- \\mSAR\_{vr}\\ is the mSAR of virtual reality headset use online in
  mW/kg

- \\f\_{online}\\ is the share of the use time online (parameter
  `vr_online_prop`)

- \\s\_{b}\\ is the share of the WiFi frequency band \\b\\ (2.4 and 5
  GHz)

- \\nSAR\_{b}\\ is the normalized SAR in W/kg/W

- \\P\_{b}\\ and \\DC\_{b}\\ are the output power in mW and the duty
  cycle of the headset

- \\duration\_{vr}\\ is the duration of VR headset use in s/day

## Examples

``` r
vr_dose(
  tissue      = "brain",
  duration_vr = 600)
#> [1] 81.8326
```
