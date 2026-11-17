# Calculate mSAR from Laptop Use

Calculates the tissue-specific momentary SAR (mSAR) from laptop use.

## Usage

``` r
laptop_msar(
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

Tissue-specific mSAR from laptop use in mW/kg

## Details

The mSAR is calculated as:

\$\$mSAR\_{laptop} = \sum\_{b} s\_{b} \times nSAR\_{b} \times P\_{b}\$\$

Where:

- \\mSAR\_{laptop}\\ is the mSAR from laptop use in mW/kg

- \\s\_{b}\\ is the share of the WiFi frequency band \\b\\ (2.4 and 5
  GHz)

- \\nSAR\_{b}\\ is the normalised SAR value in W/kg/W, weighted over the
  placements of the laptop (see
  [`laptop_sar()`](https://wipfir97.github.io/RFDose/reference/laptop_sar.md))

- \\P\_{b}\\ is the mean output power of the laptop in mW, including the
  duty cycles of the activities (see
  [`laptop_pwr()`](https://wipfir97.github.io/RFDose/reference/laptop_pwr.md))

We distinguish between 4 types of activities:

1.  Low output power: sending e-mails, browsing the internet, scrolling
    and chatting on social media, sending text messages

2.  Low to medium output power: online gaming, streaming music, sending
    voice messages

3.  Medium to high output power: watching videos, uploading pictures or
    videos, making video calls

4.  High output power: uploading large files

## See also

[`laptop_pwr()`](https://wipfir97.github.io/RFDose/reference/laptop_pwr.md),
[`laptop_sar()`](https://wipfir97.github.io/RFDose/reference/laptop_sar.md)

## Examples

``` r
laptop_msar(
  tissue      = "brain",
  dur_low     = 0,
  dur_lowmed  = 1230,
  dur_medhigh = 0,
  dur_high    = 0)
#> [1] 0.0006873832
```
