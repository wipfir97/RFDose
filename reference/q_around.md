# Quantiles of a lognormal distribution around a value

Quantiles of a lognormal distribution around a value

## Usage

``` r
q_around(p, value, spec)
```

## Arguments

- p:

  Vector of probabilities

- value:

  Value of the input, the mean of the distribution

- spec:

  Distribution: `sd_rel`, and for a truncated distribution `min` and
  `max`

## Value

Vector of quantiles. All quantiles are equal to `value` if it is 0 or at
(or beyond) a bound.
