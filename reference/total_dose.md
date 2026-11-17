# Calculate Total RF-EMF Dose from All Sources

Calculates the total RF-EMF dose from all available RF-EMF sources for a
specific tissue.

## Usage

``` r
total_dose(sample, tissue, params = load_params())
```

## Arguments

- sample:

  A list with input values for a single observation. List elements must
  match the names and data types of the provided example dataset and
  must not be NA.

- tissue:

  Tissue for which to calculate dose (default: "brain" or "body")

- params:

  Parameter list (optional). If not specified, calculations use default
  parameters.

## Value

Named vector of the RF-EMF doses of the 8 exposure sources (`call_dose`,
`data_dose`, `dect_dose`, `farf_dose`, `wifi_dose`, `lptp_dose`,
`tblt_dose`, `other_dose`) in mJ/kg/day for the specified tissue.

## Details

A detailed description of the dose calculation will follow.
