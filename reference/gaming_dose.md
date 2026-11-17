# Calculate RF-EMF Dose from online gaming (console)

Calculates the tissue-specific RF-EMF dose from online gaming

## Usage

``` r
gaming_dose(tissue, duration_gaming, params = load_params())
```

## Arguments

- tissue:

  Tissue for which to calculate dose (default: "brain" or "body")

- duration_gaming:

  duration of gaming with portable console in s/day

- params:

  Parameter list (optional). If not specified, calculations use default
  parameters.

## Value

Tissue-specific RF-EMF dose from gaming in mJ/kg/day

## Details

The RF-EMF dose from online gaming is calculated as:

\$\$Dose\_{gaming} = mSAR\_{gaming} \times duration\_{gaming}\$\$
\$\$mSAR\_{gaming} = f\_{online} \times \sum\_{b} s\_{b} \times
nSAR\_{b} \times DC\_{b} \times P\_{b}\$\$

Where:

- \\mSAR\_{gaming}\\ is the mSAR of gaming in mW/kg

- \\f\_{online}\\ is the share of the gaming time online (parameter
  `gaming_online_prop`)

- \\s\_{b}\\ is the share of the WiFi frequency band \\b\\ (2.4 and 5
  GHz)

- \\nSAR\_{b}\\ is the normalized SAR in W/kg/W

- \\P\_{b}\\ and \\DC\_{b}\\ are the output power in mW and the duty
  cycle of the console

- \\duration\_{gaming}\\ is the duration of gaming with portable console
  in s/day

## Examples

``` r
gaming_dose(
  tissue          = "body",
  duration_gaming = 600)
#> [1] 1.865883
```
