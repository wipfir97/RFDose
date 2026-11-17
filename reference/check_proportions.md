# Check input proportion(s)

Checks supplied input proportion or vector of proportions; needed to
stop calculation or raise warning in case of irregular input values.

## Usage

``` r
check_proportions(proportions)
```

## Arguments

- proportions:

  Single proportion value (between 0 and 1 ) or vector with multiple
  proportions to check

## Value

Returns invisible TRUE if all checks pass. Side effects of stopping or
showing warning message if any check fails.
