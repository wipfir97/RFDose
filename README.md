# RFDose - Deterministic RF-EMF Dose Calculator

## About

RFDose implements the deterministic RF-EMF dose calculations developed in Jalilian et al. (publication in writing stage). Version 1.0.0 is based on the most up-to-date dose calculations (August 2026).

Please also refer to the [package manual](./doc/RFDose_1.0.0.pdf)


* The definition of the headp\_prop input variable changed from version 0.2.0 to 0.3.0.
* The calculate_emf_doses() function changed: From version 0.3.0, the tissue (default: "brain" or "body") needs to be specified when using the `calculate_emf_doses` function! In addition, the output structure changed and the total_dose output column was removed. Please refer to the function documentation.
* Dose functions from different devices/sources can now be used individually.

\---


## Installation and Use Example

### Install RFDose

Install `RFDose` using the `remotes` R package.

```{r}
# Install package
remotes::install_github("wipfir97/RFDose")
# Load package
library(RFDose)
```

### Use Example

Load the example data set, which contains data from 3 hypothetical samples.

For a quick start, you can load the in-build example data set. Each row corresponds to one person, with 3 hypothetical data points. 

```{r}
# Load example data
data(example_data)
# View example data
head(example_data)
```

Calculate RF-EMF doses in mJ/kg/day for each row by using the `calculate_emf_doses()` function and specifying a tissue (currently supported: "brain" and "body"(=overall exposure of the whole body)).

```{r}
# Calculate example doses
calculate_emf_doses(example_data, tissue = "brain") # brain dose
calculate_emf_doses(example_data, tissue = "body")  # body dose
```

Use your own parameters by providing a custom file. This file must be in YAML format and follow the same structure as the [inbuilt parameter file](inst/extdata/params.yaml).

*Note that the R package does not currently check the structure of custom parameter files, so mismatches may result in faulty calculations.*

```{r}
# Calculate example doses with own parameter file
calculate_emf_doses(
  example_data, 
  tissue = "brain", 
  params = "path_to_my_file/my_params.yaml")
```

Behind the scenes, `calculate_emf_doses()` calls various source-specific dose functions, which calculate the individual contributions of different sources (e.g. mobile phone calls). These functions may be used individually. 

\---

## How can I contribute to `RFDose`?

Informations on how to contribute to `RFDose` will be added here. 

## Background

For detailed information and scientific background, please refer to the manuscript by Jalilian et al. (manuscript in preparation, will be linked here once published).

### Exposure sources

We consider the following RF-EMF exposure sources:

|Exposure|Abbreviation|Description|
|-|-|-|
|Mobile calling|mpc|Voice calling using mobile phone, with or without App|
|Mobile data|mpd|WiFi and mobile data use on mobile phone|
|WiFi|wifi|WiFi router|
|Cordless Phone|dect|Cordless phone (=DECT phone) use|
|Laptop|lptp|Laptop use|
|Tablet|tblt|Tablet use|
|Far-field|farf|Far-field exposure from mobile phone base stations and broadcast stations|
|Other|other|Other devices: smartwatch, VR headset, hotspot, bluetooth headphones, and gaming consoles|

### Calculation

```bash
total_dose()
├── mobilecall_dose()     
│    └── mobilecall_dose()
│         ├── mobilecall_nsar()
│         └── mobilecall_pwr()
├── mobiledata_dose()   
├── cordless_dose() 
├── laptop_dose()
├── tablet_dose()
├── other_dose_wrapper()
├── wifi_dose()
└── farfield_dose()
```

### Variables

Input variables are described in ...

|Name|Unit|Type|Description|Notes|
|-|-|-|-|-|
|use\_5g|-|binary|Use of 5G|🆕|
|travel\_time|s|numeric|Time spent commuting (public transport or car) per day|🆕|
|country|-|categorical|Austria:"AT", Belgium:"BE", France:"FR", Hungary:"HU", Italy:"IT", Netherlands:"NL", Poland:"PL", Spain:"ES", Switzerland:"CH", United Kingdom:"UK", unknown/other: "Other"|🆕|
|urbanicity|-|categorical|Urbanicity||
|headp\_ear\_num|-|numeric|Number of earphones worn during call (1 or 2)|🆕|
|mpc\_duration|s|numeric|Duration of daily mobile phone call||
|mpc\_ear\_prop|-|proportion|Proportion of time mobile phone is held against ear during call||
|mpc\_headp\_prop|-|proportion|Proportion of time Bluetooth headphones are used during call||
|dect\_duration|s|numeric|...||
|dect\_ear\_prop|-|proportion|...||
|mpd\_wifi\_prop\_home|---|---|Proportion of WiFi vs mobile data (3G, 4G, 5G) while using mobile phone AT HOME|🆕|
|mpd\_wifi\_prop\_work|---|---|Proportion of WiFi vs mobile data (3G, 4G, 5G) while using mobile phone AT WORK/SCHOOL|🆕|
|mpd\_wifi\_prop\_travel|---|---|Proportion of WiFi vs mobile data (3G, 4G, 5G) while using mobile phone WHILE COMMUTING|🆕|
|mpd\_dur\_low|s|numeric|Daily duration of low output power activities on mobile phone|🆕|
|mpd\_dur\_lowtomed|s|numeric|Daily duration of low-medium output power activities on mobile phone|🆕|
|mpd\_dur\_medtohigh|s|numeric|Daily duration of medium-high output power activities on mobile phone|🆕|
|mpd\_dur\_high|s|numeric|Daily duration of high output power activities on mobile phone|🆕|
|lptp\_dur\_low|s|numeric|Daily duration of low output power activities on laptop|🆕|
|lptp\_dur\_lowtomed|s|numeric|Daily duration of low-medium output power activities on laptop|🆕|
|lptp\_dur\_medtohigh|s|numeric|Daily duration of medium-high output power activities on laptop|🆕|
|lptp\_dur\_high|s|numeric|Daily duration of high output power activities on laptop|🆕|
|tblt\_dur\_low|s|numeric|Daily duration of low output power activities on tablet|🆕|
|tblt\_dur\_lowtomed|s|numeric|Daily duration of low-medium output power activities on tablet|🆕|
|tblt\_dur\_medtohigh|s|numeric|Daily duration of medium-high output power activities on tablet|🆕|
|tblt\_dur\_high|s|numeric|Daily duration of high output power activities on tablet|🆕|
|hotspot\_duration|s||||
|smartwatch\_duration|s||||
|tracker\_duration|s||||
|vr\_duration|s||||
|headphone\_duration|s||||
|gaming\_duration|s||||

\---

### Parameters

Parameters are specified in [this YAML file](./inst/extdata/params.yaml). Parameters are obtained from measurements, dosimetric simulations, and literature- more detailed descriptions of each parameter, including units and data sources, will be included in Jalilian et al. (manuscript in preparation).

### Missing data and default values

`RFDose` currently handles missing values by replacing them with default values, which are derived from survey responses of the ongoing [GOLIAT consortium studies](https://projectgoliat.eu/).

Default values are specified in [this YAML file](./inst/extdata/defaultvariables.yaml)

### Output

Detailed info to be added here.

## License and Citation

License: [MIT license](http://opensource.org/licenses/MIT)

The author list is not complete yet and may be expanded.
If you use this package in academic works, please cite it:

```{r}
citation("RFDose")
```
\---

## Contributors and Acknowledgements

Contributors will be listed here.

\---

## Version History

|Version|Description|
|-|-|-|
|1.0.0|Updated version based on finalized dose calculations in Jalilian et al. (manuscript in preparation)|
|0.3.0|Updated version with major changes in dose calculations (based on dose calculator 7.6). Based on dose calculator version 7.6|
|0.2.0|Revised draft version with updated calculations, variables, and unit tests. Based on dose calculator version 7.3|
|0.1.0|Initial draft version for internal use|
|0.0.1|Basic test version (not on Github)|

\---

## References and Further Resources

* [GOLIAT project website](https://projectgoliat.eu/)
* [ETAIN project website](https://www.etainproject.eu/)
* Will be added here: link to publication by Jalilian et al.
* Will be added here: link to Shiny interface of `RFDose`

\---

