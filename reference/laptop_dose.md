# Calculate RF-EMF Dose from Laptop Use

Calculates the tissue-specific RF-EMF dose from laptop use.

## Usage

``` r
laptop_dose(
  tissue,
  dur_low,
  dur_lowmed,
  dur_medhigh,
  dur_high,
  params = load_params()
)
```

## Arguments

- tissue:

  Tissue for which to calculate dose (default: "brain" or "body")

- dur_low:

  Duration (in seconds per day) of low output power activities on laptop

- dur_lowmed:

  Duration (in seconds per day) of low-medium output power activities on
  laptop

- dur_medhigh:

  Duration (in seconds per day) of medium-high output power activities
  on laptop

- dur_high:

  Duration (in seconds per day) of high output power activities on
  laptop

- params:

  Parameter list (optional). If not specified, calculations use default
  parameters.

## Value

Tissue-specific RF-EMF dose from laptop use in mJ/kg/day

## Details

The laptop RF-EMF dose is calculated as:

\$\$Dose\_{laptop} = mSAR\_{laptop}\*duration\_{laptop}\$\$

Where:

- \\Dose\_{laptop}\\ is the dose from laptop use

- \\mSAR\_{laptop}\\ is the momentary SAR value in mW/kg (see
  [`laptop_msar()`](https://wipfir97.github.io/RFDose/reference/laptop_msar.md))

- \\duration\_{laptop}\\ is the duration of laptop use in s/day (sum of
  the durations of the four activities)

We distinguish between 4 types of activities:

1.  Low output power: sending e-mails, browsing the internet, scrolling
    and chatting on social media, sending text messages

2.  Low to medium output power: online gaming, streaming music, sending
    voice messages

3.  Medium to high output power: watching videos, uploading pictures or
    videos, making video calls

4.  High output power: uploading large files

## See also

[`laptop_msar()`](https://wipfir97.github.io/RFDose/reference/laptop_msar.md)

## Examples

``` r
laptop_dose(
  tissue      = "brain",
  dur_low     = 0,
  dur_lowmed  = 1230,
  dur_medhigh = 0,
  dur_high    = 0)
#> [1] 0.8454813
```
