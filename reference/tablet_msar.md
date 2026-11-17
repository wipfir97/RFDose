# Calculate mSAR from Tablet Use

Calculates the tissue-specific momentary SAR (mSAR) from tablet use.

## Usage

``` r
tablet_msar(
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

  Tissue for which to calculate mSAR (default: "brain" or "body")

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

Tissue-specific mSAR from tablet use in mW/kg

## Details

The mSAR is calculated as:

\$\$mSAR\_{tablet} = \sum\_{b} s\_{b} \times nSAR\_{b} \times P\_{b}\$\$

Where:

- \\mSAR\_{tablet}\\ is the mSAR from tablet use in mW/kg

- \\s\_{b}\\ is the share of the WiFi frequency band \\b\\ (2.4 and 5
  GHz)

- \\nSAR\_{b}\\ is the normalised SAR value in W/kg/W (see
  [`tablet_sar()`](https://wipfir97.github.io/RFDose/reference/tablet_sar.md))

- \\P\_{b}\\ is the mean output power of the tablet in mW, including the
  duty cycles of the activities (see
  [`tablet_pwr()`](https://wipfir97.github.io/RFDose/reference/tablet_pwr.md))

We distinguish between 4 types of activities:

1.  Low output power: sending e-mails, browsing the internet, scrolling
    and chatting on social media, sending text messages

2.  Low to medium output power: online gaming, streaming music, sending
    voice messages

3.  Medium to high output power: watching videos, uploading pictures or
    videos, making video calls

4.  High output power: uploading large files

## See also

[`tablet_pwr()`](https://wipfir97.github.io/RFDose/reference/tablet_pwr.md),
[`tablet_sar()`](https://wipfir97.github.io/RFDose/reference/tablet_sar.md)

## Examples

``` r
tablet_msar(
  tissue      = "brain",
  dur_low     = 0,
  dur_lowmed  = 1230,
  dur_medhigh = 0,
  dur_high    = 0)
#> [1] 0.004117202
```
