# Check input duration(s)

Checks supplied input duration or vector of durations; needed to stop
calculation or raise warning in case of irregular input values.

## Usage

``` r
check_duration(duration)
```

## Arguments

- duration:

  single duration (numeric) or vector of durations

## Value

Returns invisible TRUE if all checks pass. Side effects of stopping or
showing warning message if any check fails
