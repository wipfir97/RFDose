# RFDose - Deterministic RF-EMF Dose Calculator

## About

RFDose implements the deterministic RF-EMF dose calculations developed in
Jalilian et al. (publication in writing stage).

This package is a work in progress and is continuously updated. We are currently testing the calculations and adding documentation, and there may still be errors and bugs. 

IMPORTANT information for users switching from 0.2.0 to 0.3.0: 

* The definition of the headp\_prop input variable changed from version 0.2.0 to 0.3.0.
* The calculate_emf_doses() function changed: From version 0.3.0, the tissue (default: "brain" or "body") needs to be specified when using the `calculate_emf_doses` function! In addition, the output structure changed and the total_dose output column was removed. Please refer to the function documentation.




\---

## Development Status

### Version overview

|Version|Name|Status|
|-|-|-|
|0.0.1|Basic test version (not on Github)|Completed|
|0.1.0|Initial draft version for internal use|Completed|
|0.2.0|Revised draft version with updated calculations, variables, and unit tests. Based on dose calculator version 7.3|Completed|
|0.3.0|Updated version with major changes in dose calculations (based on dose calculator 7.6). Based on dose calculator version 7.6|Completed|
|0.4.0|Expected to be a smaller update (based on dose calculator version 7.7), with updated parameter values and additional helper functions for overwriting parameters and default values |In development|



## 🛠️ Installation

### Prerequisites

The `remotes` R package should be installed and loaded.

```{r}
library(remotes)
```

### Install RFDose

To install the R package:

```{r}
remotes::install_github("wipfir97/RFDose")
```

To install the current development version:

```{r}
remotes::install_github("wipfir97/RFDose@dev/0.4.0")
```

To install an older version of the package (example v.0.2.0):

```{r}
# Install RFDose using your PAT
remotes::install_github("wipfir97/RFDose@v0.2.0")
```

\---


## Quick Start

For a quick start, you can load the in-build example data set. This contains 3 samples of hypothetical data.

```{r}
# Load package
library(RFDose)
# Load example data
data(example_data)
# View example data
head(example_data)
```

To calculate the RF-EMF doses for each participant, run the following code:

```{r}
# Calculate example doses
calculate_emf_doses(example_data, tissue = "brain") # brain dose
calculate_emf_doses(example_data, tissue = "body")  # body dose
```

\---



## Documentation


### Exposure sources

We consider the following exposure sources in the dose calculations:

|Exposure|Abbreviation|Description|
|-|-|-|
|Mobile calling|mpc|Voice calling using mobile phone, with or without App|
|Mobile data|mpd|WiFi and mobile data use during mobile phone use|
|WiFi|wifi|WiFi router|
|Cordless Phone|dect|Cordless phone use|
|Laptop|lptp|Laptop use|
|Tablet|tblt|Tablet use|
|Far-field|farf|Far-field exposure|
|Other|othe|Other devices: smart watch, tracker, VR headset, hotspot, bluetooth headphones, smart home|

### Calculation

total_dose()
   ├── mobilecall_dose()     
       └── mobilecall_msar()
           ├── mobilecall_nsar()
               ├── ... # sub-functions
           └── mobilecall_pwr()
               ├── ... # sub-functions
   ├── mobiledata_dose()   
       └── ... # same structure as mobilecall_dose()
   ├── cordless_dose() 
       └── ...
   ├── laptop_dose()
       └──...
   ├── tablet_dose()
       └── ...
   ├── other_dose_wrapper()
       └── ... # further devices
   ├── wifi_dose
       └── ...
   └── farfield_dose()
       └── ...

#### Variable overview (version 0.2.0)

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

### Input/user variables

Detailed info to be added here.

### Generated output variables

Detailed info to be added here.

### Parameters

Parameters are specified in [this YAML file](inst/extdata/params.yaml)

More detailed descriptions of each parameter, including units, can be found in the [parameter reference file](doc/params_reference.csv). **Note: this parameter reference file is continuously updated and not yet completed.**


### Missing data and default values

Default values are specified in [this YAML file](inst/extdata/defaultvariables.yaml)

Missing values in the dataset supplied by the user will be replaced with the values in this file.

At the moment, there is no limit to how much missing data is allowed. **However, variables with more than 10% missing data will raise a warning message.**



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

## References and Further Resources

Additional resources and references will be added here.

\---

