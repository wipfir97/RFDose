# Calculate Laptop Output Power

Calculates the mean laptop output power during use

## Usage

``` r
laptop_pwr(
  band,
  dur_low,
  dur_lowmed,
  dur_medhigh,
  dur_high,
  params = load_params()
)
```

## Arguments

- band:

  WiFi frequency band ("2" for 2.4 GHz, "5" for 5.0 GHz)

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

Output power in mW, including the duty cycles

## Details

The output power depends on the frequency band (2.4 GHz or 5.0 GHz) and
the type of activity:

\$\$P = P\_{wifi} \times \sum\_{k} q\_{k} \times DC\_{k}\$\$

where \\P\_{wifi}\\ is the output power of the band in mW, \\q\_{k}\\
the share of the activity \\k\\ in the use time (see
[`act_pwr_props()`](https://wipfir97.github.io/RFDose/reference/act_pwr_props.md))
and \\DC\_{k}\\ its duty cycle.

## Examples

``` r
laptop_pwr(
  band        = "2",
  dur_low     = 0,
  dur_lowmed  = 1230,
  dur_medhigh = 0,
  dur_high    = 0)
#> [1] 2.2
```
