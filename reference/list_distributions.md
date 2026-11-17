# List parameter distributions

Turns the nested list of distributions into a flat list, with one
element per drawn parameter.

## Usage

``` r
list_distributions(distributions)
```

## Arguments

- distributions:

  Nested list of distributions, as returned by
  [`load_distributions()`](https://wipfir97.github.io/RFDose/reference/load_distributions.md)

## Value

List named by the path of each parameter in the parameter list (sections
separated by "."). Each element is the distribution of the parameter,
with its path as character vector (`key`).
