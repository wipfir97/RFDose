# Calculate Output Power of DECT/Cordless Phone

Calculates the mean output power of DECT/cordless phone during a call.

## Usage

``` r
dect_pwr(params = load_params())
```

## Arguments

- params:

  Parameter list (optional). If not specified, calculations use default
  parameters.

## Value

DECT/cordless phone output power in mW, including the duty cycle

## Details

\$\$P\_{DECT} = DC \times P\$\$

where \\P\\ is the output power of the phone in mW and \\DC\\ its duty
cycle.
