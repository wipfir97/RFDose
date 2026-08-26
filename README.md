# RFDose - Deterministic RF-EMF Dose Calculator

## About

RFDose implements the deterministic RF-EMF dose calculations developed in Jalilian et al. (publication in writing stage). Version 1.0.0 is based on the most up-to-date dose calculations (August 2026).

For detailed information about the package functions, please refer to the [package manual](./doc/RFDose_1.0.0.pdf). We are also preparing a short publication on `RFDose`, which will contain further background information. 

**Information for users of previous test versions (0.2.0, 0.3.0)**

* The definition of the mpc\_headp\_prop input variable changed- please refer to the variable overview below
* `calculate_emf_doses` no longer returns a total dose, only source-specific doses
* `calculate_emf_doses` is now tissue-specific and has the additional required input variable "tissue"

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

Information on how to contribute to `RFDose` will be added here. 

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

An overview of the included variables is shown below.

For the activity variables (mpd, laptop, tablet)

* low output power activities: sending e-mails, browsing intenet, scrolling/chatting on social media
* low-medium output power activities: online gaming, music streaming, voice messaging
* medium-high output power activities: watching or uploading videos on social media, video calls, video streaming
* high output power activities: uploading large files

|Name|Unit|Type|Contraints|Description|Used for source(s)|
|-|-|-|-|-|-|
|use\_5g|-|logical|TRUE or FALSE|Use of 5g (mobile phone only)|mpc, mpd|
|travel\_time|s|numeric|>=0 and <=59350|Time spent commuting (public transport or car) per day|mpc, mpd, far-field, wifi|
|country|-|character|must exactly match one of the listed options|Austria:"AT", Belgium:"BE", France:"FR", Hungary:"HU", Italy:"IT", Netherlands:"NL", Poland:"PL", Spain:"ES", Switzerland:"CH", United Kingdom:"UK", unknown/other: "Other"|farfield|
|urbanicity|-|character|"rural", "suburban" or "urban"|Urbanicity of participant's home ("rural", "suburban", "urban")|mpd, farfield|
|headp\_ear\_num|-|numeric|0, 1 or 2|Number of earphones worn during call|mpc|
|mpc\_duration|s|numeric|>=0 and <= 86400|Daily duration of mobile phone calls (with or without app)|mpc|
|mpc\_ear\_prop|-|numeric|>=0 and <=1|Proportion of time the mobile phone is held against head during mobile calls|mpc|
|mpc\_headp\_prop|-|proportion|>=0 and <=1|Proportion of time headphones are used during mobile phone calls|mpc|
|dect\_duration|s|numeric|>=0 and <= 86400|Daily call duration of DECT/cordless phone calls|dect|
|dect\_ear\_prop|-|numeric|>=0 and <=1|Proportion of time DECT/cordless phone is held against ear during call|dect|
|mpd\_wifi\_prop\_home|-|numeric|>=0 and <=1|Proportion of WiFi vs mobile data (3G, 4G, 5G) while using mobile phone AT HOME|mpc, mpd|
|mpd\_wifi\_prop\_work|-|numeric|>=0 and <=1|Proportion of WiFi vs mobile data (3G, 4G, 5G) while using mobile phone AT WORK/SCHOOL|mpc, mpd|
|mpd\_wifi\_prop\_travel|-|numeric|>=0 and <=1|Proportion of WiFi vs mobile data (3G, 4G, 5G) while using mobile phone WHILE COMMUTING|mpc, mpd, wifi|
|mpd\_dur\_low|s|numeric|>=0 and <= 86400|Daily duration of low output power activities on mobile phone|mpd|
|mpd\_dur\_lowtomed|s|numeric|>=0 and <= 86400|Daily duration of low-medium output power activities on mobile phone|mpd|
|mpd\_dur\_medtohigh|s|numeric|>=0 and <= 86400|Daily duration of medium-high output power activities on mobile phone|mpd|
|mpd\_dur\_high|s|numeric|>=0 and <= 86400|Daily duration of high output power activities on mobile phone|mpd|
|lptp\_dur\_low|s|numeric|>=0 and <= 86400|Daily duration of low output power activities on laptop|lptp|
|lptp\_dur\_lowtomed|s|numeric|>=0 and <= 86400|Daily duration of low-medium output power activities on laptop|lptp|
|lptp\_dur\_medtohigh|s|numeric|>=0 and <= 86400|Daily duration of medium-high output power activities on laptop|lptp|
|lptp\_dur\_high|s|numeric|>=0 and <= 86400|Daily duration of high output power activities on laptop|lptp|
|tblt\_dur\_low|s|numeric|>=0 and <= 86400|Daily duration of low output power activities on tablet|tblt|
|tblt\_dur\_lowtomed|s|numeric|>=0 and <= 86400|Daily duration of low-medium output power activities on tablet|tblt|
|tblt\_dur\_medtohigh|s|numeric|>=0 and <= 86400|Daily duration of medium-high output power activities on tablet|tblt|
|tblt\_dur\_high|s|numeric|>=0 and <= 86400|Daily duration of high output power activities on tablet|tblt|
|hotspot\_duration|s|numeric|>=0 and <= 86400|Daily duration of using mobile phone as hotspot|other|
|smartwatch\_duration|s|numeric|>=0 and <= 86400|Daily duration of wearing smartwatch on wrist|other|
|vr\_duration|s|numeric|>=0 and <= 86400|Daily durarion of virtual reality headset use|other|
|headphone\_duration|s|numeric|>=0 and <= 86400|Daily duration of using bluetooth headphones (all types of usage except for mobile phone call)|other|
|gaming\_duration|s|numeric|>=0 and <= 86400|Daily duration of using portable gaming devices (eg. Nintendo Switch, Steamdeck, etc.)|other|

\---

### Parameters

Parameters are specified in [this YAML file](./inst/extdata/params.yaml). Parameters are obtained from measurements, dosimetric simulations, and literature- more detailed descriptions of each parameter, including units and data sources, will be included in Jalilian et al. (manuscript in preparation).

### Missing data and default values

`RFDose` currently handles missing values by replacing them with default values, which are derived from survey responses of the ongoing [GOLIAT consortium studies](https://projectgoliat.eu/).

Default values are specified in [this YAML file](./inst/extdata/defaultvariables.yaml)

### Output

`calculate_emf_doses` returns a data frame containing the original data columns, as well as an additional column with the dose contribution of each source in mJ/kg/day.

## License and Citation

License: [MIT license](http://opensource.org/licenses/MIT)

The author list is not complete yet. Citation will be added here. 

## Contributors and Acknowledgements

Contributors will be listed here.

\---

## Version History

|Version|Description|
|-|-|
|1.0.0|Updated version based on finalized dose calculations in Jalilian et al. (manuscript in preparation)|
|0.3.0|Updated version with major changes in dose calculations (based on dose calculator 7.6). Based on dose calculator version 7.6|
|0.2.0|Revised draft version with updated calculations, variables, and unit tests. Based on dose calculator version 7.3|
|0.1.0|Initial draft version for internal use|
|0.0.1|Basic test version (not on Github)|

\---

## References and Further Resources

* Will be added here: research paper on `RFDOSE`
* Will be added here: link to Shiny interface of `RFDose`
* Will be added here: link to publication by Jalilian et al.
* [GOLIAT project website](https://projectgoliat.eu/)
* [ETAIN project website](https://www.etainproject.eu/)


\---

