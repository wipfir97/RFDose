# Calculate Mobile Phone Output Power during WiFi Use

Calculates the mean output power of the mobile phone during WiFi use

## Usage

``` r
mpd_pwr_wifi(
  band,
  duration_low,
  duration_lowmed,
  duration_medhigh,
  duration_high,
  params = load_params()
)
```

## Arguments

- band:

  WiFi frequency band ("2" for 2.4 GHz, "5" for 5.0 GHz)

- duration_low:

  Duration (in seconds per day) of low output power activities

- duration_lowmed:

  Duration (in seconds per day) of low-medium output power activities

- duration_medhigh:

  Duration (in seconds per day) of medium-high output power activities

- duration_high:

  Duration (in seconds per day) of high output power activities

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
mpd_pwr_wifi(
band             = "2",
duration_low     = 4860,
duration_lowmed  = 540,
duration_medhigh = 4860,
duration_high    = 540)
#> [1] 10.0512
```
