# Check if country is valid

Checks if country code matches a country for which measurement data is
available. Use "Other" for any other country.

## Usage

``` r
check_country(country)
```

## Arguments

- country:

  Country to check. Must be one of these: "AT" (Austria), "BE"
  (Belgium), "FR" (France), "HU" (Hungary), "IT" (Italy), "NL"
  (Netherlands), "PL" (Poland), "ES" (Spain), "CH" (Switzerland), "UK"
  (United Kingdom), or "Other" (for any other country; calculations use
  averaged values from countries with available measurements)

## Value

Returns invisible TRUE if all checks pass. Side effect of stopping
calculations if any check fails.
