# Calculate RF-EMF Dose from Smart Watch (watch contribution only)

Calculates the tissue-specific RF-EMF dose from smart-watch use (watch
contribution only).

## Usage

``` r
smartwatch_watch_dose(tissue, duration_smartwatch, params = load_params())
```

## Arguments

- tissue:

  Tissue for which to calculate dose (default: "brain" or "body")

- duration_smartwatch:

  duration of time smart-watch was worn in s/day

- params:

  Parameter list (optional). If not specified, calculations use default
  parameters.

## Value

Tissue-specific RF-EMF dose from smart-watch use (watch contribution
only) in mJ/kg/day

## Details

The RF-EMF dose from smart-watch use (watch contribution) is calculated
as:

\$\$Dose\_{watch} = nSAR\_{watch} \times (P\_{active} \times
t\_{active} + P\_{passive} \times t\_{passive})\$\$

Where:

- \\nSAR\_{watch}\\ is the normalized SAR of the watch in W/kg/W

- \\P\_{active}\\ and \\P\_{passive}\\ are the output powers of the
  watch in mW when transmitting actively and passively

- \\t\_{active}\\ and \\t\_{passive}\\ are the times of active and
  passive transmission in s/day

While worn, the smart-watch transfers data for `watch_transfer_dur`
seconds per day of wearing. During the share
`watch_transfer_active_prop` of this time it transmits actively, the
rest of the time passively (parameters of the device `smartwatch`):

\$\$t\_{active} = duration \times T\_{transfer} / 86400 \times
f\_{active}\$\$ \$\$t\_{passive} = duration - t\_{active}\$\$

with \\duration\\ the time the watch is worn in s/day, \\T\_{transfer}\\
the transfer time (`watch_transfer_dur`) in s per day of wearing and
\\f\_{active}\\ the active share (`watch_transfer_active_prop`).

## Examples

``` r
smartwatch_watch_dose(
  tissue              = "body",
  duration_smartwatch = 6000)
#> [1] 0.171824
```
