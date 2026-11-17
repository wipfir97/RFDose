# Calculate Mobile Phone Output Power during Mobile Data Use

Calculates the mean output power of the mobile phone during mobile data
use.

## Usage

``` r
mpd_pwr_data(
  band,
  duration_low,
  duration_lowmed,
  duration_medhigh,
  duration_high,
  urbanicity,
  travel_time,
  params = load_params()
)
```

## Arguments

- band:

  Technology ("3g", "4g" or "5g")

- duration_low:

  Duration (in seconds per day) of low output power activities

- duration_lowmed:

  Duration (in seconds per day) of low-medium output power activities

- duration_medhigh:

  Duration (in seconds per day) of medium-high output power activities

- duration_high:

  Duration (in seconds per day) of high output power activities

- urbanicity:

  Urbanicity of home / workplace (rural, suburban, or urban)

- travel_time:

  Time spent commuting in seconds per day

- params:

  Parameter list (optional). If not specified, calculations use default
  parameters.

## Value

Output power in mW, including the duty cycles

## Details

The output power depends on the technology, on where the phone is used
(urbanicity; indoors, outdoors or commuting), and on the activities the
phone is used for:

\$\$P = \sum\_{l} \sum\_{k} t\_{l} \times q\_{k} \times DC\_{k} \times
P\_{l}\$\$

where \\l\\ is the place (indoors, i.e. at home or at work; outdoors;
commuting), \\k\\ the activity (low to high output power), \\t\_{l}\\
the share of the day at the place (see
[`location_props()`](https://wipfir97.github.io/RFDose/reference/location_props.md)),
\\q\_{k}\\ the share of the activity in the use time (see
[`act_pwr_props()`](https://wipfir97.github.io/RFDose/reference/act_pwr_props.md)),
\\DC\_{k}\\ the duty cycle of the activity, and \\P\_{l}\\ the output
power at the place in mW (indoors and outdoors: for the urbanicity).

## Examples

``` r
mpd_pwr_data(
band             = "4g",
duration_low     = 4860,
duration_lowmed  = 540,
duration_medhigh = 4860,
duration_high    = 540,
urbanicity       = "rural",
travel_time      = 1800)
#> [1] 11.26402
```
