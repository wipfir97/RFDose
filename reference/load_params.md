# Load dose calculation parameters

Loads default parameters or parameters from external source and returns
them as a nested list.

## Usage

``` r
load_params(path = NULL, sar_path = NULL)
```

## Arguments

- path:

  Path of parameter file to load (must be a YAML file). If null, default
  non-SAR parameters are loaded. The file may contain SAR values or not.

- sar_path:

  SAR values (optional): the name of a SAR file included in the package
  (see
  [`available_sar_files()`](https://wipfir97.github.io/RFDose/reference/available_sar_files.md):
  `"goliat_average"`, `"goliat_duke"`, `"goliat_ella"`,
  `"goliat_eartha"`, `"goliat_thelonious"` or `"etain"`), or the path of
  a YAML file with SAR values, with the structure devices \> device \>
  tissue \> SAR values. Its values replace those of the parameters
  loaded from `path`. Besides SAR values, it may set device parameters
  that go with them (e.g. placement proportions such as `legs_prop`).

## Value

List of parameters loaded from yaml input file(s)

## Details

Default parameters are split in two files: non-SAR parameters
(`params.yaml`) and SAR values, which are merged into a single list. The
default SAR values are those of GOLIAT, averaged over four phantoms
(`"goliat_average"`). The ETAIN SAR values are `"etain"`.

SAR values are taken from `sar_path` if given. Otherwise, the SAR values
of the parameter file are used, or the default SAR values if the
parameter file has none. A SAR file may also set device parameters that
go with its SAR values (e.g. placement proportions), which replace those
of the parameter file.

## See also

[`load_tissue_params()`](https://wipfir97.github.io/RFDose/reference/load_tissue_params.md),
[`available_sar_files()`](https://wipfir97.github.io/RFDose/reference/available_sar_files.md)

## Examples

``` r
params <- load_params()
params <- load_params(sar_path = "goliat_average") # the same, with the SAR file named
```
