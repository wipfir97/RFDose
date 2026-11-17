# Calculate RF-EMF Dose from Tablet Use

Calculates the tissue-specific RF-EMF dose from tablet use.

## Usage

``` r
tablet_dose(
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

  Duration (in seconds per day) of low output power activities on tablet

- dur_lowmed:

  Duration (in seconds per day) of low-medium output power activities on
  tablet

- dur_medhigh:

  Duration (in seconds per day) of medium-high output power activities
  on tablet

- dur_high:

  Duration (in seconds per day) of high output power activities on
  tablet

- params:

  Parameter list (optional). If not specified, calculations use default
  parameters.

## Value

Tissue-specific RF-EMF dose from tablet use in mJ/kg/day

## Details

The tablet RF-EMF dose is calculated as:

\$\$Dose\_{tablet} = mSAR\_{tablet}\*duration\_{tablet}\$\$

Where:

- \\Dose\_{tablet}\\ is the dose from tablet use

- \\mSAR\_{tablet}\\ is the momentary SAR value in mW/kg (see
  [`tablet_msar()`](https://wipfir97.github.io/RFDose/reference/tablet_msar.md))

- \\duration\_{tablet}\\ is the duration of tablet use in s/day (sum of
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

[`tablet_msar()`](https://wipfir97.github.io/RFDose/reference/tablet_msar.md)

## Examples

``` r
tablet_dose(
  tissue      = "brain",
  dur_low     = 0,
  dur_lowmed  = 681,
  dur_medhigh = 0,
  dur_high    = 0)
#> [1] 2.803815
```
