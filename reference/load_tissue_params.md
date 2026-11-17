# Load tissue-specific parameters

Loads device- and tissue-specific parameters (SAR values) and returns
them as a list.

## Usage

``` r
load_tissue_params(params, device_type, tissue_name)
```

## Arguments

- params:

  List of parameters (default parameter file or custom YAML that matches
  default's structure)

- device_type:

  Name of device (default: )

- tissue_name:

  Name of tissue (default: "brain" or "body")

## Value

List of parameters (SAR values) specific to selected device type and
tissue.

## See also

[`load_params()`](https://wipfir97.github.io/RFDose/reference/load_params.md)
